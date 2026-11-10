import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// "{n} رسائل جديدة" (Chat spec §4.3): full-width 1dp `primary` line with a
/// centered `primaryContainer` pill (`caption` 700).
class UnreadDivider extends StatelessWidget {
  const UnreadDivider({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 1, color: c.primary),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: c.primaryContainerBorder),
              ),
              child: Text(
                context.l10n.chat_new_messages(count),
                style: context.text.caption.copyWith(fontWeight: FontWeight.w700, color: c.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
