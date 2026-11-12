import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../application/kb_answer_editor_controller.dart';
import '../../application/kb_media_controller.dart';
import '../../application/knowledge_controller.dart';
import '../../domain/kb_editor_validation.dart';
import '../../domain/kb_entry.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/editor_conflict_sheet.dart';
import 'widgets/editor_media_section.dart';
import 'widgets/editor_source_banner.dart';

/// The web panel's knowledge entry form, on mobile: النوع · نشط · العنوان ·
/// المحتوى · attachments — nothing the web form doesn't have. Opens as a
/// full-screen modal for a new entry, an edit, a draft review or a prefill
/// from an unanswered question / a chat message.
class KbAnswerEditorScreen extends ConsumerStatefulWidget {
  const KbAnswerEditorScreen({super.key, required this.args});

  final KbeArgs args;

  /// `/knowledge/new?fromQuestion=|fromMessage=|draft=` or `/knowledge/:id/edit`.
  static KbeArgs argsFrom(String? entryId, Map<String, String> q) {
    if (entryId != null) return KbeArgs(mode: KbeMode.edit, id: entryId, appendAlt: q['appendAlt']);
    if (q['fromQuestion'] != null) return KbeArgs(mode: KbeMode.fromUnanswered, id: q['fromQuestion']);
    if (q['fromMessage'] != null) {
      return KbeArgs(mode: KbeMode.fromMessage, id: q['fromMessage'], hintQuestion: q['question'], hintAnswer: q['answer']);
    }
    if (q['draft'] != null) return KbeArgs(mode: KbeMode.draftReview, id: q['draft']);
    return KbeArgs(mode: KbeMode.create, hintQuestion: q['question'], hintAnswer: q['answer']);
  }

  /// Modal page: slide up 300ms / down 250ms.
  static Page<void> page(GoRouterState s) => CustomTransitionPage<void>(
        key: s.pageKey,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, anim, _, child) {
          if (AppMotion.reduced(context)) return child;
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: AppMotion.standard, reverseCurve: Curves.easeInCubic)),
            child: child,
          );
        },
        child: KbAnswerEditorScreen(args: argsFrom(s.pathParameters['id'], s.uri.queryParameters)),
      );

  /// The web form's types, in its order.
  static const types = ['faq', 'product', 'policy', 'company_profile', 'custom_instruction'];

  static String typeLabel(AppLocalizations l, String type) => switch (type) {
        'product' => l.kbe_type_product,
        'policy' => l.kbe_type_policy,
        'company_profile' => l.kbe_type_company_profile,
        'custom_instruction' => l.kbe_type_custom_instruction,
        _ => l.kbe_type_faq,
      };

  @override
  ConsumerState<KbAnswerEditorScreen> createState() => _KbAnswerEditorScreenState();
}

class _KbAnswerEditorScreenState extends ConsumerState<KbAnswerEditorScreen> {
  final _q = TextEditingController();
  final _a = TextEditingController();
  final _qFocus = FocusNode(debugLabel: 'kbe-title-field');
  final _aFocus = FocusNode(debugLabel: 'kbe-content-field');
  final _titleFocus = FocusNode(debugLabel: 'kbe-title');
  int _syncedRevision = -1;
  bool _closing = false;
  bool _deletedShown = false;

  /// Uploading attachments queued before the entry existed (create mode).
  bool _flushing = false;

  KbeArgs get _args => widget.args;
  KbAnswerEditorController get _ctrl => ref.read(kbAnswerEditorControllerProvider(_args).notifier);

