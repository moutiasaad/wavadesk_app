import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// "ملاحظة للزميل (اختياري)" — compact, grows to 4 lines, 500 max with a
/// counter from 450; quick chips appear on focus (Assign spec §5.9).
class AssignNoteField extends StatefulWidget {
  const AssignNoteField({super.key, required this.controller, this.enabled = true});

  final TextEditingController controller;
  final bool enabled;

  static const maxLength = 500;
  static const counterFrom = 450;

  @override
  State<AssignNoteField> createState() => _AssignNoteFieldState();
}

class _AssignNoteFieldState extends State<AssignNoteField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onText);
  }

  void _onText() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _insert(String text) {
    final cur = widget.controller.text.trimRight();
    final next = cur.isEmpty ? text : '$cur — $text';
    final clipped = next.length > AssignNoteField.maxLength ? next.substring(0, AssignNoteField.maxLength) : next;
    widget.controller.value = TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final len = widget.controller.text.characters.length;
    final showQuick = _focus.hasFocus && widget.enabled;
    final reduced = AppMotion.reduced(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: reduced ? Duration.zero : AppMotion.fast,
          alignment: AlignmentDirectional.bottomStart,
          child: !showQuick
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final q in [l.as_note_q1, l.as_note_q2, l.as_note_q3]) ...[
                          AppFilterChip(label: q, selected: false, onTap: () => _insert(q)),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
        AppTextField(
          controller: widget.controller,
          focusNode: _focus,
          hint: l.as_note,
          prefixIcon: AppIcons.note,
          enabled: widget.enabled,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          // `@` mentions are off — the receiver is implicit.
          inputFormatters: [
            LengthLimitingTextInputFormatter(AssignNoteField.maxLength),
            FilteringTextInputFormatter.deny(RegExp('@')),
          ],
        ),
        if (len >= AssignNoteField.counterFrom)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '$len/${AssignNoteField.maxLength}',
              textAlign: TextAlign.end,
              style: context.text.caption.copyWith(
                color: len >= AssignNoteField.maxLength ? c.textError : c.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
