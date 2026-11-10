import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../conversations/domain/relative_time_formatter.dart';
import '../../../domain/kb_entry.dart';

/// Edit mode (Add Answer spec §4.10): "آخر تعديل {name} · {t} · استُخدم {n}
/// مرة" and the "سجل التغييرات" link.
class EditorMetaFooter extends StatelessWidget {
  const EditorMetaFooter({super.key, required this.entry, required this.onHistory});

  final KbQa entry;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final at = entry.updatedAt ?? entry.createdAt;
    final who = entry.updatedBy?.name ?? entry.createdBy?.name ?? '—';
    final when = at == null ? '—' : RelativeTimeFormatter.format(at, DateTime.now(), l, context.localeName);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.kbe_meta(who, when, '${entry.usage.month}'), style: t.caption.copyWith(color: c.textTertiary)),
          TextButton.icon(
            onPressed: onHistory,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
            icon: AppIcon(AppIcons.history, size: AppIconSize.sm, color: c.textLink),
            label: Text(l.kbe_history, style: t.bodySmall.copyWith(color: c.textLink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