  @override
  void initState() {
    super.initState();
    _qFocus.addListener(() {
      if (!_qFocus.hasFocus) _ctrl.blurQuestion();
    });
    _aFocus.addListener(() {
      if (!_aFocus.hasFocus) _ctrl.blurAnswer();
    });
    // Screen readers start on the header title outside create mode.
    if (_args.mode != KbeMode.create) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    _qFocus.dispose();
    _aFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _syncText(KbeState s) {
    if (s.textRevision == _syncedRevision) return;
    _syncedRevision = s.textRevision;
    if (_q.text != s.fields.question) _q.text = s.fields.question;
    if (_a.text != s.fields.answer) _a.text = s.fields.answer;
  }

  // ---- Close / discard -------------------------------------------------------------

  Future<void> _close() async {
    if (_closing) return;
    final s = ref.read(kbAnswerEditorControllerProvider(_args));
    if (s.dirty && s.phase != KbePhase.deleted) {
      final l = context.l10n;
      final discard = await AppDialog.confirm(
        context,
        title: l.kbe_discard_title,
        body: l.kbe_discard_body,
        confirmLabel: l.kbe_discard,
        cancelLabel: l.kbe_keep,
      );
      if (!discard || !mounted) return;
      _ctrl.logDiscard();
      await _ctrl.clearLocalDraft();
      if (!mounted) return;
    }
    _closing = true;
    context.pop();
  }

  // ---- Save / review ---------------------------------------------------------------

  Future<void> _save({int? overwriteVersion}) async {
    FocusScope.of(context).unfocus();
    final l = context.l10n;
    final s = ref.read(kbAnswerEditorControllerProvider(_args));
    if (s.offline) {
      AppSnackbar.show(context, message: l.kbe_save_offline, kind: SnackKind.error);
      return;
    }
    // Inline errors on every field, like the web form's required checks.
    if (!_ctrl.validateAll()) {
      (KbEditorValidation.question(s.fields.question) != null ? _qFocus : _aFocus).requestFocus();
      return;
    }
    final r = await _ctrl.save(overwriteVersion: overwriteVersion);
    if (!mounted) return;
    await _handle(r);
  }

  Future<void> _handle(Object? r) async {
    final l = context.l10n;
    switch (r) {
      case KbeOutcome o:
        HapticFeedback.mediumImpact();
        // Like the web form: files picked before the first save upload now
        // that the entry exists, then the modal closes.
        var mediaFailed = 0;
        final media = ref.read(kbMediaControllerProvider(_args));
        final id = o.entryId;
        if (id != null && media.hasQueued && o.kind != KbeOutcomeKind.proposed) {
          setState(() => _flushing = true);
          mediaFailed = await ref.read(kbMediaControllerProvider(_args).notifier).flush(id);
          if (!mounted) return;
          setState(() => _flushing = false);
        }
        _finish(o, mediaFailed: mediaFailed);
      case KbeSaveFailure(:final conflict?, :final updatedBy):
        final choice = await showEditorConflictSheet(
          context,
          name: updatedBy ?? conflict.updatedBy?.name ?? '—',
          canOverwrite: ref.read(currentAgentProvider).isAdmin,
        );
        if (!mounted) return;
        switch (choice) {
          case KbeConflictChoice.viewTheirs:
            _ctrl.takeTheirs(conflict);
          case KbeConflictChoice.overwrite:
            await _save(overwriteVersion: conflict.version);
          case null:
            break;
        }
      case KbeSaveFailure(forbidden: true):
        AppSnackbar.show(context, message: l.kbe_save_forbidden, kind: SnackKind.error);
      case KbeSaveFailure(:final message):
        AppSnackbar.show(
          context,
          message: message ?? l.kbe_save_err,
          kind: SnackKind.error,
          actionLabel: l.kbe_retry,
          onAction: _save,
        );
      default:
        break;
    }
  }

  /// Close (slide down) and confirm on the screen underneath.
  void _finish(KbeOutcome o, {int mediaFailed = 0}) {
    final l = context.l10n;
    final host = Navigator.of(context, rootNavigator: true).context;
    final router = GoRouter.of(context);
    final (String message, bool view) = switch (o.kind) {
      KbeOutcomeKind.created => (l.kbe_saved_new, true),
      KbeOutcomeKind.edited => (l.kbe_saved_edit, false),
      KbeOutcomeKind.fromUnanswered =>
        (o.waiting > 0 ? l.kbe_saved_unanswered('${o.waiting}') : l.kbe_saved_new, true),
      KbeOutcomeKind.fromChat => (l.kbe_saved_chat, false),
      KbeOutcomeKind.proposed => (l.kbe_proposed, false),
      KbeOutcomeKind.approved => (l.kbe_approved, true),
      KbeOutcomeKind.rejected => (l.kbe_rejected, false),
      KbeOutcomeKind.deleted => (l.kbe_deleted, false),
    };
    _closing = true;
    context.pop();
    final id = o.entryId;
    AppSnackbar.show(
      host,
      message: mediaFailed > 0 ? l.kbe_media_some_failed(mediaFailed) : message,
      kind: mediaFailed > 0 ? SnackKind.error : SnackKind.success,
      actionLabel: view && id != null ? l.kbe_view : null,
      onAction: view && id != null ? () => router.push(Routes.knowledgeDetail(id)) : null,
    );
  }

  Future<void> _reject() async {
    final r = await _ctrl.rejectDraft();
    if (mounted) await _handle(r);
  }

  Future<void> _delete(KbeState s) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.kbe_delete_title(s.base?.question ?? s.fields.question),
      body: l.kbe_delete_body,
      confirmLabel: l.kbe_delete,
      icon: AppIcons.delete,
    );
    if (!ok || !mounted) return;
    final r = await _ctrl.delete();
    if (mounted) await _handle(r);
  }

  Future<void> _pickType(KbeState s) async {
    FocusScope.of(context).unfocus();
    final l = context.l10n;
    final picked = await AppBottomSheet.show<String>(
      context,
      title: l.kbe_type,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in KbAnswerEditorScreen.types)
            AppRadioRow(
              label: KbAnswerEditorScreen.typeLabel(l, t),
              selected: t == s.fields.category,
              onTap: () => Navigator.of(ctx).pop(t),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
    if (picked != null) _ctrl.setCategory(picked);
  }

  // ---- Build -----------------------------------------------------------------------

  String? _errorText(AppLocalizations l, KbeFieldError? e) => switch (e) {
        KbeFieldError.questionShort => l.kbe_err_q,
        KbeFieldError.answerShort => l.kbe_err_a,
        KbeFieldError.answerLong => l.kbe_err_a_long,
        _ => null,
      };

  Widget? _sourceBanner(KbeState s) {
    final c = context.colors;
    final l = context.l10n;
    final now = DateTime.now();
    switch (_args.mode) {
      case KbeMode.fromUnanswered when s.unanswered != null:
        final u = s.unanswered!;
        return EditorSourceBanner(
          icon: AppIcons.ai,
          iconColor: c.primary,
          text: l.kbe_src_unanswered('${u.count}'),
          linkLabel: u.conversationIds.isEmpty ? null : l.kbe_view_convs,
          onLink: u.conversationIds.isEmpty ? null : () => context.push(Routes.chat(u.conversationIds.first)),
        );
      case KbeMode.fromMessage when s.messagePrefill != null:
        final m = s.messagePrefill!;
        final date = m.date == null ? '' : RelativeTimeFormatter.format(m.date!, now, l, context.localeName);
        return EditorSourceBanner(
          icon: AppIcons.conversation,
          text: l.kbe_src_chat(m.customerName ?? '—', date),
          linkLabel: m.conversationId == null ? null : l.kbe_open,
          onLink: m.conversationId == null ? null : () => context.push(Routes.chat(m.conversationId!)),
        );
      case KbeMode.draftReview when s.base != null:
        final b = s.base!;
        final at = b.createdAt ?? b.updatedAt;
        return EditorSourceBanner(
          icon: AppIcons.edit,
          text: b.draftSource == KbDraftSource.aiFromConversation || b.draftedBy == null
              ? l.kbe_src_draft_conv
              : l.kbe_src_draft(b.draftedBy!.name, at == null ? '' : RelativeTimeFormatter.format(at, now, l, context.localeName)),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final provider = kbAnswerEditorControllerProvider(_args);
    final s = ref.watch(provider);
    _syncText(s);

    ref.listen(provider.select((x) => x.phase), (_, phase) {
      if (phase == KbePhase.deleted && !_deletedShown) {
        _deletedShown = true;
        _showDeletedDialog();
      }
    });
    // Read-only users can't open the edit route → detail screen.
    if (_args.mode == KbeMode.edit && !s.canEdit && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(Routes.knowledgeDetail(_args.id!));
      });
    }

    final review = _args.mode == KbeMode.draftReview;
    final title = switch (_args.mode) {
      KbeMode.edit => l.kbe_edit,
      KbeMode.draftReview => l.kbe_review,
      _ => l.kbe_new,
    };
    final ready = s.phase == KbePhase.ready || s.phase == KbePhase.saving;
    final editable = ready && !s.saving && !_flushing;
    final canSubmit = ready && !s.offline && !_flushing;
    // Attachments: list meta when loaded, else edit rights; never in propose mode.
    final list = ref.watch(knowledgeControllerProvider.select((x) => (x.loaded, x.permissions.canUploadMedia)));
    final canUploadMedia = s.canEdit && (list.$1 ? list.$2 : s.canEdit);

    Widget body;
    if (s.phase == KbePhase.loading) {
      body = const _EditorSkeleton();
    } else if (s.phase == KbePhase.loadError) {
      body = EmptyState(icon: AppIcons.error, title: l.kbe_load_error, actionLabel: l.kbe_retry, onAction: _ctrl.load);
    } else if (s.phase == KbePhase.deleted) {
      body = const SizedBox.shrink();
    } else {
      final banner = _sourceBanner(s);
      body = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(18, AppSpacing.md, 18, AppSpacing.xxl + MediaQuery.viewInsetsOf(context).bottom),
          children: [
            if (s.restorable != null) ...[
              EditorRestoreDraftBanner(onRestore: _ctrl.restoreLocalDraft, onIgnore: _ctrl.ignoreLocalDraft),
              const SizedBox(height: AppSpacing.md),
            ],
            if (banner != null) ...[banner, const SizedBox(height: AppSpacing.md)],
            // 1 · النوع (required select, like the web form).
            _Label(text: l.kbe_type, required: true),
            _TypeField(
              label: KbAnswerEditorScreen.typeLabel(l, s.fields.category),
              enabled: editable,
              onTap: () => _pickType(s),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 2 · العنوان
            AppTextField(
              label: '${l.kbe_title_label} *',
              hint: l.kbe_title_ph,
              controller: _q,
              focusNode: _qFocus,
              onChanged: _ctrl.setQuestion,
              error: _errorText(l, s.questionError),
              maxLength: KbEditorValidation.questionMax,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              autofocus: _args.mode == KbeMode.create && s.fields.question.isEmpty,
              enabled: editable,
              onSubmitted: (_) => _aFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            // 3 · المحتوى
            AppTextField(
              label: '${l.kbe_content_label} *',
              hint: l.kbe_content_ph,
              controller: _a,
              focusNode: _aFocus,
              onChanged: _ctrl.setAnswer,
              error: _errorText(l, s.answerError),
              minLines: 6,
              maxLines: 14,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enabled: editable,
            ),
            const SizedBox(height: AppSpacing.md),
            // 4 · نشط
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.border),
              ),
              child: SettingsTile(
                title: l.kbe_active,
                subtitle: l.kbe_active_sub,
                showChevron: false,
                trailing: AppSwitch(
                  value: s.fields.enabled,
                  semanticLabel: l.kbe_active,
                  onChanged: editable ? _ctrl.setEnabled : null,
                ),
                onTap: editable ? () => _ctrl.setEnabled(!s.fields.enabled) : null,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 5 · المرفقات (images / voice notes, send mode per file).
            EditorMediaSection(args: _args, enabled: editable, canUpload: canUploadMedia),
          ],
        ),
      );
    }

    final saveLabel = review ? null : (s.canEdit ? l.kbe_save : l.kbe_send);

    return PopScope(
      canPop: !s.dirty || _closing || s.phase == KbePhase.deleted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: Scaffold(
          backgroundColor: c.background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                EditorAppBar(
                  title: title,
                  titleFocus: _titleFocus,
                  onClose: _close,
                  saveLabel: saveLabel,
                  saving: (s.saving || _flushing) && !review,
                  onSave: canSubmit && !s.saving ? _save : null,
                ),
                ConnectionBanner(state: s.offline ? NetworkState.offline : NetworkState.online, offlineLabel: l.kbe_save_offline),
                Expanded(child: body),
                if (review && ready)
                  _BottomBar(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: l.kbe_reject,
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.large,
                            expand: true,
                            onPressed: s.saving || s.offline ? null : _reject,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: l.kbe_approve,
                            size: AppButtonSize.large,
                            expand: true,
                            loading: s.saving || _flushing,
                            onPressed: canSubmit && !s.saving ? _save : null,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_args.mode == KbeMode.edit && ready && s.canEdit && MediaQuery.viewInsetsOf(context).bottom == 0)
                  _BottomBar(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        label: l.kbe_delete,
                        variant: AppButtonVariant.text,
                        icon: AppIcons.delete,
                        onPressed: s.saving || s.offline ? null : () => _delete(s),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeletedDialog() async {
    final l = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.kbe_deleted_elsewhere, style: ctx.text.h5),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.kbe_close))],
      ),
    );
    if (!mounted) return;
    _closing = true;
    context.pop();
  }
}

