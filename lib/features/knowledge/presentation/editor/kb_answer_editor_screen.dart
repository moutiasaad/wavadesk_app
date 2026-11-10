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
import '../../../chat/presentation/sheets/ai_rewrite/ai_rewrite_sheet.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../application/kb_answer_editor_controller.dart';
import '../../application/kb_media_controller.dart';
import '../../application/knowledge_controller.dart';
import '../../domain/kb_editor_validation.dart';
import '../../domain/kb_entry.dart';
import 'widgets/ai_preview_card.dart';
import 'widgets/alt_phrasings_editor.dart';
import 'widgets/answer_field.dart';
import 'widgets/duplicate_warning.dart';
import 'widgets/editor_advanced_section.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/editor_conflict_sheet.dart';
import 'widgets/editor_media_section.dart';
import 'widgets/editor_meta_footer.dart';
import 'widgets/editor_source_banner.dart';
import 'widgets/editor_tools_row.dart';
import 'widgets/kb_tag_picker_sheet.dart';
import 'widgets/question_field.dart';
import 'widgets/versions_sheet.dart';

/// إضافة إجابة (Add Answer spec, frame 13): a full-screen modal that adds,
/// edits or reviews one Q&A with a live preview of the AI reply.
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

  /// Modal page: slide up 300ms / down 250ms (§12).
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

  @override
  ConsumerState<KbAnswerEditorScreen> createState() => _KbAnswerEditorScreenState();
}

class _KbAnswerEditorScreenState extends ConsumerState<KbAnswerEditorScreen> {
  final _q = TextEditingController();
  final _a = KbAnswerTextController();
  final _qFocus = FocusNode(debugLabel: 'kbe-question');
  final _aFocus = FocusNode(debugLabel: 'kbe-answer');
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
    // §10: focus the title for screen readers outside create mode.
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

  // ---- Close / discard (§6.3) ------------------------------------------------------

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

  /// Close (slide down) and confirm on the screen underneath (§5).
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

  // ---- Tools -----------------------------------------------------------------------

  Future<void> _pickTags(KbeState s) async {
    final picked = await showKbTagPickerSheet(context, selected: s.fields.tags, load: _ctrl.tags);
    if (picked != null) _ctrl.setTags(picked);
  }

  Future<void> _improve(KbeState s) async {
    FocusScope.of(context).unfocus();
    final out = await showKbAnswerRewriteSheet(context, ref, source: s.fields.answer.trim(), aiEnabled: s.aiAvailable);
    if (out != null) _ctrl.replaceAnswer(out.text);
  }

