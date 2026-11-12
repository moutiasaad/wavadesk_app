import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../account/channels_screen.dart' show webPanelPage;
import '../../application/close_titles_controller.dart';
import '../../data/close_titles_api.dart';
import '../../data/whatsapp_api.dart' show WaApiException;

/// `/settings/whatsapp/close-titles` — the web panel's "Closing titles" page:
/// the titles agents pick from when they close a conversation.
class CloseTitlesScreen extends ConsumerStatefulWidget {
  const CloseTitlesScreen({super.key});

  @override
  ConsumerState<CloseTitlesScreen> createState() => _CloseTitlesScreenState();
}

class _CloseTitlesScreenState extends ConsumerState<CloseTitlesScreen> {
  final _new = TextEditingController();
  String _q = '';
  bool _adding = false;
  bool _restoring = false;
  String? _addError;

  CloseTitlesController get _ctrl => ref.read(closeTitlesControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // The provider outlives the screen: show the kept rows, refresh quietly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(closeTitlesControllerProvider).loaded) _ctrl.load();
    });
  }

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  String _errorText(Object e) {
    final l = context.l10n;
    if (e is WaApiException) {
      if (e.isNetwork) return l.wa_offline;
      switch (e.code) {
        case 'duplicate_title':
          return l.wa_ct_error_duplicate;
        case 'limit_reached':
          return l.wa_ct_error_limit('${e.details['max'] ?? ref.read(closeTitlesControllerProvider).max}');
        case 'validation_failed':
          return l.wa_ct_error_empty;
      }
      if (e.message != null && e.message!.isNotEmpty) return e.message!;
    }
    return l.wa_ct_save_error;
  }

  Future<void> _add() async {
    final l = context.l10n;
    final title = _new.text.trim();
    if (title.isEmpty) {
      setState(() => _addError = l.wa_ct_error_empty);
      return;
    }
    setState(() {
      _adding = true;
      _addError = null;
    });
    try {
      await _ctrl.add(title);
      if (!mounted) return;
      _new.clear();
      AppSnackbar.show(context, message: l.wa_ct_added, kind: SnackKind.success);
    } catch (e) {
      if (mounted) setState(() => _addError = _errorText(e));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _rename(CloseTitleItem t) async {
    final l = context.l10n;
    final saved = await AppBottomSheet.show<bool>(
      context,
      title: l.wa_ct_edit,
      builder: (_) => _RenameSheet(item: t, errorText: _errorText),
    );
    if (saved == true && mounted) AppSnackbar.show(context, message: l.wa_ct_saved, kind: SnackKind.success);
  }

  Future<void> _delete(CloseTitleItem t) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.wa_ct_delete_title,
      body: '${l.wa_ct_delete_body}\n«${t.title}»',
      confirmLabel: l.wa_ct_delete,
      cancelLabel: l.wa_ct_cancel,
      icon: AppIcons.delete,
    );
    if (!ok || !mounted) return;
    final done = await _ctrl.delete(t.id);
    if (!mounted) return;
    AppSnackbar.show(context, message: done ? l.wa_ct_deleted : l.wa_ct_save_error, kind: done ? SnackKind.success : SnackKind.error);
  }

  Future<void> _restore() async {
    final l = context.l10n;
    setState(() => _restoring = true);
    try {
      await _ctrl.restoreDefaults();
      if (mounted) AppSnackbar.show(context, message: l.wa_ct_restore_done, kind: SnackKind.success);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, message: _errorText(e), kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _openWeb() async {
    try {
      await launchUrl(webPanelPage(ref.read(currentAgentProvider).role, 'close-titles'), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser: nothing to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final state = ref.watch(closeTitlesControllerProvider);
    final bottom = AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom;

    Widget body;
    if (state.unavailable) {
      body = ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, bottom),
        children: [
          EmptyState(
            icon: AppIcons.info,
            title: l.wa_ct_unavailable_title,
            body: l.wa_ct_unavailable_body,
            actionLabel: l.wa_ct_open_web,
            onAction: _openWeb,
          ),
        ],
      );
    } else if (state.loading && !state.loaded) {
      body = AppSkeleton.list(rows: 6);
    } else if (state.error != null && !state.loaded) {
      body = EmptyState(icon: AppIcons.error, title: l.wa_ct_load_error, actionLabel: l.wa_retry, onAction: _ctrl.load);
    } else {
      final term = _q.trim().toLowerCase();
      final rows = term.isEmpty ? state.items : [for (final x in state.items) if (x.title.toLowerCase().contains(term)) x];
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: _ctrl.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottom),
          children: [
            Text(l.wa_ct_subtitle, style: t.bodySmall.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: l.wa_ct_add_label,
                    hint: l.wa_ct_add_placeholder,
                    controller: _new,
                    error: _addError,
                    maxLength: 180,
                    enabled: !_adding,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_addError != null) setState(() => _addError = null);
                    },
                    onSubmitted: (_) => _add(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(label: l.wa_ct_add_btn, icon: AppIcons.add, expand: true, loading: _adding, onPressed: _adding ? null : _add),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.items.length > 8) ...[
              AppSearchField(hint: l.wa_ct_search, showCancel: false, onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(l.wa_ct_list_title, style: t.h6.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(l.wa_ct_list_desc, style: t.caption.copyWith(color: c.textTertiary)),
            const SizedBox(height: AppSpacing.sm),
            if (rows.isEmpty)
              EmptyState(
                icon: AppIcons.resolve,
                title: term.isEmpty ? l.wa_ct_empty_title : l.wa_ct_no_matches,
                body: term.isEmpty ? l.wa_ct_empty_hint : null,
              )
            else
              _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) Divider(height: 1, thickness: 1, color: c.divider, indent: 14, endIndent: 14),
                      _TitleRow(item: rows[i], onEdit: () => _rename(rows[i]), onDelete: () => _delete(rows[i])),
                    ],
                  ],
                ),
              ),
            if (state.canManage && state.missingDefaults > 0) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l.wa_ct_restore_defaults,
                icon: AppIcons.refresh,
                variant: AppButtonVariant.secondary,
                expand: true,
                loading: _restoring,
                onPressed: _restoring ? null : _restore,
              ),
            ],
            if (!state.canManage) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l.wa_ct_readonly_hint, style: t.caption.copyWith(color: c.textTertiary)),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: l.wa_ct_title, background: c.backgroundMuted),
      body: body,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.item, required this.onEdit, required this.onDelete});

  final CloseTitleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: t.listTitle.copyWith(fontSize: 14.5)),
                const SizedBox(height: 4),
                if (item.isDefault)
                  StatusBadge(label: l.wa_ct_default_badge, foreground: c.textSecondary, background: c.surfaceVariant, compact: true)
                else if (item.creator != null && item.creator!.isNotEmpty)
                  Text(l.wa_ct_added_by(item.creator!), style: t.caption.copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          if (item.canEdit) ...[
            AppIconButton(icon: AppIcons.edit, size: 36, semanticLabel: l.wa_ct_edit, onPressed: onEdit),
            AppIconButton(icon: AppIcons.delete, size: 36, iconColor: c.error, semanticLabel: l.wa_ct_delete, onPressed: onDelete),
          ],
        ],
      ),
    );
  }
}

/// Rename sheet: text field + حفظ / إلغاء. Pops true once saved.
class _RenameSheet extends ConsumerStatefulWidget {
  const _RenameSheet({required this.item, required this.errorText});

  final CloseTitleItem item;
  final String Function(Object) errorText;

  @override
  ConsumerState<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends ConsumerState<_RenameSheet> {
  late final _text = TextEditingController(text: widget.item.title);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final title = _text.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l.wa_ct_error_empty);
      return;
    }
    if (title == widget.item.title) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(closeTitlesControllerProvider.notifier).rename(widget.item.id, title);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = widget.errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _text,
            error: _error,
            maxLength: 180,
            autofocus: true,
            enabled: !_saving,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: l.wa_ct_save, expand: true, loading: _saving, onPressed: _saving ? null : _save),
          const SizedBox(height: AppSpacing.xs),
          AppButton(label: l.wa_ct_cancel, variant: AppButtonVariant.text, expand: true, onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}
