import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../shell/home_shell.dart';
import '../application/kb_upload_controller.dart';
import '../application/knowledge_controller.dart';
import '../data/kb_api.dart';
import '../domain/kb_entry.dart';
import 'files/kb_file_upload_sheet.dart';
import 'files/kb_import_sheet.dart';
import 'links/kb_link_add_sheet.dart';
import 'widgets/kb_add_sheet.dart';
import 'widgets/kb_drafts_section.dart';
import 'widgets/kb_empty_state.dart';
import 'widgets/kb_entry_tile.dart';
import 'widgets/kb_skeleton.dart';
import 'widgets/kb_sort_header.dart';
import 'widgets/kb_type_stats_row.dart';
import 'widgets/kb_search_entry.dart';
import 'widgets/kb_unanswered_banner.dart';

enum _Overflow { aiSettings, tags, import }

enum _RowAction { edit, copy, toggle, delete }

/// المعرفة — tab root (Knowledge Base spec "12 Knowledge Base.md").
class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  bool _logged = false;

  KbListController get _ctrl => ref.read(knowledgeControllerProvider.notifier);

  double get _snackOffset => AppTabBar.height;

  bool get _offline => ref.read(inboxProvider).network == NetworkState.offline;

  void _snack(String message, {SnackKind kind = SnackKind.info, String? actionLabel, VoidCallback? onAction}) =>
      AppSnackbar.show(context, message: message, kind: kind, actionLabel: actionLabel, onAction: onAction, bottomOffset: _snackOffset);

  /// Editing needs a connection (spec §7 Offline).
  bool _guardOnline() {
    if (!_offline) return true;
    _snack(context.l10n.kb_offline, kind: SnackKind.error);
    return false;
  }

  Future<void> _add() async {
    if (!_guardOnline()) return;
    final choice = await showKbAddSheet(context);
    if (choice == null || !mounted) return;
    switch (choice) {
      case KbAddChoice.qa:
        context.push('/knowledge/new');
      case KbAddChoice.document:
        // Picker opens right away; the sheet then shows the steps and ends
        // on "Review answers".
        await startKbFileUpload(context, ref, snackOffset: _snackOffset);
      case KbAddChoice.json:
        // Same as the web panel: a JSON file of entries.
        await startKbJsonImport(context, ref);
      case KbAddChoice.link:
        final id = await showKbLinkAddSheet(context);
        if (id != null && mounted) _snack(context.l10n.kb_link_added, kind: SnackKind.success);
    }
  }

  void _open(KbEntrySummary e, int position) {
    Analytics.log('kb_open_entry', {'type': e.type.name, 'position': position});
    if (e.status == KbStatus.draft) {
      context.push('/knowledge/new?draft=${Uri.encodeComponent(e.id)}');
      return;
    }
    context.push(switch (e.type) {
      KbType.qa => '/knowledge/${Uri.encodeComponent(e.id)}',
      KbType.file => '/knowledge/files/${Uri.encodeComponent(e.id)}',
      KbType.link => '/knowledge/links/${Uri.encodeComponent(e.id)}',
    });
  }

  Future<void> _toggle(KbEntrySummary e) async {
    if (!_guardOnline()) return;
    final l = context.l10n;
    final enable = !e.enabled;
    Analytics.log('kb_toggle_enabled', {'type': e.type.name});
    final ok = await _ctrl.setEnabled(e.id, enable);
    if (!mounted) return;
    ok
        ? _snack(enable ? l.kb_enabled_done : l.kb_disabled_done, kind: SnackKind.success, actionLabel: l.common_undo, onAction: () => _ctrl.setEnabled(e.id, !enable))
        : _snack(l.kb_save_err, kind: SnackKind.error);
  }

  Future<void> _delete(KbEntrySummary e) async {
    if (!_guardOnline()) return;
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.kb_delete_title(e.title),
      body: l.kb_delete_body,
      confirmLabel: l.kb_delete,
      icon: AppIcons.delete,
    );
    if (!ok || !mounted) return;
    Analytics.log('kb_delete', {'type': e.type.name});
    _ctrl.deleteWithUndo(e.id, onError: (_) {
      if (mounted) _snack(l.kb_save_err, kind: SnackKind.error);
    });
    _snack(l.kb_deleted, kind: SnackKind.success, actionLabel: l.common_undo, onAction: () => _ctrl.undoDelete(e.id));
  }

  Future<void> _longPress(KbEntrySummary e, KbPermissions perms) async {
    final l = context.l10n;
    final isQa = e.type == KbType.qa;
    final action = await AppBottomSheet.show<_RowAction>(
      context,
      title: e.title,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (perms.canEdit && isQa) SheetActionRow(icon: AppIcons.edit, label: l.kb_edit, onTap: () => Navigator.of(ctx).pop(_RowAction.edit)),
          if (isQa) SheetActionRow(icon: AppIcons.copy, label: l.kb_copy_answer, onTap: () => Navigator.of(ctx).pop(_RowAction.copy)),
          if (perms.canEdit)
            SheetActionRow(
              icon: e.enabled ? AppIcons.hidePassword : AppIcons.preview,
              label: e.enabled ? l.kb_disable : l.kb_enable,
              onTap: () => Navigator.of(ctx).pop(_RowAction.toggle),
            ),
          if (perms.canDelete)
            SheetActionRow(icon: AppIcons.delete, label: l.kb_delete, destructive: true, onTap: () => Navigator.of(ctx).pop(_RowAction.delete)),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _RowAction.edit:
        if (_guardOnline()) context.push('/knowledge/${Uri.encodeComponent(e.id)}/edit');
      case _RowAction.copy:
        try {
          final qa = await ref.read(kbApiProvider).fetchQa(e.id);
          await Clipboard.setData(ClipboardData(text: qa.answer));
          if (mounted) _snack(l.kb_copied, kind: SnackKind.success);
        } catch (_) {
          if (mounted) _snack(l.kb_save_err, kind: SnackKind.error);
        }
      case _RowAction.toggle:
        _toggle(e);
      case _RowAction.delete:
        _delete(e);
    }
  }

  Future<void> _overflow(_Overflow o) async {
    switch (o) {
      case _Overflow.aiSettings:
        context.push(Routes.aiAgent);
      case _Overflow.import:
        // JSON import works in the app now (same as the web panel).
        await startKbJsonImport(context, ref);
      case _Overflow.tags:
        // Tag management lives on the web dashboard (spec §1).
        final uri = Uri.parse('$apiBaseUrl/knowledge');
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
        if (mounted) _snack(context.l10n.kb_web_only);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(knowledgeControllerProvider);
    final network = ref.watch(inboxProvider.select((i) => i.network));
    final agent = ref.watch(currentAgentProvider);
    final perms = s.permissions;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    ref.listen(kbUploadControllerProvider.select((u) => u.readyTick), (_, _) {
      final job = ref.read(kbUploadControllerProvider).lastReady;
      // The upload sheet shows the result itself while it is open.
      if (job == null || ModalRoute.of(context)?.isCurrent != true) return;
      if (job.phase == KbUploadPhase.failed) {
        _snack(l.kb_file_failed_named(job.file.name), kind: SnackKind.error);
        return;
      }
      final id = job.entryId;
      final review = id != null && (job.result?.canApprove ?? false);
      _snack(
        l.kb_file_ready(job.file.name, job.facts),
        kind: SnackKind.success,
        actionLabel: review ? l.kb_review_answers : null,
        onAction: review ? () => context.push(Routes.knowledgeFileReview(id)) : null,
      );
    });

    // A failed refresh keeps the rows on screen; say so once (rule 3).
    ref.listen(knowledgeControllerProvider.select((k) => k.loaded && k.error != null), (was, failed) {
      if (failed && was != true && network == NetworkState.online) _snack(l.kb_error, kind: SnackKind.error);
    });

    if (s.loaded && !s.loading && !_logged) {
      _logged = true;
      Analytics.log('kb_view', {'total': s.counts.total, 'unanswered': s.unansweredCount, 'role': agent.role.name});
    }

    final kbHeader = _KbAppBarDelegate(
      title: l.kb_title,
      textScale: scale,
      // The brand header paints under the status bar (no top SafeArea).
      topInset: MediaQuery.paddingOf(context).top,
      actions: [
        if (perms.canEdit)
          AppIconButton(
            icon: AppIcons.add,
            variant: AppIconButtonVariant.primary,
            size: 36,
            iconSize: 18,
            semanticLabel: l.kb_add_title,
            onPressed: _add,
          ),
        PopupMenuButton<_Overflow>(
            icon: AppIcon(AppIcons.more, dp: 18, color: c.textPrimary),
            tooltip: l.common_more,
            onSelected: _overflow,
            itemBuilder: (_) => [
              PopupMenuItem(value: _Overflow.aiSettings, child: Text(l.kb_menu_ai_settings)),
              if (perms.canEdit) PopupMenuItem(value: _Overflow.tags, child: Text(l.kb_menu_tags)),
              if (perms.canEdit) PopupMenuItem(value: _Overflow.import, child: Text(l.kb_menu_import)),
            ],
          ),
      ],
    );
    final header = SliverPersistentHeader(pinned: true, delegate: kbHeader);

    final bottomPad = tabBarInset(context) + AppSpacing.lg;
    final slivers = <Widget>[header];

    if (network != NetworkState.online) {
      slivers.add(SliverToBoxAdapter(child: ConnectionBanner(state: network, offlineLabel: l.kb_offline)));
    }

    if (!s.loaded && s.error != null) {
      final e = s.error;
      slivers.add(SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: e is KbApiException && e.isNetwork ? AppIcons.offline : AppIcons.error,
          title: l.kb_error,
          actionLabel: l.kb_retry,
          onAction: _ctrl.refresh,
        ),
      ));
    } else if (!s.loaded) {
      slivers.add(const SliverToBoxAdapter(child: KbSkeleton()));
    } else if (s.isEmptyKb && s.type == null && s.tags.isEmpty) {
      if (s.unansweredCount > 0) {
        slivers.add(SliverToBoxAdapter(child: KbUnansweredBanner(count: s.unansweredCount, onReview: () => context.push('/knowledge/unanswered'))));
      }
      slivers.add(SliverFillRemaining(
        hasScrollBody: false,
        child: KbEmptyState(
          canEdit: perms.canEdit,
          onAddQa: () => _guardOnline() ? context.push('/knowledge/new') : null,
          onUpload: () => _guardOnline() ? startKbFileUpload(context, ref, snackOffset: _snackOffset) : null,
        ),
      ));
    } else {
      slivers.addAll([
        SliverToBoxAdapter(child: KbSearchEntry(total: s.counts.total)),
        SliverToBoxAdapter(
          child: KbTypeStatsRow(
            counts: s.counts,
            selected: s.type,
            processing: s.counts.processing,
            onSelect: (t) {
              Analytics.log('kb_filter_type', {'value': t?.name ?? 'all'});
              _ctrl.setType(t);
            },
          ),
        ),
        if (s.unansweredCount > 0)
          SliverToBoxAdapter(child: KbUnansweredBanner(count: s.unansweredCount, onReview: () => context.push('/knowledge/unanswered'))),
        SliverToBoxAdapter(
          child: KbSortHeader(
            sort: s.sort,
            onSort: _ctrl.setSort,
            selectedTags: s.tags,
            loadTags: () => ref.read(kbApiProvider).tags(),
            onTags: _ctrl.setTags,
          ),
        ),
        if (s.refetching)
          const SliverToBoxAdapter(child: KbSkeleton(rowsOnly: true))
        else if (s.items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: EmptyState(
                icon: AppIcons.filterX,
                title: l.kb_filter_empty,
                actionLabel: l.kb_show_all,
                onAction: () {
                  _ctrl.setTags(const {});
                  _ctrl.setType(null);
                },
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.fast,
              child: KeyedSubtree(
                key: ValueKey('${s.type}-${s.sort}-${s.tags.join(',')}'),
                child: SettingsGroup(
                  children: [
                    for (var i = 0; i < s.items.length; i++)
                      KbEntryTile(
                        key: ValueKey(s.items[i].id),
                        entry: s.items[i],
                        onTap: () => _open(s.items[i], i),
                        onLongPress: perms.canEdit || s.items[i].type == KbType.qa ? () => _longPress(s.items[i], perms) : null,
                        onToggle: perms.canEdit ? () => _toggle(s.items[i]) : null,
                        onDelete: perms.canDelete ? () => _delete(s.items[i]) : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (s.hasMore && !s.refetching)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: AppSpinner()))),
        if (perms.canReviewDrafts && s.drafts.isNotEmpty && s.type == null)
          SliverToBoxAdapter(child: KbDraftsSection(drafts: s.drafts, onOpen: (d) => _open(d, -1))),
      ]);
    }
    slivers.add(SliverToBoxAdapter(child: SizedBox(height: bottomPad)));

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SlidableAutoCloseBehavior(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 400) _ctrl.loadMore();
              return false;
            },
            child: RefreshIndicator(
              color: c.primary,
              edgeOffset: kbHeader.minExtent,
              onRefresh: _ctrl.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Large title "المعرفة" that shrinks to a standard bar on scroll (Inbox
/// pattern), on the brand surface (BrandHeader) from the top of the screen.
/// The child fills the extent (SizedBox.expand) — a shorter child breaks the
/// sliver geometry.
class _KbAppBarDelegate extends SliverPersistentHeaderDelegate {
  _KbAppBarDelegate({required this.title, required this.actions, required this.textScale, this.topInset = 0});

  final String title;
  final List<Widget> actions;
  final double textScale;

  /// Status-bar height: the teal header paints under it.
  final double topInset;

  double get _scale => textScale.clamp(1.0, 2.0);

  @override
  double get minExtent => topInset + 60 * _scale;

  @override
  double get maxExtent => math.max(minExtent, topInset + 76 * _scale);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = context.text;
    final range = maxExtent - minExtent;
    final p = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    return SizedBox.expand(
      child: BrandHeader(
        safeTop: false,
        elevated: p > 0.5 || overlapsContent,
        padding: EdgeInsetsDirectional.fromSTEB(18, topInset + 4 * (1 - p), 8, AppSpacing.sm + 6 * (1 - p)),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle.lerp(t.h1, t.h4, p)!.copyWith(fontWeight: FontWeight.w800, color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }

  @override
  // Actions capture fresh callbacks / permissions on every build.
  bool shouldRebuild(_KbAppBarDelegate old) => true;
}
