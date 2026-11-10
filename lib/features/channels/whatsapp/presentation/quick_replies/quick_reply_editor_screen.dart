import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/quick_replies_controller.dart';
import '../../data/quick_replies_api.dart';
import '../../data/whatsapp_api.dart' show WaApiException;
import '../../domain/shortcut_validator.dart';
import '../editors/wa_welcome_editor_screen.dart' show WaEditorLabel, WaVariableChips, waConfirmDiscard;
import 'quick_replies_screen.dart' show canEditTeamReplies;

/// `/settings/whatsapp/quick-replies/:id` — `new` creates (WhatsApp spec
/// §5.4). No attachments: the server doesn't store them yet.
class QuickReplyEditorScreen extends ConsumerStatefulWidget {
  const QuickReplyEditorScreen({super.key, required this.id, this.scope});

  final String id;

  /// Scope for a new reply (the tab it was created from).
  final QuickReplyScope? scope;

  @override
  ConsumerState<QuickReplyEditorScreen> createState() => _QuickReplyEditorScreenState();
}

class _QuickReplyEditorScreenState extends ConsumerState<QuickReplyEditorScreen> {
  final _title = TextEditingController();
  final _shortcut = TextEditingController();
  final _text = TextEditingController();
  WaQuickReply? _initial;
  bool _shared = true;
  bool _saving = false;
  bool _touched = false;
  String? _serverShortcutError;

