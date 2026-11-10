import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Login spec §4.9: line · 12 · "أو" (caption 12.5/700, `textTertiary`) · 12 · line.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(height: 1, thickness: 1, color: c.divider)),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: context.text.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textTertiary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Divider(height: 1, thickness: 1, color: c.divider)),
      ],
    );
  }
}
