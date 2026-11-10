import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_suggestion_controller.dart';

/// AI suggestion card (Chat spec §4.6, DS §8.5): full card, loading
/// shimmer, collapsed "اقتراح جاهز" pill, or the no-answer row.
class AiSuggestionCard extends ConsumerWidget {
  const AiSuggestionCard({super.key, required this.conversationId, required this.onEdit, required this.onAddAnswer});

  final String conversationId;
  final void Function(String text) onEdit;
  final void Function(String question) onAddAnswer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(aiSuggestionControllerProvider(conversationId));
    final ctrl = ref.read(aiSuggestionControllerProvider(conversationId).notifier);

    final Widget child = switch (s.view) {
      AiCardView.hidden => const SizedBox(key: ValueKey('hidden'), width: double.infinity),
      AiCardView.collapsed => _ReadyPill(key: const ValueKey('pill'), onTap: ctrl.expandFromPill),
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
        onSwipeDown: () => ctrl.collapse(),
        child: _CardBody(
          state: s,
          onClose: () => ctrl.collapse(),
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
class _CardShell extends StatelessWidget {
  const _CardShell({super.key, required this.child, this.onSwipeDown});

  final Widget child;
  final VoidCallback? onSwipeDown;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onVerticalDragEnd: onSwipeDown == null
          ? null
          : (d) {
              if ((d.primaryVelocity ?? 0) > 250) onSwipeDown!();
            },
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceElevated : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: c.primaryContainerBorder),
          boxShadow: c.isDark
              ? context.shadows.mediumUp
              : const [
                  // Spec value: 0 -8 24 -14 rgba(15,126,122,.45).
                  BoxShadow(offset: Offset(0, -8), blurRadius: 24, spreadRadius: -14, color: Color(0x730F7E7A)),
                ],
        ),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.source, this.onClose, this.onSource});

  final String? source;
  final VoidCallback? onClose;
  final VoidCallback? onSource;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Row(
      children: [
        Icon(AppIcons.sparkle, size: 16, color: c.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              l.chat_ai_suggestion,
              style: t.caption.copyWith(fontWeight: FontWeight.w800, color: c.onPrimaryContainer),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                child: Text(
                  l.chat_ai_source(source!),
                  style: t.overline.copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        if (onClose != null)
          AppIconButton(
            icon: AppIcons.close,
            size: 28,
            iconSize: 16,
            iconColor: c.textTertiary,
            semanticLabel: l.aicard_close,
            onPressed: onClose,
          ),
      ],
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.state,
    required this.onClose,
    required this.onSend,
    required this.onEdit,
    required this.onRegenerate,
    required this.onToggleBody,
    required this.onSource,
  });

  final AiSuggestionState state;
  final VoidCallback onSource;
  final VoidCallback onClose;
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
    final bodyStyle = t.chatMessage.copyWith(fontSize: 14, height: 1.65);

    return Semantics(
      container: true,
      label: l.chat_ai_suggestion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(source: s.source, onClose: onClose, onSource: onSource),
          const SizedBox(height: 2),
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
                Icon(AppIcons.alertTriangle, size: 14, color: c.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l.chat_ai_low_conf, style: t.caption.copyWith(color: c.textWarning)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(label: l.chat_ai_send, icon: AppIcons.send, expand: true, onPressed: onSend),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.chat_ai_edit,
                icon: AppIcons.edit,
                variant: AppButtonVariant.secondary,
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: AppIcons.regenerate,
                variant: AppIconButtonVariant.outlined,
                semanticLabel: l.aicard_regenerate,
                onPressed: onRegenerate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      label: l.chat_ai_writing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Header(),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, box) => AppSkeleton(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: box.maxWidth, height: 10),
                  const SizedBox(height: 8),
                  SkeletonBox(width: box.maxWidth * 0.85, height: 10),
                  const SizedBox(height: 8),
                  SkeletonBox(width: box.maxWidth * 0.55, height: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Text(l.chat_ai_writing, style: context.text.caption.copyWith(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// h32 `primaryContainer` pill: sparkle + "اقتراح جاهز".
class _ReadyPill extends StatelessWidget {
  const _ReadyPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Center(
        child: Semantics(
          button: true,
          label: l.aicard_open_pill,
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
                    Icon(AppIcons.sparkle, size: 14, color: c.primary),
                    const SizedBox(width: 6),
                    Text(l.chat_ai_ready_pill, style: context.text.buttonSmall.copyWith(color: c.onPrimaryContainer)),
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
          Icon(AppIcons.sparkle, size: 14, color: c.textWarning),
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
