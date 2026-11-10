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
import '../../../../core/api/wd_api.dart' show WdApi;
import '../../application/claim_controller.dart';
import '../../data/chat_api.dart';
import '../../domain/conversation_detail.dart';
import 'claim_confirm_sheet.dart';
import 'claim_viewing_row.dart';

/// "Claim on reply" variant (Claim spec §7.5), off by default.
/// Enable with `--dart-define=feature.claimOnReply=true`.
const kClaimOnReply = bool.fromEnvironment('feature.claimOnReply');

/// Unassigned state of the chat (Claim spec §4): viewing row + waiting tag,
/// "استلم المحادثة", "إسناد لزميل", admin "تولَّ الذكاء الاصطناعي الرد".
class ClaimBar extends ConsumerStatefulWidget {
  const ClaimBar({
    super.key,
    required this.detail,
    required this.onResult,
    required this.onAssign,
    this.pulse = false,
    this.autoClaim = false,
    this.source = 'chat',
  });

  final ConversationDetail detail;

  /// Called with every finished claim attempt (success, conflict, …).
  final ValueChanged<ClaimState> onResult;
  final VoidCallback onAssign;

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
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  int _pulseCycles = 0;

  String get _id => widget.detail.id;

  @override
  void initState() {
    super.initState();
    _pulse.addStatusListener((s) {
      if (s == AnimationStatus.completed && ++_pulseCycles < 2) _pulse.forward(from: 0);
    });
    if (widget.autoClaim) {
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
    HapticFeedback.mediumImpact();
    var setAvailable = false;
    if (!skipConfirm) {
      final presence = ref.read(settingsProvider).presence;
      final limits = ref.read(claimLimitsProvider(_id));
      final open = limits.open;
      if (presence == Presence.away) {
        if (!await showClaimConfirmSheet(context, kind: ClaimConfirmKind.away)) return;
        setAvailable = true;
      } else if (limits.atCapacity) {
        if (!mounted) return;
        if (!await showClaimConfirmSheet(context, kind: ClaimConfirmKind.capacity, open: open)) return;
      }
    }
    final result = await ref
        .read(claimControllerProvider(_id).notifier)
        .claim(source: source ?? widget.source, setAvailable: setAvailable);
    if (result.phase == ClaimPhase.success) HapticFeedback.heavyImpact();
    widget.onResult(result);
  }

  /// §4.5 (admins): hand the conversation to the AI agent.
  /// Real API: `POST conversations/{id}/assign {assignee: {type: ai}}`.
  Future<void> _assignToAi() async {
    final l = context.l10n;
    final api = ref.read(chatApiProvider);
    try {
      final r = await api.action(_id, 'assign', {
        'assignee': {'type': 'ai'},
      }, WdApi.newIdempotencyKey());
      ref.read(inboxProvider.notifier).upsertFromApi(r.conversation);
      ref.read(remoteChatPermissionsProvider.notifier).put(r);
    } on ChatApiException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, message: e.message ?? l.chatscreen_action_failed, kind: SnackKind.error);
      return;
    }
    if (!mounted) return;
    Analytics.log('claim_assign_done', {'target_type': 'ai', 'undo': false});
    AppSnackbar.show(context, message: l.claim_ai_takeover_done, kind: SnackKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final d = widget.detail;
    final claiming = ref.watch(claimControllerProvider(_id).select((s) => s.claiming));
    final offline = ref.watch(inboxProvider.select((s) => s.network != NetworkState.online));
    final ai = ref.watch(aiSettingsProvider);
    final limits = ref.watch(claimLimitsProvider(_id));
    final open = limits.open;
    final atCapacity = limits.atCapacity;
    final hardBlocked = limits.hardBlocked;
    final canAssign = d.permissions.canAssign;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    final primary = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        if (!_pulse.isAnimating) return child!;
        final v = _pulse.value;
        final scale = 1 + 0.03 * math.sin(v * math.pi);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Expanding primaryContainer ring, fading out.
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.scale(
                  scaleX: 1 + 16 * v / 360,
                  scaleY: 1 + 16 * v / 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
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
      child: Semantics(
        hint: l.claim_button_hint,
        child: AppButton(
          label: hardBlocked ? l.claim_capacity_reached : l.claim_button,
          icon: AppIcons.claim,
          size: AppButtonSize.large,
          expand: true,
          loading: claiming,
          onPressed: offline || hardBlocked ? null : _claim,
        ),
      ),
    );

    Widget content;
    if (kClaimOnReply) {
      content = _ClaimOnReplyRow(claiming: claiming, offline: offline, onClaim: _claim);
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClaimViewingRow(conversationId: _id, waitingSince: d.waitingSince, slaSeconds: limits.slaSeconds),
          const SizedBox(height: 10),
          if (atCapacity && !hardBlocked) ...[
            Text(
              l.claim_capacity_hint(open, limits.max!),
              style: t.caption.copyWith(color: c.textWarning),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          primary,
          if (offline) ...[
            const SizedBox(height: 6),
            Text(
              l.claim_offline_hint,
              style: t.caption.copyWith(color: c.textError),
              textAlign: TextAlign.center,
            ),
          ],
          if (canAssign) ...[
            const SizedBox(height: 10),
            Opacity(
              opacity: claiming ? 0.4 : 1,
              child: AppButton(
                label: l.claim_assign_colleague,
                icon: AppIcons.team,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                height: 46,
                expand: true,
                onPressed: claiming
                    ? null
                    : () {
                        Analytics.log('claim_assign_open');
                        widget.onAssign();
                      },
              ),
            ),
          ],
          // Admins only: hand back to the AI agent (§4.5).
          if (d.permissions.isAdmin && (d.permissions.canHandToAi ?? ai.enabled)) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: c.textSecondary,
                  textStyle: t.buttonSmall,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: claiming
                    ? null
                    : _assignToAi,
                child: Text(l.claim_ai_takeover),
              ),
            ),
          ],
        ],
      );
    }

    final curve = CurvedAnimation(parent: _enter, curve: AppMotion.standard);
    return Semantics(
      container: true,
      label: l.claim_region,
      child: FadeTransition(
        opacity: curve,
        child: AnimatedBuilder(
          animation: curve,
          builder: (context, child) => Transform.translate(offset: Offset(0, 16 * (1 - curve.value)), child: child),
          child: Container(
            decoration: BoxDecoration(
              color: c.background,
              border: Border(top: BorderSide(color: c.divider)),
            ),
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 14 + math.max(bottom, 6.0)),
            child: content,
          ),
        ),
      ),
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
                style: context.text.bodyLarge.copyWith(fontSize: 15, color: c.textTertiary),
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
