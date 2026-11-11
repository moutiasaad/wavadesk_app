import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../domain/kb_entry.dart';

/// Answers the AI drafted from an uploaded document (`GET kb/files/{id}`).
/// Admins tick what the AI should know and add them in one go; each card
/// can be edited (draft editor) or discarded. Others see the list and a
/// note that an admin will review it.
class KbDocumentReviewScreen extends ConsumerStatefulWidget {
  const KbDocumentReviewScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<KbDocumentReviewScreen> createState() => _KbDocumentReviewScreenState();
}

class _KbDocumentReviewScreenState extends ConsumerState<KbDocumentReviewScreen> {
  KbFile? _file;
  bool _failed = false;
  final Set<String> _selected = {};
  final Set<String> _expanded = {};
  final Set<String> _discarding = {};

  /// (done, total) while adding.
  (int, int)? _adding;

  @override
  void initState() {
    super.initState();
    _load(selectAll: true);
  }

  Future<void> _load({bool selectAll = false}) async {
    try {
      final f = await ref.read(kbApiProvider).file(widget.id);
      if (!mounted) return;
      final ids = {for (final c in f.chunks) c.id};
      setState(() {
        _file = f;
        _failed = false;
        if (selectAll) {
          _selected
            ..clear()
            ..addAll(ids);
        } else {
          _selected.retainAll(ids);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _edit(KbChunk chunk) async {
    await context.push(Routes.knowledgeReviewDraft(chunk.id));
    await _load();
  }

  Future<void> _discard(KbChunk chunk) async {
    final l = context.l10n;
    HapticFeedback.lightImpact();
    setState(() => _discarding.add(chunk.id));
    try {
      await ref.read(kbApiProvider).rejectDraft(chunk.id);
      Analytics.log('kb_doc_review', {'action': 'discard'});
      await _load();
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.kb_save_err, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _discarding.remove(chunk.id));
    }
  }

  Future<void> _addSelected() async {
    final l = context.l10n;
    final ids = [for (final c in _file!.chunks) if (_selected.contains(c.id)) c.id];
    if (ids.isEmpty) return;
    final api = ref.read(kbApiProvider);
    var done = 0;
    var failed = 0;
    setState(() => _adding = (0, ids.length));
    for (final id in ids) {
      try {
        await api.approveDraft(id);
        done++;
      } catch (_) {
        failed++;
      }
      if (mounted) setState(() => _adding = (done + failed, ids.length));
    }
    Analytics.log('kb_doc_review', {'action': 'add', 'count': done, 'failed': failed});
    ref.read(knowledgeControllerProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _adding = null);
    await _load();
    if (!mounted) return;
    final left = _file?.chunks.length ?? 0;
    if (failed > 0) {
      AppSnackbar.show(context, message: l.kb_review_partial(done, failed), kind: SnackKind.error);
    } else if (left == 0) {
      AppSnackbar.show(context, message: l.kb_review_added(done), kind: SnackKind.success);
      context.pop();
    } else {
      AppSnackbar.show(context, message: l.kb_review_added_left(done, left), kind: SnackKind.success);
    }
  }

  void _toggleAll(bool all) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected.clear();
      if (all) _selected.addAll(_file!.chunks.map((c) => c.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final f = _file;

    final Widget body;
    if (f == null) {
      body = _failed
          ? EmptyState(icon: AppIcons.failed, title: l.kb_error, actionLabel: l.kb_retry, onAction: _load)
          : const Center(child: AppSpinner());
    } else if (f.chunks.isEmpty) {
      body = EmptyState(
        icon: AppIcons.success,
        title: l.kb_review_all_done,
        body: l.kb_review_all_done_body,
        actionLabel: l.common_done,
        onAction: () => context.pop(),
      );
    } else {
      body = _list(context, f);
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: l.kb_review_title, background: c.backgroundMuted),
      body: body,
      bottomNavigationBar: f != null && f.chunks.isNotEmpty && f.canApprove ? _bottomBar(context, f) : null,
    );
  }

  Widget _list(BuildContext context, KbFile f) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final all = _selected.length == f.chunks.length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          // Where these came from + what happens next.
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.primaryContainerBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.ai, color: c.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.kb_review_from(f.chunks.length, f.name), style: t.listTitle.copyWith(color: c.onPrimaryContainer)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        f.canApprove ? l.kb_review_hint : l.kb_found_admin_hint,
                        style: t.bodySmall.copyWith(color: c.onPrimaryContainer.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (f.canApprove) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(l.kb_review_selected(_selected.length, f.chunks.length), style: t.caption.copyWith(color: c.textSecondary)),
                const Spacer(),
                TextButton(
                  onPressed: _adding == null ? () => _toggleAll(!all) : null,
                  child: Text(all ? l.kb_review_clear : l.kb_review_select_all),
                ),
              ],
            ),
          ] else
            const SizedBox(height: AppSpacing.md),
          for (final chunk in f.chunks) ...[
            _card(context, chunk, f.canApprove),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, KbChunk chunk, bool canApprove) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final selected = _selected.contains(chunk.id);
    final expanded = _expanded.contains(chunk.id);
    final busy = _discarding.contains(chunk.id) || _adding != null;

    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: _discarding.contains(chunk.id) ? 0.4 : 1,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: selected && canApprove ? c.primary : c.border, width: selected && canApprove ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy || !canApprove
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() => selected ? _selected.remove(chunk.id) : _selected.add(chunk.id));
                },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canApprove) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AppCheckbox(
                      value: selected,
                      onChanged: busy ? null : (v) => setState(() => v ? _selected.add(chunk.id) : _selected.remove(chunk.id)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chunk.title, style: t.listTitle),
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => setState(() => expanded ? _expanded.remove(chunk.id) : _expanded.add(chunk.id)),
                        child: AnimatedSize(
                          duration: AppMotion.fast,
                          alignment: AlignmentDirectional.topStart,
                          child: Text(
                            chunk.preview,
                            style: t.bodyMedium.copyWith(color: c.textSecondary),
                            maxLines: expanded ? null : 3,
                            overflow: expanded ? null : TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (canApprove)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: busy ? null : () => _edit(chunk),
                              icon: AppIcon(AppIcons.edit, dp: 16, color: c.primary),
                              label: Text(l.kb_review_edit),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: c.textError),
                              onPressed: busy ? null : () => _discard(chunk),
                              icon: AppIcon(AppIcons.delete, dp: 16, color: c.textError),
                              label: Text(l.kb_review_discard),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, KbFile f) {
    final c = context.colors;
    final l = context.l10n;
    final adding = _adding;
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.divider))),
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md + MediaQuery.paddingOf(context).bottom),
      child: AppButton(
        label: adding != null ? l.kb_review_adding(adding.$1, adding.$2) : l.kb_review_add(_selected.length),
        icon: adding != null ? null : AppIcons.check,
        loading: adding != null,
        expand: true,
        size: AppButtonSize.large,
        onPressed: _selected.isEmpty || adding != null ? null : _addSelected,
      ),
    );
  }
}
