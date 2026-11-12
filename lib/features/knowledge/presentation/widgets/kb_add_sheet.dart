import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';
import 'kb_entry_tile.dart';

/// What the "add" sheet starts.
enum KbAddChoice {
  /// Write one entry (the web form).
  qa,

  /// The web panel's JSON file of many entries.
  json,
}

/// "إضافة إلى قاعدة المعرفة" (spec §5). Returns the choice; the caller
/// opens the editor / picker / link flow after the sheet closes.
Future<KbAddChoice?> showKbAddSheet(BuildContext context) async {
  final l = context.l10n;
  final picked = await AppBottomSheet.show<KbAddChoice>(
    context,
    title: l.kb_add_title,
    builder: (ctx) {
      final c = ctx.colors;
      final dark = c.isDark;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Option(choice: KbAddChoice.qa, visual: KbTypeVisual.of(ctx, KbType.qa), title: l.kb_qa, subtitle: l.kb_add_qa_sub),
            _Option(
              choice: KbAddChoice.json,
              visual: KbTypeVisual(AppIcons.upload, dark ? const Color(0xFF1F2430) : c.surfaceVariant, c.textSecondary),
              title: l.kb_import_title,
              subtitle: l.kb_add_file_sub,
            ),
          ],
        ),
      );
    },
  );
  if (picked != null) Analytics.log('kb_add_start', {'type': picked.name});
  return picked;
}

class _Option extends StatelessWidget {
  const _Option({required this.choice, required this.visual, required this.title, required this.subtitle});

  final KbAddChoice choice;
  final KbTypeVisual visual;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(choice),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: AppIcon(visual.icon, color: visual.foreground),
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
              AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}
