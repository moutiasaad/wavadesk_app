import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// "ابحث في {n} مدخلًا": h44, `surface`, 1dp `border` on the grouped
/// background. Not editable here — opens Search with scope=kb (spec §4.2).
class KbSearchEntry extends StatelessWidget {
  const KbSearchEntry({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hint = context.l10n.kb_search(total);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Semantics(
        button: true,
        label: hint,
        excludeSemantics: true,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: c.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => context.push('${Routes.search}?scope=kb'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                child: Row(
                  children: [
                    Icon(AppIcons.search, size: 16, color: c.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(hint, style: context.text.bodyMedium.copyWith(color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
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
