import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/state/load_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/kb_upload_controller.dart';
import '../../application/knowledge_controller.dart';
import '../../data/kb_api.dart';
import '../../domain/kb_entry.dart';
import '../widgets/kb_entry_tile.dart';
import 'kb_file_upload_sheet.dart';

/// File detail `/knowledge/files/:id` (Knowledge Base spec §6.2).
class KbFileDetailScreen extends ConsumerStatefulWidget {
  const KbFileDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<KbFileDetailScreen> createState() => _KbFileDetailScreenState();
}

class _KbFileDetailScreenState extends ConsumerState<KbFileDetailScreen> {
  late KbFile? _file = MemoryCache.get<KbFile>('kb_file:${widget.id}');
  Object? _error;
  Timer? _poll;
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _poll?.cancel();
    try {
      final f = await ref.read(kbApiProvider).file(widget.id);
      MemoryCache.put('kb_file:${widget.id}', f);
      if (!mounted) return;
      setState(() {
        _file = f;
        _error = null;
      });
      if (f.status == KbStatus.processing) _poll = Timer(const Duration(seconds: 3), _load);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _setEnabled(bool v) async {
    final f = _file;
    if (f == null) return;
    try {
      await ref.read(kbApiProvider).setEnabled(f.id, v);
      Analytics.log('kb_toggle_enabled', {'type': 'file'});
      ref.read(knowledgeControllerProvider.notifier).refresh();
      _load();
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: context.l10n.kb_save_err, kind: SnackKind.error);
    }
  }

  Future<void> _replace() async {
    await startKbFileUpload(context, ref, replaceId: widget.id);
    if (mounted) _load();
  }

  Future<void> _download() async {
    final url = _file?.downloadUrl;
    if (url == null) {
      AppSnackbar.show(context, message: context.l10n.kb_web_only);
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _delete() async {
    final f = _file;
    if (f == null) return;
    final l = context.l10n;
    final ok = await AppDialog.confirm(context, title: l.kb_delete_title(f.name), body: l.kb_delete_body, confirmLabel: l.kb_delete, icon: AppIcons.delete);
    if (!ok || !mounted) return;
    try {
      await ref.read(kbApiProvider).delete(f.id);
      Analytics.log('kb_delete', {'type': 'file'});
      ref.read(knowledgeControllerProvider.notifier).removeLocal(f.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.kb_save_err, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final perms = ref.watch(knowledgeControllerProvider.select((s) => s.permissions));
    // A replacement finished → reload.
    ref.listen(kbUploadControllerProvider.select((s) => s.readyTick), (_, _) => _load());
    final f = _file;

    Widget body;
    if (f == null && _error != null) {
      final e = _error;
      final ns = e is KbApiException && e.isNotSupported;
      body = EmptyState(
        icon: ns ? AppIcons.globe : AppIcons.alert,
        title: ns ? l.kb_web_only : l.kb_error,
        actionLabel: ns ? null : l.kb_retry,
        onAction: ns ? null : _load,
      );
    } else if (f == null) {
      body = const Center(child: AppSpinner());
    } else {
      final v = KbTypeVisual.of(context, KbType.file);
      body = ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          _box(
            context,
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: v.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(v.icon, size: 24, color: v.foreground),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: t.listTitle),
                      Text(
                        [kbFileSize(l, f.sizeBytes), if (f.pages > 0) l.kb_pages(f.pages)].join(' · '),
                        style: t.bodySmall.copyWith(color: c.textSecondary),
                      ),
                      if (f.uploadedBy != null && f.uploadedAt != null)
                        Text(l.kb_uploaded_by(f.uploadedBy!.name, AppFormat.date(context, f.uploadedAt!)), style: t.caption.copyWith(color: c.textTertiary)),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(duration: AppMotion.normal, child: KeyedSubtree(key: ValueKey(f.status), child: _statusBadge(context, f))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (f.status == KbStatus.failed) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.errorContainer, borderRadius: BorderRadius.circular(AppRadius.xl)),
              child: Row(
                children: [
                  Icon(AppIcons.alertTriangle, size: 18, color: c.textError),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.kb_file_failed, style: t.listTitle.copyWith(fontSize: 14, color: c.textError)),
                        Text(switch (f.error) {
                          KbFileError.encrypted => l.kb_fail_encrypted,
                          KbFileError.imagesOnly => l.kb_fail_images,
                          _ => l.kb_fail_corrupt,
                        }, style: t.bodySmall),
                      ],
                    ),
                  ),
                  if (perms.canEdit) AppButton(label: l.kb_retry, size: AppButtonSize.small, variant: AppButtonVariant.secondary, onPressed: _replace),
                ],
              ),
            ),
          ],
          if (f.chunks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, AppSpacing.lg, 6, 6),
              child: Text(l.kb_extracted, style: t.caption.copyWith(color: c.textSecondary)),
            ),
            _box(
              context,
              Column(
                children: [
                  for (var i = 0; i < f.chunks.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.divider),
                    _chunk(context, f.chunks[i]),
                  ],
                ],
              ),
              padding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _box(
            context,
            Column(
              children: [
                SettingsTile(
                  title: l.kb_available_ai,
                  trailing: AppSwitch(value: f.enabled, semanticLabel: l.kb_available_ai, onChanged: perms.canEdit ? _setEnabled : null),
                ),
                if (perms.canEdit) ...[
                  Divider(height: 1, color: c.divider),
                  SettingsTile(icon: AppIcons.regenerate, title: l.kb_replace, onTap: _replace),
                ],
                Divider(height: 1, color: c.divider),
                SettingsTile(icon: AppIcons.download, title: l.kb_download, onTap: _download),
                if (perms.canDelete) ...[
                  Divider(height: 1, color: c.divider),
                  SettingsTile(
                    icon: AppIcons.delete,
                    iconColor: c.textError,
                    iconBackground: c.errorContainer,
                    title: l.kb_delete,
                    destructive: true,
                    showChevron: false,
                    onTap: _delete,
                  ),
                ],
              ],
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: f?.name ?? l.kb_files, background: c.backgroundMuted),
      body: SafeArea(top: false, child: body),
    );
  }

  Widget _statusBadge(BuildContext context, KbFile f) {
    final c = context.colors;
    final l = context.l10n;
    return switch (f.status) {
      KbStatus.processing => StatusBadge(
          label: l.kb_processing,
          foreground: c.textInfo,
          background: c.infoContainer,
          leading: AppSpinner(size: 11, color: c.textInfo, delayed: false),
        ),
      KbStatus.failed => StatusBadge(label: l.kb_badge_failed, foreground: c.textError, background: c.errorContainer),
      KbStatus.disabled => StatusBadge(label: l.kb_badge_disabled, foreground: c.textSecondary, background: c.surfaceVariant),
      _ => StatusBadge(label: l.kb_available_ai, foreground: c.textSuccess, background: c.successContainer),
    };
  }

  Widget _chunk(BuildContext context, KbChunk ch) {
    final c = context.colors;
    final t = context.text;
    final open = _expanded.contains(ch.id);
    return InkWell(
      onTap: () => setState(() => open ? _expanded.remove(ch.id) : _expanded.add(ch.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedSize(
                duration: AppMotion.fast,
                alignment: AlignmentDirectional.topStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ch.title, style: t.listTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      ch.preview,
                      style: t.bodySmall.copyWith(color: c.textSecondary),
                      maxLines: open ? null : 2,
                      overflow: open ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: AppMotion.fast,
              child: Icon(AppIcons.chevronDown, size: 16, color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(BuildContext context, Widget child, {EdgeInsets padding = const EdgeInsets.all(AppSpacing.lg)}) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