  Future<void> _addLink() async {
    final l = context.l10n;
    final url = TextEditingController();
    final title = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l.kbe_add_link, style: ctx.text.h5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: l.kbe_link_url,
                hint: 'https://',
                controller: url,
                autofocus: true,
                error: error,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l.kbe_link_label, controller: title),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.kbe_cancel)),
            TextButton(
              onPressed: () {
                final u = url.text.trim();
                final uri = Uri.tryParse(u);
                if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http') || uri.host.isEmpty) {
                  setLocal(() => error = l.kbe_link_invalid);
                  return;
                }
                final t = title.text.trim();
                Navigator.of(ctx).pop(t.isEmpty ? u : '$t: $u');
              },
              child: Text(l.kbe_insert),
            ),
          ],
        ),
      ),
    );
    url.dispose();
    title.dispose();
    if (result == null || !mounted) return;
    final text = _a.text;
    final sel = _a.selection;
    final at = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
    final pre = at > 0 && !RegExp(r'\s$').hasMatch(text.substring(0, at)) ? ' ' : '';
    final next = text.replaceRange(at, at, '$pre$result ');
    _a.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: at + pre.length + result.length + 1));
    _ctrl.setAnswer(next);
  }

  void _openEntry(String id) => context.push(Routes.knowledgeDetail(id));

  void _mergeInto(String id, KbeState s) {
    // The entry editor opens with this question appended to its phrasings.
    _ctrl.clearLocalDraft();
    _closing = true;
    context.pushReplacement(Uri(path: '/knowledge/$id/edit', queryParameters: {'appendAlt': s.fields.question.trim()}).toString());
  }

  // ---- Build -----------------------------------------------------------------------

  String? _errorText(AppLocalizations l, KbeFieldError? e) => switch (e) {
        KbeFieldError.questionShort => l.kbe_err_q,
        KbeFieldError.answerShort => l.kbe_err_a,
        KbeFieldError.answerLong => l.kbe_err_a_long,
        KbeFieldError.datePast => l.kbe_err_date,
        null => null,
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
    // Read-only users can't open the edit route (§7) → detail screen.
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
    final canSubmit = ready && s.valid && !s.offline && !_flushing;
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
      final showWarning = !s.warningDismissed && (s.similar != null || s.conflict != null);
      body = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: const EdgeInsets.fromLTRB(18, AppSpacing.sm, 18, AppSpacing.xxl),
          children: [
            if (s.restorable != null)
              EditorRestoreDraftBanner(onRestore: _ctrl.restoreLocalDraft, onIgnore: _ctrl.ignoreLocalDraft),
            ?banner,
            QuestionField(
              controller: _q,
              focusNode: _qFocus,
              onChanged: _ctrl.setQuestion,
              error: _errorText(l, s.questionError),
              autofocus: _args.mode == KbeMode.create && s.fields.question.isEmpty,
              enabled: editable,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(child: Text(l.kbe_alts, style: context.text.inputLabel)),
                const SizedBox(width: AppSpacing.xs),
                Text(l.kbe_optional, style: context.text.caption.copyWith(color: c.textTertiary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AltPhrasingsEditor(
              alts: s.fields.alts,
              ghosts: s.ghosts,
              shakeTick: s.shakeTick,
              enabled: editable,
              onAdd: (items) => _ctrl.addAlts(items),
              onEdit: _ctrl.editAlt,
              onRemove: _ctrl.removeAlt,
              onAcceptGhost: _ctrl.acceptGhost,
              onDismissGhost: _ctrl.dismissGhost,
            ),
            const SizedBox(height: 14),
            AnswerField(
              controller: _a,
              focusNode: _aFocus,
              onChanged: _ctrl.setAnswer,
              error: _errorText(l, s.answerError),
              aiDraft: s.aiDraft,
              enabled: editable,
            ),
            const SizedBox(height: 10),
            EditorToolsRow(
              tags: s.fields.tags,
              enabled: editable,
              onTag: () => _pickTags(s),
              onImprove: s.fields.answer.trim().isEmpty || s.offline ? null : () => _improve(s),
              onAddLink: _addLink,
            ),
            AnimatedSize(
              duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.normal,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.normal,
                child: showWarning
                    ? DuplicateWarning(
                        key: ValueKey('${s.similar?.id}-${s.conflict?.id}'),
                        similar: s.similar,
                        conflict: s.conflict,
                        onOpen: _openEntry,
                        onMerge: s.canEdit && _args.mode != KbeMode.edit ? (id) => _mergeInto(id, s) : null,
                        onDismiss: _ctrl.dismissWarning,
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
            EditorMediaSection(args: _args, enabled: editable, canUpload: canUploadMedia),
            AiPreviewCard(
              preview: s.preview,
              loading: s.previewLoading,
              error: s.previewError,
              offline: s.offline,
              ready: KbEditorValidation.question(s.fields.question) == null && KbEditorValidation.answer(s.fields.answer) == null,
              fallbackQuestion: s.testQuestion ?? (s.fields.alts.isNotEmpty ? s.fields.alts.last : s.fields.question.trim()),
              onRefresh: _ctrl.refreshPreview,
              onTestQuestion: _ctrl.setTestQuestion,
              onTryAnother: _ctrl.tryAnother,
              onTone: () => context.push(Routes.aiAgent),
            ),
            EditorAdvancedSection(
              enabled: s.fields.enabled,
              channels: s.fields.channels,
              expiresAt: s.fields.expiresAt,
              verbatim: s.fields.verbatim,
              handoffAfter: s.fields.handoffAfter,
              internalNotes: s.fields.internalNotes,
              dateError: _errorText(l, s.dateError),
              editable: editable,
              initiallyExpanded: s.fields.expiresAt != null || s.fields.verbatim || s.fields.handoffAfter,
              onEnabled: _ctrl.setEnabled,
              onChannels: _ctrl.setChannels,
              onExpiresAt: _ctrl.setExpiresAt,
              onVerbatim: _ctrl.setVerbatim,
              onHandoffAfter: _ctrl.setHandoffAfter,
              onInternalNotes: _ctrl.setInternalNotes,
            ),
            if (_args.mode == KbeMode.edit && s.base != null)
              EditorMetaFooter(
                entry: s.base!,
                onHistory: () => showVersionsSheet(context, load: _ctrl.versions, onRestore: _ctrl.restoreVersion),
              ),
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

/// Loading (edit / prefill, §7): field skeletons; the app bar stays active.
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
      padding: const EdgeInsets.fromLTRB(18, AppSpacing.sm, 18, 0),
      children: [
        const SkeletonBox(width: 60, height: 12),
        const SizedBox(height: AppSpacing.sm),
        field(52),
        const SizedBox(height: 18),
        const SkeletonBox(width: 150, height: 12),
        const SizedBox(height: AppSpacing.sm),
        const Row(
          children: [
            SkeletonBox(width: 110, height: 32, radius: AppRadius.full),
            SizedBox(width: 6),
            SkeletonBox(width: 90, height: 32, radius: AppRadius.full),
          ],
        ),
        const SizedBox(height: 18),
        const SkeletonBox(width: 60, height: 12),
        const SizedBox(height: AppSpacing.sm),
        field(140),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 150, decoration: BoxDecoration(color: c.backgroundMuted, borderRadius: BorderRadius.circular(AppRadius.xl))),
      ],
    );
    return AppMotion.reduced(context) ? content : AppSkeleton(child: content);
  }
}
