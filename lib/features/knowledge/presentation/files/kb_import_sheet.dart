import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../data/kb_api.dart';
import '../../domain/kb_entry.dart';
import '../kb_file_picker.dart';

/// "رفع ملف" = the web panel's JSON import: pick a `.json` file with an
/// `entries` list → `POST kb/import` → imported / skipped / row errors.
Future<void> startKbJsonImport(BuildContext context, WidgetRef ref) =>
    AppBottomSheet.show<void>(context, title: context.l10n.kb_import_title, builder: (_) => const KbImportSheet());

class KbImportSheet extends ConsumerStatefulWidget {
  const KbImportSheet({super.key});

  @override
  ConsumerState<KbImportSheet> createState() => _KbImportSheetState();
}

class _KbImportSheetState extends ConsumerState<KbImportSheet> {
  bool _busy = false;
  bool _savingTemplate = false;
  String? _fileName;
  String? _error;
  KbImportResult? _result;

  Future<void> _pickAndImport() async {
    final l = context.l10n;
    final file = await pickKbJson();
    if (file == null || !mounted) return;
    if (!file.name.toLowerCase().endsWith('.json')) {
      setState(() => _error = l.kb_import_json_only);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _fileName = file.name;
    });
    try {
      final r = await ref.read(kbApiProvider).importJson(file);
      if (!mounted) return;
      Analytics.log('kb_import', {'imported': r.imported, 'skipped': r.skipped});
      setState(() => _result = r);
      if (r.imported > 0) unawaited(ref.read(knowledgeControllerProvider.notifier).refresh());
    } on KbApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.isNotSupported ? l.kb_web_only : ((e.message?.isNotEmpty ?? false) && e.status == 422 ? e.message : l.kb_import_failed));
    } catch (_) {
      if (mounted) setState(() => _error = l.kb_import_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Saves the template through the system "save as" dialog; falls back to
  /// the clipboard where saving isn't available.
  Future<void> _template() async {
    final l = context.l10n;
    setState(() => _savingTemplate = true);
    try {
      final text = await ref.read(kbApiProvider).importTemplate();
      String? path;
      try {
        path = await FilePicker.saveFile(
          fileName: 'knowledge-template.json',
          type: FileType.custom,
          allowedExtensions: const ['json'],
          bytes: Uint8List.fromList(utf8.encode(text)),
        );
      } catch (e) {
        debugPrint('Template save failed: $e');
      }
      if (!mounted) return;
      if (path != null) {
        AppSnackbar.show(context, message: l.kb_template_saved, kind: SnackKind.success);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) AppSnackbar.show(context, message: l.kb_template_copied);
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.kb_import_failed, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final r = _result;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.kb_import_hint, style: t.bodySmall.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          if (_fileName != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.file, dp: 18, color: c.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_fileName!, style: t.listTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (_busy) SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
                ],
              ),
            ),
          if (_busy) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(liveRegion: true, child: Text(l.kb_importing, style: t.bodySmall.copyWith(color: c.textSecondary))),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(liveRegion: true, child: Text(_error!, style: t.bodySmall.copyWith(color: c.textError))),
          ],
          if (r != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  AppIcon(r.imported > 0 ? AppIcons.check : AppIcons.error, dp: 18, color: r.imported > 0 ? c.textSuccess : c.textWarning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      [l.kb_import_done(r.imported), if (r.skipped > 0) l.kb_import_skipped(r.skipped)].join(' · '),
                      style: t.listTitle,
                    ),
                  ),
                ],
              ),
            ),
            if (r.errors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in r.errors)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(l.kb_import_row_err(e.row, e.message), style: t.bodySmall.copyWith(color: c.textError)),
                      ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.kb_import_pick,
            icon: AppIcons.file,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _pickAndImport,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.kb_import_template,
            variant: AppButtonVariant.secondary,
            expand: true,
            loading: _savingTemplate,
            onPressed: _savingTemplate ? null : _template,
          ),
        ],
      ),
    );
  }
}
