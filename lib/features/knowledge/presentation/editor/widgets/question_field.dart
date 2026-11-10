import 'package:flutter/material.dart';

import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/kb_editor_validation.dart';

/// Direction of the first strong character; null (inherit) when none.
TextDirection? autoTextDirection(String text) {
  for (final r in text.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFEFC)) return TextDirection.rtl;
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A) || (r >= 0xC0 && r <= 0x24F)) return TextDirection.ltr;
  }
  return null;
}

/// "السؤال" (Add Answer spec §4.3): h52 field, 15px text, auto direction,
/// 1–4 visible lines, 5–200 chars.
class QuestionField extends StatelessWidget {
  const QuestionField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.error,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppTextField(
      label: l.kbe_question,
      hint: l.kbe_question_ph,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      error: error,
      textDirection: autoTextDirection(controller.text),
      autofocus: autofocus,
      readOnly: !enabled,
      minLines: 1,
      maxLines: 4,
      maxLength: KbEditorValidation.questionMax,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
