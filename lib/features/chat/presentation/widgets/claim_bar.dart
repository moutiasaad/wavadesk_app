import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/chat_controller.dart';
import '../../application/claim_controller.dart';
import '../../domain/conversation_detail.dart';
import 'claim_confirm_sheet.dart';
import 'claim_viewing_row.dart';

/// "Claim on reply" variant (Claim spec §7.5), off by default.
/// Enable with `--dart-define=feature.claimOnReply=true`.
const kClaimOnReply = bool.fromEnvironment('feature.claimOnReply');

/// Claim bar (Claim v2 §4.3): white panel over the messages with the
/// presence row (viewers + wait chip), teal "استلم المحادثة" 52 and outline
/// "إسناد لزميل" 46; leads/admins also get "إضافة ملاحظة داخلية". No text
/// field, so the keyboard never opens here.
///
/// Variants: the AI is still replying (§4.5) → "استلم من الذكاء الاصطناعي",
/// which also pauses the AI; the agent may not claim (team restriction,
/// §4.3.2) → outline button only + "هذه المحادثة لفريق {team}".
class ClaimBar extends ConsumerStatefulWidget {
  const ClaimBar({
    super.key,
    required this.detail,
    required this.onResult,
    required this.onAssign,
    this.onNote,
    this.canClaim = true,
    this.pulse = false,
    this.autoClaim = false,
    this.source = 'chat',
  });

  final ConversationDetail detail;

  /// Called with every finished claim attempt (success, conflict, …).
  final ValueChanged<ClaimState> onResult;
  final VoidCallback onAssign;

  /// "إضافة ملاحظة داخلية" (leads / admins, §4.3.4).
  final VoidCallback? onNote;

  /// False: team restriction — no primary button.
  final bool canClaim;

  /// One-time pulse on the primary button (opened from a push).
  final bool pulse;

  /// `?claim=1`: claim automatically after 400ms if still unassigned.
  final bool autoClaim;

  /// chat | push | auto (analytics).
  final String source;

  @override
  ConsumerState<ClaimBar> createState() => _ClaimBarState();
}

class _ClaimBarState extends ConsumerState<ClaimBar> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: AppMotion.normal);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  int _pulseCycles = 0;

  String get _id => widget.detail.id;

  /// §4.5: auto mode, nobody assigned, the AI still replying.
  bool get _aiVariant => widget.detail.assignee == null && widget.detail.handledByAi && widget.detail.aiAutoMode;

  @override
  void initState() {
    super.initState();
    _pulse.addStatusListener((s) {
      if (s == AnimationStatus.completed && ++_pulseCycles < 2) _pulse.forward(from: 0);
    });
    if (widget.autoClaim && widget.canClaim) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted && widget.detail.assignee == null) _claim(source: 'auto', skipConfirm: true);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _enter.value = 1;
    } else if (_enter.status == AnimationStatus.dismissed) {
      _enter.forward();
    }
    if (widget.pulse && !reduced && _pulseCycles == 0 && !_pulse.isAnimating) _pulse.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _claim({String? source, bool skipConfirm = false}) async {
    if (ref.read(claimControllerProvider(_id)).claiming) return;
    HapticFeedback.lightImpact();
    final fromAi = _aiVariant;
    var setAvailable = false;
    if (!skipConfirm) {
      final presence = ref.read(settingsProvider).presence;
      final limits = ref.read(claimLimitsProvider(_id));
      if (presence == Presence.away) {
        if (!await showClaimConfirmSheet(context, kind: ClaimConfirmKind.away)) return;
        setAvailable = true;
      } else if (limits.atCapacity) {
        if (!mounted) return;
        if (!await showClaimConfirmSheet(context, kind: ClaimConfirmKind.capacity, open: limits.open)) return;
      }
    }
    final result = await ref
        .read(claimControllerProvider(_id).notifier)
        .claim(source: source ?? widget.source, setAvailable: setAvailable);
    if (result.phase == ClaimPhase.success) {
      HapticFeedback.mediumImpact();
      // Taking over from the AI stops it on this conversation (§4.5).
      if (fromAi) ref.read(chatActionsProvider(_id)).setAiPaused(true);
    }
    widget.onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final d = widget.detail;
    final claiming = ref.watch(claimControllerProvider(_id).select((s) => s.claiming));
    final offline = ref.watch(inboxProvider.select((s) => s.network != NetworkState.online));
    final lead = ref.watch(currentAgentProvider).canManage || d.permissions.isAdmin;
    final limits = ref.watch(claimLimitsProvider(_id));
    final atCapacity = limits.atCapacity;
    final hardBlocked = limits.hardBlocked;
    final dark = c.isDark;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    final primary = _PulseRing(
      animation: _pulse,
      child: _BarButton(
        primary: true,
        height: 52,
        icon: AppIcons.check,
        iconSize: 20,
        label: hardBlocked ? l.claim_capacity_reached : (_aiVariant ? l.claim_btn_ai : l.claim_button),
        hint: l.claim_button_hint,
        loading: claiming,
        onPressed: offline || hardBlocked ? null : _claim,
      ),
    );

    final secondary = d.permissions.canAssign
        ? _BarButton(
            primary: false,
            height: 46,
            icon: AppIcons.team,
            iconSize: 16,
            label: l.claim_assign_colleague,
            onPressed: claiming
                ? null
                : () {
                    Analytics.log('claim_assign_open');
                    widget.onAssign();
                  },
          )
        : null;

    final caption = t.caption.copyWith(fontSize: 12, color: dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309));

    final Widget content = kClaimOnReply && widget.canClaim
        ? _ClaimOnReplyRow(claiming: claiming, offline: offline, onClaim: _claim)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaimViewingRow(
                conversationId: _id,
                waitingSince: d.waitingSince,
                slaSeconds: limits.slaSeconds,
                aiReplying: _aiVariant,
              ),
              if (atCapacity && !hardBlocked && widget.canClaim) ...[
                const SizedBox(height: 10),
                Text(l.claim_capacity_hint(limits.open, limits.max!), style: caption, textAlign: TextAlign.center),
              ],
              if (widget.canClaim) ...[const SizedBox(height: 10), primary],
              if (secondary != null) ...[const SizedBox(height: 10), secondary],
              if (!widget.canClaim) ...[
                const SizedBox(height: 8),
                Text(
                  l.claim_team_only(d.permissions.claimTeamName ?? ''),
                  style: t.caption.copyWith(fontSize: 12, color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              if (offline && widget.canClaim) ...[
                const SizedBox(height: 8),
                Text(l.claim_offline_hint, style: caption, textAlign: TextAlign.center),
              ],
              if (lead && widget.onNote != null) ...[
                const SizedBox(height: 2),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      textStyle: t.buttonSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                      minimumSize: const Size(48, 36),
                    ),
                    onPressed: claiming ? null : widget.onNote,
                    child: Text(l.readonly_add_note),
                  ),
                ),
              ],
            ],
          );

    final curve = CurvedAnimation(parent: _enter, curve: AppMotion.standard);
    return Semantics(
      container: true,
      label: l.claim_region,
      child: FadeTransition(
        opacity: curve,
        child: AnimatedBuilder(
          animation: curve,
          builder: (context, child) => Transform.translate(offset: Offset(0, 16 * (1 - curve.value)), child: child),
          child: ClaimPanel(
            bottomInset: bottom,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The white panel shared by the Claim and Taken bars (§4.3, §4.6): top
/// hairline, soft upward lift (off in dark mode), padding 14/16/(safe+10).
class ClaimPanel extends StatelessWidget {
  const ClaimPanel({super.key, required this.child, required this.bottomInset});

  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = c.isDark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF151E22) : Colors.white,
        border: Border(top: BorderSide(color: dark ? const Color(0xFF243036) : const Color(0xFFE9EEF2))),
        boxShadow: dark
            ? null
            : const [BoxShadow(offset: Offset(0, -8), blurRadius: 24, spreadRadius: -16, color: Color(0x2E0F172A))],
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 10 + math.max(bottomInset, 0.0)),
      child: child,
    );
  }
}

