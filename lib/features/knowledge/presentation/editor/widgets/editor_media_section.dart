import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/kb_answer_editor_controller.dart';
import '../../../application/kb_media_controller.dart';
import '../../../data/kb_api.dart';
import '../../../domain/kb_entry.dart';
import '../../kb_file_picker.dart';
import '../../kb_media_view.dart';

/// "المرفقات": images / voice notes the AI sends with this answer — same as
/// the web form (16 MB, images ≤ 5 MB, send mode per file).
class EditorMediaSection extends ConsumerWidget {
  const EditorMediaSection({super.key, required this.args, required this.enabled, required this.canUpload});

  final KbeArgs args;
  final bool enabled;

  /// `permissions.can_upload_media` (plan + role).
  final bool canUpload;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final kind = await AppBottomSheet.show<KbMediaKind>(
      context,
      title: l.kbe_media_add,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetActionRow(icon: AppIcons.image, label: l.kbe_media_image, onTap: () => Navigator.of(ctx).pop(KbMediaKind.image)),
            SheetActionRow(icon: AppIcons.voice, label: l.kbe_media_voice, onTap: () => Navigator.of(ctx).pop(KbMediaKind.voice)),
          ],
        ),
      ),
    );
    if (kind == null) return;
    final KbPickedFile? file = kind == KbMediaKind.image ? await pickKbImage() : await pickKbAudio();
    if (file == null || !context.mounted) return;
    final rejected = ref.read(kbMediaControllerProvider(args).notifier).add(file);
    final msg = switch (rejected) {
      KbMediaRejection.type => l.kbe_media_type_err,
      KbMediaRejection.tooBig => l.kbe_media_too_big,
      KbMediaRejection.imageTooBig => l.kbe_media_image_too_big,
      null => null,
    };
    if (msg != null) AppSnackbar.show(context, message: msg, kind: SnackKind.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(kbMediaControllerProvider(args));
    // No permission and nothing attached: nothing to show.
    if (!canUpload && !s.planBlocked && s.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: Text(l.kbe_media, style: t.inputLabel)),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(l.kbe_media_hint, style: t.caption.copyWith(color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in s.items) ...[
            _MediaRow(args: args, item: item, enabled: enabled),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (s.planBlocked)
            _UpgradeHint(onPlans: () => context.push(Routes.subscription))
          else if (canUpload)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: l.kbe_media_add,
                icon: AppIcons.attach,
                variant: AppButtonVariant.tonal,
                size: AppButtonSize.small,
                onPressed: enabled ? () => _add(context, ref) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaRow extends ConsumerWidget {
  const _MediaRow({required this.args, required this.item, required this.enabled});

  final KbeArgs args;
  final KbMediaItem item;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ctrl = ref.read(kbMediaControllerProvider(args).notifier);

    final String status;
    Color statusColor = c.textSecondary;
    if (item.uploading) {
      status = l.kbe_media_uploading(((item.progress ?? 0) * 100).round());
    } else if (item.failed) {
      status = item.error ?? l.kbe_media_failed;
      statusColor = c.textError;
    } else if (item.queued) {
      status = l.kbe_media_queued;
    } else {
      status = kbMediaMeta(l, item.media!);
    }

    Future<void> setMode(KbMediaSendMode m) async {
      try {
        await ctrl.setSendMode(item.key, m);
      } catch (_) {
        if (context.mounted) AppSnackbar.show(context, message: l.kbe_save_err, kind: SnackKind.error);
      }
    }

    Future<void> remove() async {
      try {
        await ctrl.remove(item.key);
      } catch (_) {
        if (context.mounted) AppSnackbar.show(context, message: l.kbe_save_err, kind: SnackKind.error);
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: item.failed ? c.error : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KbMediaThumb(kind: item.kind, media: item.media, localBytes: item.file?.bytes, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: t.listTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Semantics(liveRegion: item.uploading, child: Text(status, style: t.bodySmall.copyWith(color: statusColor))),
                  ],
                ),
              ),
              if (item.failed && item.file != null)
                AppIconButton(icon: AppIcons.regenerate, semanticLabel: l.kbe_retry, onPressed: enabled ? () => ctrl.retry(item.key) : null),
              AppIconButton(
                icon: AppIcons.close,
                semanticLabel: l.kbe_media_remove,
                onPressed: enabled && !item.uploading ? remove : null,
              ),
            ],
          ),
          if (item.uploading) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(value: item.progress, minHeight: 4, color: c.primary, backgroundColor: c.surfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Send mode (web `send_mode`): with the text, or the file alone.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in KbMediaSendMode.values)
                AppFilterChip(
                  label: m == KbMediaSendMode.withText ? l.kbe_media_with_text : l.kbe_media_file_only,
                  selected: item.sendMode == m,
                  onTap: enabled && !item.uploading ? () => setMode(m) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.onPlans});

  final VoidCallback onPlans;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l.kbe_media_upgrade, style: t.bodySmall.copyWith(color: c.onPrimaryContainer))),
          AppButton(label: l.kbe_media_upgrade_cta, size: AppButtonSize.small, variant: AppButtonVariant.secondary, onPressed: onPlans),
        ],
      ),
    );
  }
}
