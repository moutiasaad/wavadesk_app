import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/kb_editor_validation.dart';
import 'question_field.dart';

/// Answer text with `{variable}` tokens as tonal inline spans and URLs
/// in link colour (Add Answer spec §4.5). Plain text is what's saved.
class KbAnswerTextController extends TextEditingController {
  KbAnswerTextController({super.text});

  static final _pattern = RegExp(r'\{[^{}\s]{1,40}\}|https?://[^\s]+');

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final c = context.colors;
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _pattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final s = m[0]!;
      spans.add(TextSpan(
        text: s,
        style: s.startsWith('{')
            ? TextStyle(color: c.onPrimaryContainer, backgroundColor: c.primaryContainer, fontWeight: FontWeight.w600)
            : TextStyle(color: c.textLink, decoration: TextDecoration.underline, decorationColor: c.textLink),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }
}

/// Variables offered after typing `{` (§4.5).
List<String> kbAnswerVariables(BuildContext context) => context.localeName.startsWith('ar')
    ? const ['{اسم_العميل}', '{رقم_الطلب}', '{رابط_التتبع}']
    : const ['{customer_name}', '{order_number}', '{tracking_link}'];

/// "الإجابة" (§4.5): focused-style multiline field, min ≈4 lines, grows to
/// 12, counter from 1,600 chars, variable chips, AI-draft tag above.
class AnswerField extends StatefulWidget {
  const AnswerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.error,
    this.aiDraft = false,
    this.enabled = true,
  });

  final KbAnswerTextController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool aiDraft;
  final bool enabled;

  @override
  State<AnswerField> createState() => _AnswerFieldState();
}

class _AnswerFieldState extends State<AnswerField> {
  bool _vars = false;

  void _changed(String v) {
    final sel = widget.controller.selection;
    final at = sel.isValid ? sel.baseOffset : v.length;
    setState(() => _vars = at > 0 && at <= v.length && v[at - 1] == '{');
    widget.onChanged(v);
  }

  void _insert(String token) {
    final ctl = widget.controller;
    final text = ctl.text;
    final sel = ctl.selection;
    final at = sel.isValid ? sel.baseOffset : text.length;
    final start = at > 0 && text[at - 1] == '{' ? at - 1 : at;
    final next = text.replaceRange(start, at, token);
    ctl.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + token.length));
    setState(() => _vars = false);
    widget.onChanged(next);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final n = widget.controller.text.trim().runes.length;
    final showCounter = n >= KbEditorValidation.answerCounterFrom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.kbe_answer, style: t.inputLabel),
        if (widget.aiDraft) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.ai, dp: 11, color: c.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l.kbe_ai_draft_tag, style: t.caption.copyWith(color: c.onPrimaryContainer, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: AppTextField(
            hint: l.kbe_answer_ph,
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: _changed,
            error: widget.error,
            readOnly: !widget.enabled,
            minLines: 4,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textDirection: autoTextDirection(widget.controller.text),
            textCapitalization: TextCapitalization.sentences,
            style: t.bodyLarge.copyWith(height: 1.7),
          ),
        ),
        if (showCounter)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l.kbe_counter('$n'),
                textAlign: TextAlign.end,
                style: t.caption.copyWith(color: n > KbEditorValidation.answerMax ? c.textError : c.textTertiary),
              ),
            ),
          ),
        AnimatedSize(
          duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.fast,
          child: _vars
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in kbAnswerVariables(context))
                        AppFilterChip(label: v, selected: false, onTap: () => _insert(v)),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
