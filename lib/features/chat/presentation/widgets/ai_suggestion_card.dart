import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../application/ai_suggestion_controller.dart';

/// AI suggestion card (Chat spec §4.6, DS §8.5): full card, loading
/// shimmer, collapsed "اقتراح جاهز" pill, the on-demand "suggest a reply"
/// button, or the no-answer row.
class AiSuggestionCard extends ConsumerStatefulWidget {
  const AiSuggestionCard({super.key, required this.conversationId, required this.onEdit, required this.onAddAnswer});

  final String conversationId;
  final void Function(String text) onEdit;
  final void Function(String question) onAddAnswer;

  @override
  ConsumerState<AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends ConsumerState<AiSuggestionCard> {
  /// The suggestion just arrived after the AI loading state: glow once.
  bool _glow = false;

  String get conversationId => widget.conversationId;
  void Function(String text) get onEdit => widget.onEdit;
  void Function(String question) get onAddAnswer => widget.onAddAnswer;

  @override
  Widget build(BuildContext context) {
    ref.listen(aiSuggestionControllerProvider(conversationId).select((s) => s.view), (prev, next) {
      if (next == AiCardView.card) _glow = prev == AiCardView.loading;
    });
    final s = ref.watch(aiSuggestionControllerProvider(conversationId));
    final ctrl = ref.read(aiSuggestionControllerProvider(conversationId).notifier);

    final Widget child = switch (s.view) {
      AiCardView.hidden => const SizedBox(key: ValueKey('hidden'), width: double.infinity),
      AiCardView.idle => _ReadyPill(key: const ValueKey('idle'), label: context.l10n.chat_ai_suggest_pill, onTap: ctrl.request),
      AiCardView.collapsed => _ReadyPill(key: const ValueKey('pill'), label: context.l10n.chat_ai_ready_pill, onTap: ctrl.expandFromPill),
      AiCardView.noAnswer => _NoAnswerRow(
        key: const ValueKey('noanswer'),
        onAdd: () {
          final msgs = ref.read(conversationProvider(conversationId))?.messages ?? const <Message>[];
          final question = msgs.lastWhere(
            (m) => m.type == MessageBubbleType.incoming && m.text.isNotEmpty,
            orElse: () => Message(id: '', type: MessageBubbleType.incoming, sentAt: DateTime.now()),
          );
          onAddAnswer(question.text);
        },
      ),
      AiCardView.loading => const _CardShell(key: ValueKey('loading'), child: _LoadingBody()),
      AiCardView.card => _CardShell(
        key: const ValueKey('card'),
        glow: _glow,
        onSwipeDown: () => ctrl.collapse(),
        child: _CardBody(
          state: s,
          onSend: ctrl.send,
          onEdit: () {
            final text = ctrl.edit();
            if (text != null) onEdit(text);
          },
          onRegenerate: ctrl.regenerate,
          onToggleBody: ctrl.toggleBody,
          onSource: () {
            final title = s.suggestion?.source;
            final entry = ref.read(knowledgeProvider).where((k) => k.title == title).firstOrNull;
            entry == null ? context.go(Routes.knowledge) : context.push(Routes.editKnowledge(entry.id));
          },
        ),
      ),
    };

    final reduced = AppMotion.reduced(context);
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        reverseDuration: AppMotion.normal,
        switchInCurve: AppMotion.standard,
        transitionBuilder: (child, anim) => reduced
            ? FadeTransition(opacity: anim, child: child)
            : FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  // Enter: slide up 16dp.
                  position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
        child: child,
      ),
    );
  }
}

/// Container: margin H10 bottom 8, radius 20, surface (dark elevated),
/// 1dp primaryContainerBorder, upward teal glow.
class _CardShell extends StatefulWidget {
  const _CardShell({super.key, required this.child, this.onSwipeDown, this.glow = false});

  final Widget child;
  final VoidCallback? onSwipeDown;

