import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/kb_upload_controller.dart';
import '../../data/kb_api.dart';
import '../../domain/kb_entry.dart';
import '../kb_file_picker.dart';
import '../widgets/kb_entry_tile.dart';

/// "1.2 ميجابايت" / "340 كيلوبايت".
String kbFileSize(AppLocalizations l, int bytes) {
  if (bytes >= 1024 * 1024) return l.kb_mb((bytes / (1024 * 1024)).toStringAsFixed(1));
  return l.kb_kb((bytes / 1024).ceil().toString());
}

/// System picker for a document (pdf, docx, txt, md).
Future<KbPickedFile?> pickKbFile(BuildContext context) => pickKbDocument();

/// Pick → validate → background upload + progress sheet (spec §6.2). The
/// AI reads the document on the server and drafts answers; the sheet ends
/// on "Review answers", which opens [Routes.knowledgeFileReview].
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
  final next = await AppBottomSheet.show<_SheetExit>(
    context,
    title: l.kb_add_document,
    builder: (_) => KbFileUploadSheet(jobKey: key),
  );
  if (!context.mounted) return;
  switch (next) {
    case _SheetExit(review: final String id):
      context.push(Routes.knowledgeFileReview(id));
    case _SheetExit(another: true):
      await startKbFileUpload(context, ref, snackOffset: snackOffset);
    default:
  }
}

/// What the user chose when the sheet closed.
class _SheetExit {
  const _SheetExit({this.review, this.another = false});

  final String? review;
  final bool another;
}

class KbFileUploadSheet extends ConsumerStatefulWidget {
  const KbFileUploadSheet({super.key, required this.jobKey});

  final String jobKey;

  @override
  ConsumerState<KbFileUploadSheet> createState() => _KbFileUploadSheetState();
}

class _KbFileUploadSheetState extends ConsumerState<KbFileUploadSheet> {
  /// Reading → preparing: the server reports one "processing" phase; the
  /// second step lights up after a few seconds so progress feels alive.
  static const _readingFor = Duration(seconds: 6);
  Timer? _stepTimer;
  bool _preparing = false;

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _close([_SheetExit? exit]) {
    final job = ref.read(kbUploadControllerProvider).jobs[widget.jobKey];
    if (job != null && (job.phase == KbUploadPhase.failed || job.phase == KbUploadPhase.ready)) {
      ref.read(kbUploadControllerProvider.notifier).forget(widget.jobKey);
    }
    Navigator.of(context).pop(exit);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final job = ref.watch(kbUploadControllerProvider.select((s) => s.jobs[widget.jobKey]));
    if (job == null) return const SizedBox.shrink();
    if (job.phase == KbUploadPhase.processing && _stepTimer == null) {
      _stepTimer = Timer(_readingFor, () {
        if (mounted) setState(() => _preparing = true);
      });
    }
    final v = KbTypeVisual.of(context, KbType.file);

    final header = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: v.background, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: AppIcon(v.icon, color: v.foreground),
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
    );

    final Widget body = switch (job.phase) {
      KbUploadPhase.uploading || KbUploadPhase.processing => _Progress(job: job, preparing: _preparing, onHide: _close),
      KbUploadPhase.ready => _Ready(
          job: job,
          onReview: job.entryId == null ? null : () => _close(_SheetExit(review: job.entryId)),
          onDone: _close,
        ),
      KbUploadPhase.failed => _Failed(job: job, onAnother: () => _close(const _SheetExit(another: true)), onClose: _close),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.normal,
            child: KeyedSubtree(key: ValueKey(job.phase), child: body),
          ),
        ],
      ),
    );
  }
}

/// Three steps: upload (with %), read the document, prepare answers.
class _Progress extends StatelessWidget {
  const _Progress({required this.job, required this.preparing, required this.onHide});