/// Full-width claim-bar button: teal filled (52) or white outlined (46),
/// radius 14, Cairo 15.5/700, icon + label centred; pressed = darker teal +
/// scale 0.98; loading = 20 white spinner.
class ClaimBarButton extends StatefulWidget {
  const ClaimBarButton({
    super.key,
    required this.primary,
    required this.height,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.onPressed,
    this.hint,
    this.loading = false,
  });

  final bool primary;
  final double height;
  final IconData icon;
  final double iconSize;
  final String label;
  final String? hint;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  State<ClaimBarButton> createState() => _ClaimBarButtonState();
}

typedef _BarButton = ClaimBarButton;

class _ClaimBarButtonState extends State<ClaimBarButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = c.isDark;
    final enabled = widget.onPressed != null && !widget.loading;
    final reduced = AppMotion.reduced(context);
    final Color bg;
    final Color fg;
    final BorderSide side;
    if (widget.primary) {
      bg = _down ? const Color(0xFF0A5E5B) : const Color(0xFF0F7E7A);
      fg = Colors.white;
      side = BorderSide.none;
    } else {
      bg = _down ? c.surfaceVariant : (dark ? const Color(0xFF151E22) : Colors.white);
      fg = dark ? const Color(0xFFE6ECEF) : const Color(0xFF0F172A);
      side = BorderSide(color: dark ? const Color(0xFF243036) : const Color(0xFFE9EEF2));
    }
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: side);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      hint: widget.hint,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _down && !reduced ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: widget.onPressed == null && !widget.loading ? 0.45 : 1,
          child: Material(
            color: bg,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _down = v && enabled),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.height),
                child: Center(
                  child: widget.loading
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(widget.icon, dp: widget.iconSize, color: fg),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.label,
                                  textAlign: TextAlign.center,
                                  style: context.text.buttonMedium.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, color: fg),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time ring pulse around the primary button (opened from a push).
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value;
        if (v == 0 || v == 1) return child!;
        final scale = 1 + 0.03 * math.sin(v * math.pi);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.scale(
                  scaleX: 1 + 16 * v / 360,
                  scaleY: 1 + 16 * v / 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.primaryContainer.withValues(alpha: 1 - v), width: 2),
                    ),
                  ),
                ),
              ),
            ),
            Transform.scale(scale: scale, child: child),
          ],
        );
      },
    );
  }
}

/// §7.5: a disabled-looking composer ("اكتب للاستلام والرد…") + "استلم"
/// chip. Focusing the field claims silently; on success the chat swaps to
/// the real composer.
class _ClaimOnReplyRow extends StatelessWidget {
  const _ClaimOnReplyRow({required this.claiming, required this.offline, required this.onClaim});

  final bool claiming;
  final bool offline;
  final Future<void> Function({String? source, bool skipConfirm}) onClaim;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: offline ? null : () => onClaim(source: 'chat'),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: AlignmentDirectional.centerStart,
              decoration: BoxDecoration(
                color: c.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                l.claim_reply_placeholder,
                style: context.text.bodyLarge.copyWith(fontSize: 14, color: c.textTertiary),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: l.claim_short,
          size: AppButtonSize.small,
          loading: claiming,
          onPressed: offline ? null : () => onClaim(source: 'chat'),
        ),
      ],
    );
  }
}
