import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/state/load_state.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';
import '../sheets/wa_template_preview_sheet.dart';
import '../wa_links.dart';

final waTemplatesProvider = FutureProvider.autoDispose<List<WaTemplate>>((ref) {
  ref.cacheFor(const Duration(minutes: 5)); // reopening is instant
  return ref.watch(whatsAppApiProvider).templates();
});

String waTemplateCategoryLabel(AppLocalizations l, WaTemplateCategory c) => switch (c) {
      WaTemplateCategory.marketing => l.wa_tpl_marketing,
      WaTemplateCategory.utility => l.wa_tpl_utility,
      WaTemplateCategory.authentication => l.wa_tpl_auth,
    };

Widget waTemplateStatusBadge(BuildContext context, WaTemplateStatus s) {
  final c = context.colors;
  final l = context.l10n;
  return switch (s) {
    WaTemplateStatus.approved => StatusBadge(label: l.wa_tpl_approved, foreground: c.textSuccess, background: c.successContainer, compact: true),
    WaTemplateStatus.pending => StatusBadge(label: l.wa_tpl_pending, foreground: c.textWarning, background: c.warningContainer, compact: true),
    WaTemplateStatus.rejected => StatusBadge(label: l.wa_tpl_rejected, foreground: c.textError, background: c.errorContainer, compact: true),
  };
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template});

  final WaTemplate template;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final tpl = template;
    return InkWell(
      onTap: () => showWaTemplatePreviewSheet(context, tpl),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tpl.displayName ?? tpl.name, style: t.listTitle.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(tpl.name, textDirection: TextDirection.ltr, style: t.caption.copyWith(color: c.textTertiary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(waTemplateCategoryLabel(l, tpl.category), style: t.tagLabel.copyWith(color: c.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            waTemplateStatusBadge(context, tpl.status),
            const SizedBox(width: AppSpacing.xs),
            AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
          ],
        ),
      ),
    );
  }
}

/// "القوالب المعتمدة" (cloud_api only, WhatsApp spec §4.5).
class WaTemplatesSection extends ConsumerWidget {
  const WaTemplatesSection({super.key, this.limit});

  /// Rows shown on the channel screen (the full list is `/templates`).
  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(waTemplatesProvider);
    final list = async.valueOrNull ?? const <WaTemplate>[];
    final shown = limit == null ? list : list.take(limit!).toList();
    return SettingsGroup(
      title: l.wa_templates,
      children: [
        if (!async.hasValue && async.hasError)
          SettingsTile(title: l.wa_load_error, value: l.wa_retry, onTap: () => ref.invalidate(waTemplatesProvider))
        else if (!async.hasValue)
          const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: AppSpinner()))
        else if (list.isEmpty)
          SettingsTile(title: l.wa_tpl_empty, showChevron: false)
        else
          for (final tpl in shown) _TemplateRow(template: tpl),
        SettingsTile(
          icon: AppIcons.globe,
          title: l.wa_tpl_manage_web,
          onTap: WaLinks.templatesOnWeb,
        ),
      ],
    );
  }
}

/// `/settings/whatsapp/templates`.
class WaTemplatesScreen extends StatelessWidget {
  const WaTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: context.l10n.wa_templates, background: c.backgroundMuted),
      body: ListView(
        padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
        children: const [WaTemplatesSection()],
      ),
    );
  }
}
