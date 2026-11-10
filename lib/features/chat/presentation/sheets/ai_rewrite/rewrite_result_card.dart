import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/rewrite_session.dart';
import 'rewrite_result_indicators.dart';
import 'rewrite_version_pager.dart';

/// "✦ الصياغة المقترحة" card (Rewrite spec §5.5) with every §6 state.
class RewriteResultCard extends StatefulWidget {
  const RewriteResultCard({
    super.key,
    required this.session,
    required this.labelFocusNode,
    required this.onRetry,
    required this.onEdit,
    required this.onPrevious,
    required this.onNext,
    this.onViewPlans,
  });

  final RewriteSession session;

  /// Initial focus lands on the label so screen readers hear the result (§10).
  final FocusNode labelFocusNode;
  final VoidCallback onRetry;
  final ValueChanged<String> onEdit;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onViewPlans;

  @override
  State<RewriteResultCard> createState() => _RewriteResultCardState();
}

enum _Transition { appear, versionForward, versionBack }

class _RewriteResultCardState extends State<RewriteResultCard> {
  bool _editing = false;
  bool _showDiff = false;
  final _editController = TextEditingController();
  final _editFocus = FocusNode();
  _Transition _transition = _Transition.appear;

  RewriteSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    _editFocus.addListener(() {
      if (!_editFocus.hasFocus && _editing) setState(() => _editing = false);
    });
  }

  @override
  void didUpdateWidget(RewriteResultCard old) {
    super.didUpdateWidget(old);
    final o = old.session;
    final sameStyle = o.style == s.style;
    final versionChanged = o.current?.id != s.current?.id;
    if (sameStyle && o.status == RewriteStatus.success && s.status == RewriteStatus.success && versionChanged) {
      _transition = s.currentIndex > o.currentIndex ? _Transition.versionForward : _Transition.versionBack;
    } else if (versionChanged || o.status != s.status || !sameStyle) {
      _transition = _Transition.appear;
    }
    if (versionChanged || !sameStyle || s.status != RewriteStatus.success) {
      _editing = false;
      _showDiff = false;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _startEdit() {
    final v = s.current;
    if (v == null || s.status != RewriteStatus.success) return;
    _editController.value = TextEditingValue(
      text: v.effectiveText,
      selection: TextSelection.collapsed(offset: v.effectiveText.length),
    );
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _editFocus.requestFocus());
  }

  Future<void> _copyMenu(Offset position) async {
    final v = s.current;
    if (v == null) return;
    final l = context.l10n;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
      items: [PopupMenuItem(value: 'copy', child: Text(l.rw_copy))],
    );
    if (picked != 'copy' || !mounted) return;
    await Clipboard.setData(ClipboardData(text: v.effectiveText));
    HapticFeedback.lightImpact();
    if (mounted) {
      SemanticsService.announce(l.rw_copied, Directionality.of(context));
    }
  }

  // ---- Decoration per state ------------------------------------------------------------

  ({Color bg, Color border, double width}) _frame(AppColors c) => switch (s.status) {
    RewriteStatus.loading ||
    RewriteStatus.streaming ||
    RewriteStatus.success => (bg: c.primaryContainer, border: c.primary, width: 1.5),
    RewriteStatus.error ||
    RewriteStatus.rateLimited => (bg: c.errorContainer, border: c.error.withValues(alpha: 0.25), width: 1),
    RewriteStatus.blocked ||
    RewriteStatus.tooLong => (bg: c.warningContainer, border: c.warning.withValues(alpha: 0.3), width: 1),
    RewriteStatus.planLimit || RewriteStatus.offline => (bg: c.surfaceVariant, border: c.border, width: 1),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _frame(c);
    final reduced = AppMotion.reduced(context);

    // One focus target outside the switcher (two attached nodes would clash
    // while versions cross-fade).
    return Focus(
      focusNode: widget.labelFocusNode,
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : AppMotion.fast,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: f.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.border, width: f.width),
        ),
        child: AnimatedSwitcher(
          duration: reduced ? Duration.zero : (_transition == _Transition.appear ? AppMotion.normal : AppMotion.fast),
          switchInCurve: AppMotion.standard,
          layoutBuilder: (current, previous) =>
              Stack(alignment: AlignmentDirectional.topStart, children: [...previous, ?current]),
          transitionBuilder: (child, anim) {
            final rtl = Directionality.of(context) == TextDirection.rtl;
            final Offset begin = switch (_transition) {
              _Transition.appear => const Offset(0, 4),
              // Direction-aware: "next" slides in from the end side.
              _Transition.versionForward => Offset(rtl ? -12 : 12, 0),
              _Transition.versionBack => Offset(rtl ? 12 : -12, 0),
            };
            return FadeTransition(
              opacity: anim,
              child: AnimatedBuilder(
                animation: anim,
                child: child,
                builder: (_, child) => Transform.translate(offset: begin * (1 - anim.value), child: child),
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey('${s.status.name}-${s.style.id}-${s.current?.id}'), child: _body(context)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (s.status) {
    RewriteStatus.loading => _loading(context),
    RewriteStatus.streaming => _streaming(context),
    RewriteStatus.success => _success(context),
    RewriteStatus.error => _message(
      context,
      icon: AppIcons.alert,
      color: context.colors.textError,
      text: context.l10n.rw_error,
      action: AppButton(
        label: context.l10n.rw_retry,
        variant: AppButtonVariant.text,
        size: AppButtonSize.small,
        icon: AppIcons.regenerate,
        onPressed: widget.onRetry,
      ),
    ),
    RewriteStatus.rateLimited => _message(
      context,
      icon: AppIcons.clock,
      color: context.colors.textError,
      text: context.l10n.rw_rate_limited(s.retryAfter),
      live: false,
    ),
    RewriteStatus.planLimit => _message(
      context,
      icon: AppIcons.lock,
      color: context.colors.textSecondary,
      text: context.l10n.rw_plan_limit,
      action: s.canViewPlans && widget.onViewPlans != null
          ? AppButton(
              label: context.l10n.rw_view_plans,
              variant: AppButtonVariant.tonal,
              size: AppButtonSize.small,
              onPressed: widget.onViewPlans,
            )
          : null,
    ),
    RewriteStatus.blocked => _message(
      context,
      icon: AppIcons.alertTriangle,
      color: context.colors.textWarning,
      text: context.l10n.rw_blocked,
    ),
    RewriteStatus.offline => _message(
      context,
      icon: AppIcons.wifiOff,
      color: context.colors.textSecondary,
      text: context.l10n.rw_offline,
    ),
    RewriteStatus.tooLong => _message(
      context,
      icon: AppIcons.alertTriangle,
      color: context.colors.textWarning,
      text: context.l10n.rw_too_long,
    ),
  };

  // ---- Pieces --------------------------------------------------------------------------

  TextStyle _textStyle(BuildContext context) =>
      context.text.chatMessage.copyWith(fontSize: 14.5, height: 1.7, color: context.colors.textPrimary);

  TextDirection _dir(String language) => language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  double _maxTextHeight(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    // 200% text: grows to half the screen, still scrolling inside (§10).
    return scaled ? MediaQuery.sizeOf(context).height * 0.5 : 240;
  }

  Widget _labelRow(BuildContext context, {String? label, Widget? trailing}) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(AppIcons.sparkle, size: 13, color: c.primary)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label ?? context.l10n.rw_result,
                    style: context.text.caption.copyWith(fontWeight: FontWeight.w800, color: c.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _loading(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: AppSpacing.minTouch - 12, child: _labelRow(context)),
        AppSkeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in const [1.0, 0.92, 0.6]) ...[
                FractionallySizedBox(widthFactor: w, child: const SkeletonBox(height: 12)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Semantics(
          liveRegion: true,
          child: _AnimatedDots(
            text: context.l10n.rw_writing,
            style: context.text.caption.copyWith(color: c.onPrimaryContainer),
          ),
        ),
      ],
    );
  }

  Widget _streaming(BuildContext context) {
    final style = _textStyle(context);
    final lang = s.style.isTranslate ? s.targetLanguage : s.sourceLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppSpacing.minTouch - 12,
          child: _labelRow(context, label: context.l10n.rw_streaming),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: _maxTextHeight(context)),
          child: SingleChildScrollView(
            reverse: true, // keep the newest tokens in view
            child: Text.rich(
              TextSpan(
                text: s.streamingText,
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _Caret(color: context.colors.primary),
                  ),
                ],
              ),
              style: style,
              textDirection: _dir(lang),
            ),
          ),
        ),
      ],
    );
  }

  Widget _success(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final v = s.current!;
    final style = _textStyle(context);
    final dir = _dir(v.language);
    final count = s.currentVersions.length;
    final canDiff = !s.style.isTranslate && !v.unchanged && v.language == s.sourceLanguage;

    final Widget text;
    if (_editing) {
      text = TextField(
        controller: _editController,
        focusNode: _editFocus,
        style: style,
        textDirection: dir,
        minLines: 1,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        cursorColor: c.primary,
        decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
        onChanged: widget.onEdit,
      );
    } else {
      text = Semantics(
        hint: l.rw_a11y_edit_result,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _startEdit,
          onLongPressStart: (d) => _copyMenu(d.globalPosition),
          child: _showDiff && canDiff
              ? Text.rich(_diffSpan(context, s.source, v.effectiveText, style), textDirection: dir)
              : Text(v.effectiveText, style: style, textDirection: dir),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppSpacing.minTouch - 12,
          child: _labelRow(
            context,
            trailing: count > 1
                ? RewriteVersionPager(
                    index: s.currentIndex,
                    count: count,
                    onPrevious: widget.onPrevious,
                    onNext: widget.onNext,
                  )
                : null,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: _maxTextHeight(context)),
          child: SingleChildScrollView(child: text),
        ),
        if (v.edited)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l.rw_edited, style: context.text.overline.copyWith(color: c.textTertiary)),
          ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: RewriteResultIndicators(
            version: v,
            sourceLength: s.source.characters.length,
            resultLength: s.resultLength,
            overLimit: s.overLimit,
          ),
        ),
        if (canDiff && !_editing)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              label: _showDiff ? l.rw_hide_diff : l.rw_show_diff,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              horizontalPadding: AppSpacing.xs,
              onPressed: () => setState(() => _showDiff = !_showDiff),
            ),
          ),
      ],
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    Widget? action,
    bool live = true,
  }) {
    return Semantics(
      liveRegion: live,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: context.text.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: AlignmentDirectional.centerStart, child: action),
          ],
        ],
      ),
    );
  }

  // ---- Diff (v1.1) ---------------------------------------------------------------------

  /// Word-level LCS: added words on `primaryContainerBorder`, removed ones
  /// struck in `textTertiary`.
  TextSpan _diffSpan(BuildContext context, String source, String result, TextStyle style) {
    final c = context.colors;
    final a = source.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final b = result.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final n = a.length, m = b.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        dp[i][j] = a[i] == b[j] ? dp[i + 1][j + 1] + 1 : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
      }
    }
    final added = style.copyWith(backgroundColor: c.primaryContainerBorder);
    final removed = style.copyWith(
      color: c.textTertiary,
      decoration: TextDecoration.lineThrough,
      decorationColor: c.textTertiary,
    );
    final spans = <TextSpan>[];
    void push(String w, TextStyle? st) => spans.add(TextSpan(text: spans.isEmpty ? w : ' $w', style: st));
    var i = 0, j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        push(b[j], null);
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        push(a[i++], removed);
      } else {
        push(b[j++], added);
      }
    }
    while (i < n) {
      push(a[i++], removed);
    }
    while (j < m) {
      push(b[j++], added);
    }
    return TextSpan(style: style, children: spans);
  }
}

/// "يعيد الصياغة…" with animated dots; static under reduce motion.
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> {
  Timer? _timer;
  int _n = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!AppMotion.reduced(context)) {
      _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => setState(() => _n = _n % 3 + 1));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.text.replaceAll(RegExp(r'[.…]+$'), '');
    // Dots keep their slot so the line never jumps.
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: base),
          TextSpan(text: '.' * _n),
          TextSpan(
            text: '.' * (3 - _n),
            style: const TextStyle(color: Colors.transparent),
          ),
        ],
      ),
      style: widget.style,
      semanticsLabel: widget.text,
    );
  }
}

/// Blinking stream caret; solid under reduce motion (§10).
class _Caret extends StatefulWidget {
  const _Caret({required this.color});

  final Color color;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 530));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _ctrl.value = 1;
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(width: 2, height: 16, margin: const EdgeInsetsDirectional.only(start: 2), color: widget.color),
  );
}
