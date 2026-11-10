import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/wd_api_provider.dart';
import '../../../../../core/data/data.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../data/messages_repository.dart';

/// Approved templates from the server.
final _sheetTemplatesProvider = FutureProvider.autoDispose<List<MessageTemplate>>((ref) async {
  final api = ref.watch(wdApiRequiredProvider);
  final r = await api.get('whatsapp/templates');
  return [
    for (final m in r.list)
      if (m['status'] == null || m['status'] == 'approved')
        MessageTemplate(
          id: '${m['id']}',
          name: '${m['display_name'] ?? m['name'] ?? ''}',
          body: '${m['body'] ?? ''}',
          category: '${m['category'] ?? ''}',
        ),
  ];
});

/// Approved WhatsApp templates (Chat spec §4.11 "اختر قالبًا", attach sheet
/// "قالب واتساب"). Variables are previewed with the contact's data.
Future<void> showTemplatesSheet(BuildContext context, WidgetRef ref, {required String conversationId}) {
  final l = context.l10n;
  return AppBottomSheet.showExpanded<void>(
    context,
    initialSize: 0.7,
    title: l.templates_title,
    subtitle: l.templates_subtitle,
    builder: (ctx, controller) => _TemplatesList(conversationId: conversationId, controller: controller),
  );
}

class _TemplatesList extends ConsumerWidget {
  const _TemplatesList({required this.conversationId, required this.controller});

  final String conversationId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final async = ref.watch(_sheetTemplatesProvider);
    final conv = ref.watch(conversationProvider(conversationId));
    String fill(MessageTemplate tp) => tp.body
        .replaceAll('{{1}}', conv?.customer.name.split(' ').first ?? '')
        .replaceAll('{{2}}', conv?.orderRef ?? '');

    // Skeleton until the list arrives; "no templates" only after a real answer.
    final templates = async.valueOrNull;
    if (templates == null) {
      if (async.hasError) {
        return EmptyState(
          icon: AppIcons.offline,
          title: l.chatscreen_load_failed,
          actionLabel: l.common_retry,
          onAction: () => ref.invalidate(_sheetTemplatesProvider),
        );
      }
      return ListView(controller: controller, children: [AppSkeleton.list(rows: 4)]);
    }
    if (templates.isEmpty) {
      return EmptyState(icon: AppIcons.templates, title: l.templates_empty);
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final tp = templates[i];
        return Semantics(
          button: true,
          label: '${tp.category}، ${tp.name}، ${fill(tp)}',
          excludeSemantics: true,
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(messagesRepositoryProvider).send(
                  conversationId,
                  OutgoingMessage(text: fill(tp), kind: MessageKind.template, templateName: tp.name, sentVia: 'template'),
                );
                Navigator.of(context).pop();
                AppSnackbar.show(context, message: l.templates_sent, kind: SnackKind.success);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(AppIcons.templates, size: AppIconSize.sm, color: c.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(tp.category, style: t.caption.copyWith(color: c.textSecondary)),
                        ),
                        Text(
                          tp.name,
                          textDirection: TextDirection.ltr,
                          style: t.mono.copyWith(fontSize: 11, color: c.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(fill(tp), style: t.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