  /// Green glow around the card that fades out (suggestion just generated).
  final bool glow;

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.glow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _glow.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Widget get child => widget.child;
  VoidCallback? get onSwipeDown => widget.onSwipeDown;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        // Quick bloom over the first 25%, then a slow fade.
        final t = _glow.value;
        final g = t == 0 || t == 1 ? 0.0 : (t < 0.25 ? t / 0.25 : 1 - (t - 0.25) / 0.75);
        return _shell(context, c, reduced ? 0.0 : Curves.easeOut.transform(g.clamp(0.0, 1.0)));
      },
    );
  }

  Widget _shell(BuildContext context, AppColors c, double glow) {
    return GestureDetector(
      onVerticalDragEnd: onSwipeDown == null
          ? null
          : (d) {
              if ((d.primaryVelocity ?? 0) > 250) onSwipeDown!();
            },
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceElevated : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: Color.lerp(c.primaryContainerBorder, c.success, glow)!,
            width: 1 + glow * 0.5,
          ),
          boxShadow: [
            if (c.isDark)
              ...context.shadows.mediumUp
            else
              // Spec value: 0 -8 24 -14 rgba(15,126,122,.45).
              const BoxShadow(offset: Offset(0, -8), blurRadius: 24, spreadRadius: -14, color: Color(0x730F7E7A)),
            if (glow > 0)
              BoxShadow(blurRadius: 22 * glow, spreadRadius: 3 * glow, color: c.success.withValues(alpha: 0.45 * glow)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.source, this.onSource});

  final String? source;
  final VoidCallback? onSource;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Row(
      children: [
        AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              l.chat_ai_suggestion,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800, color: c.textPrimary),
              maxLines: 1,
            ),
          ),
        ),
        const Spacer(),
        if (source != null && source!.isNotEmpty)
          Flexible(
            flex: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              onTap: onSource,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                child: Text(
                  l.chat_ai_source(source!),
                  style: t.caption.copyWith(fontWeight: FontWeight.w500, color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.state,
    required this.onSend,
    required this.onEdit,
    required this.onRegenerate,
    required this.onToggleBody,
    required this.onSource,
  });

  final AiSuggestionState state;
  final VoidCallback onSource;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback onRegenerate;
  final VoidCallback onToggleBody;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = state.suggestion!;
    final bodyStyle = t.chatMessage.copyWith(height: 1.65, color: c.textPrimary);

    return Semantics(
      container: true,
      label: l.chat_ai_suggestion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(source: s.source, onSource: onSource),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, box) {
              final overflows = (TextPainter(
                text: TextSpan(text: s.text, style: bodyStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 5,
              )..layout(maxWidth: box.maxWidth)).didExceedMaxLines;
              return GestureDetector(
                onTap: overflows || state.expanded ? onToggleBody : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.text,
                      style: bodyStyle,
                      maxLines: state.expanded ? null : 5,
                      overflow: state.expanded ? null : TextOverflow.ellipsis,
                    ),
                    if (overflows || state.expanded)
                      Text(
                        state.expanded ? l.aicard_less : l.chat_ai_more,
                        style: t.buttonSmall.copyWith(color: c.primary),
                      ),
                  ],
                ),
              );
            },
          ),
          if (state.lowConfidence) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                AppIcon(AppIcons.warning, size: AppIconSize.sm, color: c.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l.chat_ai_low_conf, style: t.caption.copyWith(color: c.textWarning)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardAction(label: l.chat_ai_send, icon: AppIcons.send, filled: true, onTap: onSend),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CardAction(label: l.chat_ai_edit, icon: AppIcons.edit, onTap: onEdit),
              const SizedBox(width: AppSpacing.sm),
              _CardAction(icon: AppIcons.regenerate, semanticLabel: l.aicard_regenerate, onTap: onRegenerate),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatefulWidget {
  const _LoadingBody();

  @override
  State<_LoadingBody> createState() => _LoadingBodyState();
}

/// AI loading inside the card: the ✦ pulses next to "يكتب الاقتراح…", three
/// lines with a teal light sweeping across, and the button row as quiet
/// placeholders so the card keeps its final size.
class _LoadingBodyState extends State<_LoadingBody> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _t.stop();
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      label: l.chat_ai_writing,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final v = _t.value;
            // 0.55 → 1 → 0.55 over one loop.
            final pulse = 0.55 + 0.45 * (1 - (2 * v - 1).abs());
            Widget line(double factor) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: factor,
                  child: Container(
                    height: 10,
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment(-3 + 4 * v, 0),
                        end: Alignment(-1 + 4 * v, 0),
                        colors: [c.primaryContainer, c.primary.withValues(alpha: 0.28), c.primaryContainer],
                      ),
                    ),
                  ),
                );
            Widget slot({double? width}) => Container(
                  height: 40,
                  width: width,
                  decoration: BoxDecoration(
                    color: c.surfaceVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.85 + 0.25 * pulse,
                      child: Opacity(opacity: pulse, child: AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.primary)),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l.chat_ai_suggestion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(fontWeight: FontWeight.w800, color: c.textPrimary),
                      ),
                    ),
                    const Spacer(),
                    Text(l.chat_ai_writing, style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                line(1),
                line(0.86),
                line(0.55),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(child: slot()),
                    const SizedBox(width: AppSpacing.sm),
                    slot(width: 86),
                    const SizedBox(width: AppSpacing.sm),
                    slot(width: 40),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 40dp card button: teal filled (send) or white outlined (edit); with no
/// [label] it is a 40×40 rounded square (regenerate).
class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.onTap, this.label, this.semanticLabel, this.filled = false});

  final IconData icon;
  final String? label;
  final String? semanticLabel;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = filled ? c.onPrimary : c.textPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: filled ? BorderSide.none : BorderSide(color: c.border),
    );
    return Semantics(
      button: true,
      label: label ?? semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: filled ? c.primary : c.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            height: 40,
            width: label == null ? 40 : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(icon, dp: 16, color: fg),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(label!, style: context.text.buttonMedium.copyWith(color: fg)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// h32 `primaryContainer` pill: sparkle + "اقتراح جاهز".
class _ReadyPill extends StatelessWidget {
  const _ReadyPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: c.primaryContainer,
            shape: StadiumBorder(side: BorderSide(color: c.primaryContainerBorder)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.primary),
                    const SizedBox(width: 6),
                    Text(label, style: context.text.buttonSmall.copyWith(color: c.onPrimaryContainer)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// h40 warning row: no answer in the knowledge base + "أضف إجابة".
class _NoAnswerRow extends StatelessWidget {
  const _NoAnswerRow({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, AppSpacing.sm),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.xs),
      decoration: BoxDecoration(color: c.warningContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.textWarning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(l.chat_ai_no_answer, style: t.caption.copyWith(color: c.textWarning)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: c.textWarning,
              textStyle: t.buttonSmall,
              minimumSize: const Size(48, 40),
            ),
            onPressed: onAdd,
            child: Text(l.chat_ai_add_answer),
          ),
        ],
      ),
    );
  }
}
