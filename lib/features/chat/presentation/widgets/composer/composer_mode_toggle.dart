import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/composer_controller.dart';

/// رد / ملاحظة داخلية — 32dp segmented mini-toggle above the field
/// (Chat spec §4.7.1).
class ComposerModeToggle extends StatelessWidget {
  const ComposerModeToggle({super.key, required this.mode, required this.onChanged});

  final ComposerMode mode;
  final ValueChanged<ComposerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SizedBox(
        width: 260,
        child: AppSegmented<ComposerMode>(
          height: 32,
          selected: mode,
          onChanged: onChanged,
          segments: [
            AppSegment(value: ComposerMode.reply, label: l.chat_mode_reply),
            AppSegment(value: ComposerMode.note, label: l.chat_mode_note, selectedColor: c.noteBackground),
          ],
        ),
      ),
    );
  }
}