  bool get _isNew => widget.id == 'new';

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _shortcut, _text]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _shortcut.dispose();
    _text.dispose();
    super.dispose();
  }

  void _seed(WaQuickReply? r, bool canTeam) {
    if (_initial != null) return;
    _initial =
        r ??
        WaQuickReply(
          id: '',
          shortcut: '',
          title: '',
          text: '',
          scope: widget.scope == QuickReplyScope.team && canTeam ? QuickReplyScope.team : QuickReplyScope.mine,
        );
    _title.text = _initial!.title;
    _shortcut.text = _initial!.shortcut;
    _text.text = _initial!.text;
    _shared = _initial!.shared;
  }

  QuickReplyScope get _scope => _shared ? QuickReplyScope.team : QuickReplyScope.mine;

  bool get _dirty =>
      _title.text.trim() != _initial!.title ||
      ShortcutValidator.normalize(_shortcut.text) != _initial!.shortcut ||
      _text.text.trim() != _initial!.text ||
      _scope != _initial!.scope;

  String? _shortcutError(List<WaQuickReply> all) {
    if (_serverShortcutError != null) return _serverShortcutError;
    final l = context.l10n;
    final others = [
      for (final r in all)
        if (r.id != _initial!.id && r.scope == _scope) r.shortcut,
    ];
    return switch (ShortcutValidator.validate(_shortcut.text, existing: others)) {
      ShortcutError.empty => l.wa_qr_err_shortcut_empty,
      ShortcutError.invalid => l.wa_qr_err_shortcut_invalid,
      ShortcutError.tooLong => l.wa_qr_err_shortcut_long,
      ShortcutError.taken => l.wa_qr_err_shortcut_taken,
      null => null,
    };
  }

  Future<void> _save(List<WaQuickReply> all) async {
    final l = context.l10n;
    setState(() => _touched = true);
    if (_title.text.trim().isEmpty || _text.text.trim().isEmpty || _shortcutError(all) != null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(quickRepliesControllerProvider.notifier)
          .save(
            _initial!.copyWith(
              title: _title.text.trim(),
              shortcut: ShortcutValidator.normalize(_shortcut.text),
              text: _text.text.trim(),
              scope: _scope,
            ),
          );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      AppSnackbar.show(context, message: l.wa_qr_saved, kind: SnackKind.success);
      Navigator.of(context).pop();
    } on WaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.code == 'shortcut_taken' || e.details.containsKey('shortcut')) _serverShortcutError = l.wa_qr_err_shortcut_taken;
      });
      if (_serverShortcutError == null) {
        AppSnackbar.show(context, message: e.isNetwork ? l.wa_offline : l.wa_qr_save_failed, kind: SnackKind.error);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(context, message: l.wa_qr_save_failed, kind: SnackKind.error);
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final r = _initial!;
    final ok = await AppDialog.confirm(
      context,
      title: l.wa_qr_delete_title(r.title),
      body: l.wa_qr_delete_body,
      confirmLabel: l.wa_delete,
      icon: AppIcons.delete,
    );
    if (!ok || !mounted) return;
    final done = await ref.read(quickRepliesControllerProvider.notifier).delete(r.id);
    if (!mounted) return;
    AppSnackbar.show(context, message: done ? l.wa_qr_deleted : l.wa_qr_delete_failed, kind: done ? SnackKind.success : SnackKind.error);
    if (done) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final state = ref.watch(quickRepliesControllerProvider);
    final me = ref.watch(currentAgentProvider);
    final canTeam = canEditTeamReplies(me);
    final existing = _isNew ? null : state.items.where((r) => r.id == widget.id).firstOrNull;

    if (!_isNew && existing == null) {
      return Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(title: l.wa_qr_edit),
        // Not found only once the list has loaded; before that spinner / error.
        body: !state.loaded && state.error != null && !state.loading
            ? EmptyState(
                icon: AppIcons.offline,
                title: l.wa_load_error,
                actionLabel: l.wa_retry,
                onAction: ref.read(quickRepliesControllerProvider.notifier).load,
              )
            : !state.loaded
                ? const Center(child: AppSpinner())
                : EmptyState(icon: AppIcons.error, title: l.wa_qr_no_results),
      );
    }
    _seed(existing, canTeam);
    final r = _initial!;
    final editable = r.canEdit && (r.scope == QuickReplyScope.mine || canTeam);
    final dirty = _dirty;
    final titleErr = _touched && _title.text.trim().isEmpty ? l.wa_qr_err_title : null;
    final textErr = _touched && _text.text.trim().isEmpty ? l.wa_qr_err_text : null;
    final scErr = (_touched || _shortcut.text.isNotEmpty) ? _shortcutError(state.items) : null;

    return PopScope(
      canPop: !dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await waConfirmDiscard(context) && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(
          title: _isNew ? l.wa_qr_new : l.wa_qr_edit,
          background: c.backgroundMuted,
          actions: [
            if (editable)
              _saving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AppSpinner(size: 18, delayed: false),
                    )
                  : AppBarTextAction(label: l.wa_save, onPressed: dirty ? () => _save(state.items) : null),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              WaEditorLabel(l.wa_qr_title_f),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppTextField(controller: _title, enabled: editable, maxLength: 80, error: titleErr, autofocus: _isNew),
              ),
              WaEditorLabel(l.wa_qr_shortcut),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                // The `/` is enforced: shown outside the field, never typed.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 14, right: AppSpacing.sm),
                        child: Text('/', style: t.h4.copyWith(color: c.textTertiary)),
                      ),
                      Expanded(
                        child: AppTextField(
                          controller: _shortcut,
                          enabled: editable,
                          textDirection: TextDirection.ltr,
                          autocorrect: false,
                          enableSuggestions: false,
                          maxLength: ShortcutValidator.maxLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                            TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toLowerCase())),
                          ],
                          error: scErr,
                          onChanged: (_) {
                            if (_serverShortcutError != null) setState(() => _serverShortcutError = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              WaEditorLabel(l.wa_qr_text),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _text,
                      enabled: editable,
                      minLines: 4,
                      maxLines: 10,
                      maxLength: 1024,
                      keyboardType: TextInputType.multiline,
                      error: textErr,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    WaVariableChips(controller: _text, variables: const ['اسم_العميل', 'رقم_الطلب', 'رابط_التتبع'], enabled: editable),
                  ],
                ),
              ),
              if (canTeam) ...[
                const SizedBox(height: AppSpacing.lg),
                SettingsGroup(
                  children: [
                    MergeSemantics(
                      child: InkWell(
                        onTap: editable ? () => setState(() => _shared = !_shared) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.wa_qr_shared, style: t.listTitle.copyWith(fontSize: 14.5)),
                                    Text(l.wa_qr_shared_sub, style: t.bodySmall.copyWith(color: c.textSecondary)),
                                  ],
                                ),
                              ),
                              AppSwitch(
                                value: _shared,
                                semanticLabel: l.wa_qr_shared,
                                onChanged: editable ? (v) => setState(() => _shared = v) : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (!_isNew && editable)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Center(
                    child: AppButton(
                      label: l.wa_delete,
                      variant: AppButtonVariant.text,
                      icon: AppIcons.delete,
                      onPressed: _delete,
                      textStyle: t.buttonMedium.copyWith(color: c.textError),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
