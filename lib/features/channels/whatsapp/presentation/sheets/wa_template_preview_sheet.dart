import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/wa_channel.dart';
import '../editors/wa_message_preview.dart';
import '../widgets/wa_templates_section.dart' show waTemplateCategoryLabel, waTemplateStatusBadge;

/// Template preview: rendered bubble with `{{n}}` variables (§4.5).
Future<void> showWaTemplatePreviewSheet(BuildContext context, WaTemplate template) => AppBottomSheet.show<void>(
      context,
      title: template.displayName ?? template.name,
      subtitle: context.l10n.wa_tpl_preview,
      builder: (_) => _Preview(template: template),
    );

class _Preview extends StatelessWidget {
  const _Preview({required this.template});

  final WaTemplate template;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(template.name, textDirection: TextDirection.ltr, style: t.caption.copyWith(color: c.textTertiary)),
              const Spacer(),
              Text(waTemplateCategoryLabel(l, template.category), style: t.caption.copyWith(color: c.textSecondary)),
              const SizedBox(width: AppSpacing.sm),
              waTemplateStatusBadge(context, template.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WaMessagePreview(text: template.body, buttons: template.buttons, highlightTemplateVars: true),
        ],
      ),
    );
  }
}
