import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../application/unanswered_controller.dart';
import '../../data/kb_api.dart';
import '../../domain/kb_entry.dart';
import 'kb_link_existing_sheet.dart';
import 'kb_unanswered_card.dart';

/// "أسئلة بلا إجابة" `/knowledge/unanswered` (Knowledge Base spec §6.4).
class KbUnansweredScreen extends ConsumerStatefulWidget {
  const KbUnansweredScreen({super.key});

  @override
  ConsumerState<KbUnansweredScreen> createState() => _KbUnansweredScreenState();
}

class _KbUnansweredScreenState extends ConsumerState<KbUnansweredScreen> {
  UnansweredController get _ctrl => ref.read(unansweredControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Re-open → fresh list (the provider stays alive with the KB tab).
    Future.microtask(_ctrl.refresh);
  }

  Future<void> _add(KbUnanswered u) async {
    Analytics.log('kb_unanswered_action', {'action': 'add', 'count': u.count});
    await context.push('/knowledge/new?fromQuestion=${Uri.encodeComponent(u.id)}');
  }

  Future<void> _link(KbUnanswered u) async {
    final l = context.l10n;
    final target = await showKbLinkExistingSheet(context);
    if (target == null || !mounted) return;
    Analytics.log('kb_unanswered_action', {'action': 'link', 'count': u.count});
    final qa = await _ctrl.linkTo(u.id, target.id);
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: qa == null ? l.kb_save_err : l.kb_linked(target.title),
      kind: qa == null ? SnackKind.error : SnackKind.success,
    );
  }

  void _ignore(KbUnanswered u) {
    Analytics.log('kb_unanswered_action', {'action': 'ignore', 'count': u.count});
    _ctrl.dismissWithUndo(u.id);
    AppSnackbar.undo(context, message: context.l10n.kb_ignored, onUndo: () => _ctrl.undoDismiss(u.id));
  }

  Future<void> _conversations(KbUnanswered u) async {
    final ids = u.conversationIds;
    if (ids.isEmpty) return;
    if (ids.length == 1) {
      context.push(Routes.chat(ids.first, readOnly: false));
      return;
    }
    final l = context.l10n;
    final picked = await AppBottomSheet.show<String>(
      context,
      title: l.kb_view_convs,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ids.length; i++)
            SheetActionRow(icon: AppIcons.conversation, label: '${u.question} · ${i + 1}', onTap: () => Navigator.of(ctx).pop(ids[i])),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
    if (picked != null && mounted) context.push(Routes.chat(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(unansweredControllerProvider);
    final canEdit = ref.watch(knowledgeControllerProvider.select((k) => k.permissions.canEdit));

    // A failed refresh keeps the cards; say so once (core/state/load_state.dart rule 3).
    ref.listen(unansweredControllerProvider.select((u) => u.loaded && u.error != null), (was, failed) {
      if (failed && was != true) AppSnackbar.show(context, message: l.kb_error, kind: SnackKind.error);
    });

    Widget body;
    if (!s.loaded && s.error != null) {
      final e = s.error;
      body = EmptyState(
        icon: e is KbApiException && e.isNetwork ? AppIcons.offline : AppIcons.error,
        title: l.kb_error,
        actionLabel: l.kb_retry,
        onAction: _ctrl.refresh,
      );
    } else if (!s.loaded) {
      body = AppSkeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (var i = 0; i < 4; i++) ...[
              const SkeletonBox(height: 120, radius: AppRadius.xl),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: _ctrl.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
                child: Text(l.kb_unanswered_info, style: t.caption.copyWith(color: c.textSecondary)),
              ),
            ),
            SliverToBoxAdapter(
              child: AppChipRow(
                children: [
                  AppFilterChip(
                    label: l.kb_sort_frequency,
                    selected: s.sort == UnansweredSort.frequency,
                    onTap: () => _ctrl.setSort(UnansweredSort.frequency),
                  ),
                  AppFilterChip(
                    label: l.kb_sort_newest,
                    selected: s.sort == UnansweredSort.recent,
                    onTap: () => _ctrl.setSort(UnansweredSort.recent),
                  ),
                ],
              ),
            ),
            if (s.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: AppIcons.resolve, title: l.kb_none_unanswered, body: l.kb_none_unanswered_body),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
                sliver: SliverList.separated(
                  itemCount: s.items.length + (s.nextCursor != null ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) {
                    if (i >= s.items.length) {
                      _ctrl.loadMore();
                      return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: AppSpinner()));
                    }
                    final u = s.items[i];
                    return KbUnansweredCard(
                      key: ValueKey(u.id),
                      item: u,
                      canEdit: canEdit,
                      onAdd: () => _add(u),
                      onLink: () => _link(u),
                      onIgnore: () => _ignore(u),
                      onViewConversations: () => _conversations(u),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.kb_unanswered,
        background: c.backgroundMuted,
        actions: [
          if (s.loaded && s.total > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: CountBadge(count: s.total, color: c.warning),
            ),
        ],
      ),
      body: SafeArea(top: false, child: SlidableAutoCloseBehavior(child: body)),
    );
  }
}