/// Field label above an input (`inputLabel`), "*" for required ones.
class _Label extends StatelessWidget {
  const _Label({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [if (required) TextSpan(text: ' *', style: TextStyle(color: context.colors.error))],
        ),
        style: t.inputLabel,
      ),
    );
  }
}

/// Select-like field for النوع: current type + chevron, opens the radio sheet.
class _TypeField extends StatelessWidget {
  const _TypeField({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${context.l10n.kbe_type}: $label',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(child: Text(label, style: t.bodyMedium.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600))),
                AppIcon(AppIcons.chevronDown, size: AppIconSize.sm, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(color: c.background, border: Border(top: BorderSide(color: c.divider))),
      padding: EdgeInsets.fromLTRB(18, AppSpacing.sm, 18, AppSpacing.sm + MediaQuery.viewPaddingOf(context).bottom),
      child: child,
    );
  }
}

/// Loading (edit / prefill): the form's field skeletons; the app bar stays active.
class _EditorSkeleton extends StatelessWidget {
  const _EditorSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget field(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border, width: 1.5),
          ),
        );
    final content = ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, AppSpacing.md, 18, 0),
      children: [
        const SkeletonBox(width: 50, height: 12),
        const SizedBox(height: AppSpacing.sm),
        field(52),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(width: 60, height: 12),
        const SizedBox(height: AppSpacing.sm),
        field(52),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(width: 60, height: 12),
        const SizedBox(height: AppSpacing.sm),
        field(150),
        const SizedBox(height: AppSpacing.md),
        field(60),
      ],
    );
    return AppMotion.reduced(context) ? content : AppSkeleton(child: content);
  }
}
