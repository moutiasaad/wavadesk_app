import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';
import 'kb_entry_tile.dart';

/// "إضافة إلى قاعدة المعرفة" (spec §5). Returns the chosen type; the
/// caller opens the editor / upload / link flow after the sheet closes.
Future<KbType?> showKbAddSheet(BuildContext context) async {
  final l = context.l10n;
  final picked = await AppBottomSheet.show<KbType>(
    context,
    title: l.kb_add_title,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Option(type: KbType.qa, title: l.kb_qa, subtitle: l.kb_add_qa_sub),
          _Option(type: KbType.file, title: l.kb_add_file, subtitle: l.kb_add_file_sub),
          _Option(type: KbType.link, title: l.kb_add_link, subtitle: l.kb_add_link_sub),
        ],
      ),
    ),
  );
  if (picked != null) Analytics.log('kb_add_start', {'type': picked.name});
  return picked;
}

class _Option extends StatelessWidget {
  const _Option({required this.type, required this.title, required this.subtitle});

  final KbType type;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final v = KbTypeVisual.of(context, type);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(type),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: v.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(v.icon, size: 22, color: v.foreground),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.listTitle),
                    Text(subtitle, style: t.bodySmall.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              Icon(AppIcons.chevronEnd, size: 16, color: c.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}