  final KbUploadJob job;
  final bool preparing;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final uploading = job.phase == KbUploadPhase.uploading;
    final pct = (job.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: uploading ? l.kb_uploading(pct) : (preparing ? l.kb_step_prepare : l.kb_step_read),
          child: Column(
            children: [
              _Step(label: uploading ? l.kb_uploading(pct) : l.kb_step_upload, state: uploading ? _S.active : _S.done),
              _Step(label: l.kb_step_read, state: uploading ? _S.waiting : (preparing ? _S.done : _S.active)),
              _Step(label: l.kb_step_prepare, state: uploading || !preparing ? _S.waiting : _S.active, last: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: uploading
              ? LinearProgressIndicator(value: job.progress, minHeight: 4, color: c.primary, backgroundColor: c.surfaceVariant)
              : LinearProgressIndicator(minHeight: 4, color: c.primary, backgroundColor: c.surfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l.kb_processing_hint, style: t.caption.copyWith(color: c.textTertiary)),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: l.kb_hide, variant: AppButtonVariant.secondary, expand: true, onPressed: onHide),
      ],
    );
  }
}

enum _S { waiting, active, done }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.state, this.last = false});

  final String label;
  final _S state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Widget mark = switch (state) {
      _S.done => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          child: const AppIcon(AppIcons.check, dp: 14, color: Colors.white),
        ),
      _S.active => SizedBox.square(dimension: 22, child: AppSpinner(size: 18, delayed: false, color: c.primary)),
      _S.waiting => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderStrong, width: 2)),
        ),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        children: [
          mark,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: t.bodyMedium.copyWith(
                color: state == _S.waiting ? c.textTertiary : c.textPrimary,
                fontWeight: state == _S.active ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "We found N answers" → Review (admins) or "sent for review" (others).
class _Ready extends StatelessWidget {
  const _Ready({required this.job, required this.onReview, required this.onDone});

  final KbUploadJob job;
  final VoidCallback? onReview;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final canApprove = job.result?.canApprove ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Outcome(
          icon: AppIcons.success,
          color: c.success,
          background: c.successContainer,
          title: l.kb_found_answers(job.facts),
          body: canApprove ? l.kb_found_review_hint : l.kb_found_admin_hint,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (canApprove) ...[
          AppButton(label: l.kb_review_answers, icon: AppIcons.check, expand: true, size: AppButtonSize.large, onPressed: onReview),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: l.kb_later, variant: AppButtonVariant.text, expand: true, onPressed: onDone),
        ] else
          AppButton(label: l.common_done, expand: true, size: AppButtonSize.large, onPressed: onDone),
      ],
    );
  }
}

/// A clear reason and the way out.
class _Failed extends StatelessWidget {
  const _Failed({required this.job, required this.onAnother, required this.onClose});

  final KbUploadJob job;
  final VoidCallback onAnother;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final err = job.error;
    final (String title, String body) = switch ((job.result?.error, err)) {
      (KbFileError.encrypted, _) => (l.kb_fail_encrypted, l.kb_fail_encrypted_hint),
      (KbFileError.imagesOnly, _) => (l.kb_fail_images, l.kb_fail_images_hint),
      (KbFileError.corrupt, _) => (l.kb_fail_corrupt, l.kb_fail_corrupt_hint),
      (KbFileError.noAnswers, _) => (l.kb_fail_no_answers, l.kb_fail_no_answers_hint),
      (KbFileError.aiUnavailable, _) => (l.kb_fail_ai, l.kb_fail_ai_hint),
      (_, KbApiException(isNotSupported: true)) => (l.kb_file_failed, l.kb_web_only),
      (_, KbApiException(isPlanLimit: true)) => (l.kb_fail_quota, l.kb_fail_quota_hint),
      (_, KbApiException(status: 413)) => (l.kb_file_size_err, l.kb_fail_corrupt_hint),
      (_, KbApiException(status: 415)) => (l.kb_file_type_err, l.kb_fail_corrupt_hint),
      (_, KbApiException(isNetwork: true)) => (l.kb_fail_network, l.kb_fail_network_hint),
      _ => (l.kb_file_failed, l.kb_fail_ai_hint),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Outcome(icon: AppIcons.failed, color: c.error, background: c.errorContainer, title: title, body: body),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: l.kb_try_another, icon: AppIcons.upload, expand: true, size: AppButtonSize.large, onPressed: onAnother),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: l.common_close, variant: AppButtonVariant.text, expand: true, onPressed: onClose),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.icon, required this.color, required this.background, required this.title, required this.body});

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: AppIcon(icon, size: AppIconSize.lg, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: t.h4.copyWith(color: c.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
