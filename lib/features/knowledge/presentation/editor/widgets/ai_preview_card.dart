import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../ai_agent/domain/ai_agent_config.dart';
import '../../../../ai_agent/presentation/test/ai_why_sheet.dart' show aiToneLabel;
import '../../../data/kb_editor_api.dart';
import 'question_field.dart';

/// "معاينة: كيف سيردّ الذكاء" (Add Answer spec §4.8): soft card with a
/// customer test question and the AI reply in the workspace tone.
class AiPreviewCard extends StatefulWidget {
  const AiPreviewCard({
    super.key,
    required this.preview,
    required this.loading,
    required this.error,
    required this.offline,
    required this.ready,
    required this.fallbackQuestion,
    required this.onRefresh,
    required this.onTestQuestion,
    required this.onTryAnother,
    required this.onTone,
  });

  final KbPreview? preview;
  final bool loading;
  final bool error;
  final bool offline;

  /// Question + answer valid → a preview can be generated.
  final bool ready;

  /// Shown in the customer bubble before the first preview.
  final String fallbackQuestion;
  final VoidCallback onRefresh;
  final ValueChanged<String> onTestQuestion;
  final VoidCallback onTryAnother;

  /// "بنبرة: ودود" → AI settings.
  final VoidCallback onTone;

  @override
  State<AiPreviewCard> createState() => _AiPreviewCardState();
}

class _AiPreviewCardState extends State<AiPreviewCard> {
  bool _editing = false;
  final _test = TextEditingController();

  @override
  void dispose() {
    _test.dispose();
    super.dispose();
  }

  void _startEdit(String current) => setState(() {
        _editing = true;
        _test.text = current;
        _test.selection = TextSelection(baseOffset: 0, extentOffset: current.length);
      });

  void _submit() {
    setState(() => _editing = false);
    widget.onTestQuestion(_test.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = widget.preview;
    final reduced = AppMotion.reduced(context);
    final question = p?.testQuestion ?? widget.fallbackQuestion;
    final bubbleText = t.chatMessage.copyWith(fontSize: 13.5);

    // ---- AI bubble content ----
    final Widget aiContent;
    if (widget.offline) {
      aiContent = Text(l.kbe_preview_offline, key: const ValueKey('off'), style: bubbleText.copyWith(color: c.textTertiary));
    } else if (widget.error) {
      aiContent = Row(
        key: const ValueKey('err'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(l.kbe_preview_err, style: bubbleText.copyWith(color: c.textError))),
          IconButton(
            onPressed: widget.onRefresh,
            tooltip: l.kbe_retry,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: Icon(AppIcons.regenerate, color: c.textSecondary),
          ),
        ],
      );
    } else if (widget.loading) {
      final lines = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonBox(width: 180, height: 10),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 120, height: 10),
          const SizedBox(height: AppSpacing.sm),
          Text(l.kbe_writing, style: t.caption.copyWith(color: c.textTertiary)),
        ],
      );
      aiContent = KeyedSubtree(key: const ValueKey('load'), child: reduced ? lines : AppSkeleton(child: lines));
    } else if (p != null) {
      aiContent = Semantics(
        liveRegion: true,
        child: SelectableText(p.reply, key: ValueKey(p.reply), style: bubbleText.copyWith(color: c.textPrimary), textDirection: autoTextDirection(p.reply)),
      );
    } else {
      aiContent = Text(l.kbe_preview_empty, key: const ValueKey('empty'), style: bubbleText.copyWith(color: c.textTertiary));
    }

    final confidence = p?.confidence;
    final (confLabel, confFg, confBg) = switch (confidence) {
      KbConfidence.high => (l.kbe_conf_high, c.textSuccess, c.successContainer),
      KbConfidence.medium => (l.kbe_conf_med, c.textWarning, c.warningContainer),
      KbConfidence.low => (l.kbe_conf_low, c.textError, c.errorContainer),
      null => ('', c.textSecondary, c.surfaceVariant),
    };

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: c.backgroundMuted, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.eye, size: 13, color: c.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l.kbe_preview, style: t.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: c.textSecondary)),
              ),
              if (widget.ready && !widget.offline)
                IconButton(
                  onPressed: widget.loading ? null : widget.onRefresh,
                  tooltip: l.kbe_preview_regen,
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(AppIcons.regenerate, color: c.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Customer bubble — tap to edit the test question.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
              child: Material(
                color: c.bubbleIncoming,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(AppRadius.bubbleTail),
                    topEnd: Radius.circular(AppRadius.xl),
                    bottomStart: Radius.circular(AppRadius.xl),
                    bottomEnd: Radius.circular(AppRadius.xl),
                  ).resolve(Directionality.of(context)),
                  side: c.isDark ? BorderSide(color: c.divider) : BorderSide.none,
                ),
                child: InkWell(
                  onTap: _editing || !widget.ready ? null : () => _startEdit(question),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: _editing
                        ? SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _test,
                              autofocus: true,
                              style: bubbleText.copyWith(color: c.textPrimary),
                              onSubmitted: (_) => _submit(),
                              onTapOutside: (_) => _submit(),
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: l.kbe_test_hint,
                                hintStyle: bubbleText.copyWith(color: c.textTertiary),
                              ),
                            ),
                          )
                        : Text(
                            question.isEmpty ? '…' : question,
                            style: bubbleText.copyWith(color: c.textPrimary),
                            textDirection: autoTextDirection(question),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // AI bubble.
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: c.bubbleAi,
                  border: Border.all(color: c.bubbleAiBorder),
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(AppRadius.xl),
                    topEnd: Radius.circular(AppRadius.bubbleTail),
                    bottomStart: Radius.circular(AppRadius.xl),
                    bottomEnd: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.sparkle, size: 11, color: c.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(l.kbe_ai_label, style: t.chatSenderLabel.copyWith(color: c.primary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedSwitcher(
                      duration: reduced ? Duration.zero : AppMotion.normal,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: AlignmentDirectional.topStart,
                        children: [...previous, ?current],
                      ),
                      child: aiContent,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (p != null && !widget.loading && !widget.error && !widget.offline) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: widget.onTone,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      l.kbe_tone(aiToneLabel(l, AiTone.parse(p.tone))),
                      style: t.caption.copyWith(color: c.textLink, decoration: TextDecoration.underline, decorationColor: c.textLink),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(color: confBg, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text(confLabel, style: t.caption.copyWith(color: confFg, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (confidence == KbConfidence.low)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(l.kbe_low_hint, style: t.caption.copyWith(color: c.textWarning)),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: widget.onTryAnother,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
                child: Text(l.kbe_try_another, style: t.bodySmall.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
