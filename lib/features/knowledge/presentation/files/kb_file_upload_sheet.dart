import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/kb_upload_controller.dart';
import '../../data/kb_api.dart';
import '../widgets/kb_entry_tile.dart';
import '../../domain/kb_entry.dart';

/// "1.2 ميجابايت" / "340 كيلوبايت".
String kbFileSize(AppLocalizations l, int bytes) {
  if (bytes >= 1024 * 1024) return l.kb_mb((bytes / (1024 * 1024)).toStringAsFixed(1));
  return l.kb_kb((bytes / 1024).ceil().toString());
}

/// No file-picker plugin in the app yet (same as chat attachments): a
/// stand-in picker with demo files, incl. ones that hit each validation /
/// processing error. Swap for `file_picker` (pdf, docx, txt, md).
Future<KbPickedFile?> pickKbFile(BuildContext context) {
  const demo = [
    KbPickedFile(name: 'دليل المنتجات 2026.pdf', sizeBytes: 2400000, mime: 'application/pdf'),
    KbPickedFile(name: 'سياسة الشحن.docx', sizeBytes: 340000, mime: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
    KbPickedFile(name: 'ساعات العمل.txt', sizeBytes: 4200, mime: 'text/plain'),
    KbPickedFile(name: 'عرض أسعار.xlsx', sizeBytes: 90000, mime: 'application/vnd.ms-excel'),
    KbPickedFile(name: 'كتالوج كامل.pdf', sizeBytes: 14 * 1024 * 1024, mime: 'application/pdf'),
    KbPickedFile(name: 'ملف تالف.pdf', sizeBytes: 800000, mime: 'application/pdf'),
  ];
  final l = context.l10n;
  return AppBottomSheet.show<KbPickedFile>(
    context,
    title: l.kb_add_file,
    subtitle: l.kb_add_file_sub,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in demo) SheetActionRow(icon: AppIcons.file, label: '${f.name} · ${kbFileSize(l, f.sizeBytes)}', onTap: () => Navigator.of(ctx).pop(f)),
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
}

/// Pick → validate → background upload + progress sheet (spec §6.2).
Future<void> startKbFileUpload(BuildContext context, WidgetRef ref, {String? replaceId, double snackOffset = 0}) async {
  final l = context.l10n;
  final file = await pickKbFile(context);
  if (file == null || !context.mounted) return;
  switch (KbUploadController.validate(file)) {
    case KbFileRejection.type:
      AppSnackbar.show(context, message: l.kb_file_type_err, kind: SnackKind.error, bottomOffset: snackOffset);
      return;
    case KbFileRejection.size:
      AppSnackbar.show(context, message: l.kb_file_size_err, kind: SnackKind.error, bottomOffset: snackOffset);
      return;
    case null:
  }
  final key = ref.read(kbUploadControllerProvider.notifier).start(file, replaceId: replaceId);
  await AppBottomSheet.show<void>(context, title: l.kb_add_file, builder: (_) => KbFileUploadSheet(jobKey: key));
}

class KbFileUploadSheet extends ConsumerWidget {
  const KbFileUploadSheet({super.key, required this.jobKey});

  final String jobKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final job = ref.watch(kbUploadControllerProvider.select((s) => s.jobs[jobKey]));
    if (job == null) return const SizedBox.shrink();
    final v = KbTypeVisual.of(context, KbType.file);
    final reduced = AppMotion.reduced(context);
    final pct = (job.progress * 100).round();
    final err = job.error;
    final notSupported = err is KbApiException && err.isNotSupported;

    final String status;
    Color statusColor = c.textSecondary;
    switch (job.phase) {
      case KbUploadPhase.uploading:
        status = l.kb_uploading(pct);
      case KbUploadPhase.processing:
        status = l.kb_processing_long;
      case KbUploadPhase.ready:
        status = l.kb_file_ready(job.file.name, job.facts);
        statusColor = c.textSuccess;
      case KbUploadPhase.failed:
        status = notSupported ? l.kb_web_only : (err == null ? l.kb_file_failed : l.kb_save_err);
        statusColor = c.textError;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: v.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(v.icon, size: 22, color: v.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.file.name, style: t.listTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(kbFileSize(l, job.file.sizeBytes), style: t.bodySmall.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Announced at 25 / 50 / 75 / 100 % (spec §10).
          Semantics(
            liveRegion: true,
            value: job.phase == KbUploadPhase.uploading ? '${(pct ~/ 25) * 25}%' : status,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: job.phase == KbUploadPhase.processing && !reduced
                  ? LinearProgressIndicator(minHeight: 6, color: c.primary, backgroundColor: c.surfaceVariant)
                  : TweenAnimationBuilder<double>(
                      tween: Tween(end: job.phase == KbUploadPhase.uploading ? job.progress : 1),
                      duration: reduced ? Duration.zero : const Duration(milliseconds: 100),
                      builder: (_, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: job.phase == KbUploadPhase.failed ? c.error : (job.phase == KbUploadPhase.ready ? c.success : c.primary),
                        backgroundColor: c.surfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(status, style: t.bodySmall.copyWith(color: statusColor)),
          if (job.phase == KbUploadPhase.processing) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l.kb_processing_bg, style: t.caption.copyWith(color: c.textTertiary)),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.common_close,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () {
              if (job.phase == KbUploadPhase.failed || job.phase == KbUploadPhase.ready) {
                ref.read(kbUploadControllerProvider.notifier).forget(jobKey);
              }
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }
}
