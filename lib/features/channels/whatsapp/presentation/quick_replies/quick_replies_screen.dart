import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/quick_replies_controller.dart';
import '../../data/quick_replies_api.dart';

/// Team scope is edited by admins / supervisors only (server rule).
bool canEditTeamReplies(Agent me) => me.role == AgentRole.admin || me.role == AgentRole.supervisor;

/// `/settings/whatsapp/quick-replies` (WhatsApp spec §5.4).
class QuickRepliesScreen extends ConsumerStatefulWidget {
  const QuickRepliesScreen({super.key});

  @override
  ConsumerState<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends ConsumerState<QuickRepliesScreen> {
  QuickReplyScope _scope = QuickReplyScope.team;
  String _q = '';

  bool _rowEditable(WaQuickReply r, Agent me) => r.canEdit && (r.scope == QuickReplyScope.mine || canEditTeamReplies(me));

  Future<bool> _confirmDelete(WaQuickReply r) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.wa_qr_delete_title(r.title),
      body: l.wa_qr_delete_body,
      confirmLabel: l.wa_delete,
      icon: AppIcons.delete,
    );
    if (!ok || !mounted) return false;
    final done = await ref.read(quickRepliesControllerProvider.notifier).delete(r.id);
    if (!mounted) return done;
    AppSnackbar.show(context, message: done ? l.wa_qr_deleted : l.wa_qr_delete_failed, kind: done ? SnackKind.success : SnackKind.error);
    return done;
  }

  void _open(String id) => context.push(Routes.whatsappQuickReply(id, scope: _scope));

  @override
  void initState() {
    super.initState();
    // The provider outlives the screen: show the kept rows, refresh quietly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(quickRepliesControllerProvider).loaded) ref.read(quickRepliesControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() async {
    await ref.read(quickRepliesControllerProvider.notifier).load();
    if (mounted && ref.read(quickRepliesControllerProvider).error != null) {
      AppSnackbar.show(context, message: context.l10n.wa_load_error, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final state = ref.watch(quickRepliesControllerProvider);
    final me = ref.watch(currentAgentProvider);
    final term = _q.trim().toLowerCase();
    final all = state.of(_scope);
    final rows = term.isEmpty
        ? all
        : [
            for (final r in all)
              if (r.title.toLowerCase().contains(term) || r.shortcut.contains(term.replaceFirst('/', '')) || r.text.toLowerCase().contains(term)) r,
          ];
    final canAdd = _scope == QuickReplyScope.mine || canEditTeamReplies(me);
    // Reorder only on the full list, and only when every row is editable.
    final reorderable = term.isEmpty && canAdd;

    Widget list;
    if (state.loading && !state.loaded) {
      list = AppSkeleton.list(rows: 6);
    } else if (state.error != null && !state.loaded) {
      list = EmptyState(icon: AppIcons.alert, title: l.wa_load_error, actionLabel: l.wa_retry, onAction: ref.read(quickRepliesControllerProvider.notifier).load);
    } else if (rows.isEmpty) {
      list = EmptyState(
        icon: AppIcons.send,
        title: term.isEmpty ? l.wa_qr_empty : l.wa_qr_no_results,
        body: term.isEmpty ? l.wa_qr_empty_body : null,
        actionLabel: term.isEmpty && canAdd ? l.wa_qr_add : null,
        onAction: term.isEmpty && canAdd ? () => _open('new') : null,
      );
    } else {
      list = ReorderableListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
        itemCount: rows.length,
        onReorder: (from, to) async {
          if (!reorderable) return;
          final ok = await ref.read(quickRepliesControllerProvider.notifier).reorder(_scope, from, to > from ? to - 1 : to);
          if (!ok && context.mounted) AppSnackbar.show(context, message: l.wa_qr_reorder_failed, kind: SnackKind.error);
        },
        proxyDecorator: (child, _, _) => Material(color: Colors.transparent, elevation: 6, borderRadius: BorderRadius.circular(AppRadius.xl), child: child),
        itemBuilder: (context, i) {
          final r = rows[i];
          final editable = _rowEditable(r, me);
          Widget tile = _QuickReplyTile(reply: r, onTap: () => _open(r.id));
          if (editable) {
            tile = Dismissible(
              key: ValueKey('d_${r.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(r),
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(color: c.error, borderRadius: BorderRadius.circular(AppRadius.xl)),
                child: Icon(AppIcons.delete, color: c.onPrimary),
              ),
              child: tile,
            );
          }
          return Padding(
            key: ValueKey(r.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: reorderable ? ReorderableDelayedDragStartListener(index: i, child: tile) : tile,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.wa_quick,
        background: c.backgroundMuted,
        actions: [
          if (canAdd)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: AppIconButton(
                icon: AppIcons.plus,
                variant: AppIconButtonVariant.primary,
                size: 40,
                semanticLabel: l.wa_qr_new,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _open('new');
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: AppSegmented<QuickReplyScope>(
              segments: [
                AppSegment(value: QuickReplyScope.team, label: l.wa_qr_team, count: state.of(QuickReplyScope.team).length),
                AppSegment(value: QuickReplyScope.mine, label: l.wa_qr_mine, count: state.of(QuickReplyScope.mine).length),
              ],
              selected: _scope,
              onChanged: (s) => setState(() => _scope = s),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: AppSearchField(hint: l.wa_qr_search, showCancel: false, onChanged: (v) => setState(() => _q = v)),
          ),
          if (_scope == QuickReplyScope.team && !canEditTeamReplies(me))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
              child: Text(l.wa_qr_readonly, style: context.text.caption.copyWith(color: c.textTertiary)),
            ),
          // Pull to refresh once the first load is done (skeleton / error before).
          Expanded(child: state.loaded ? RefreshIndicator(color: c.primary, onRefresh: _refresh, child: list) : list),
        ],
      ),
    );
  }
}

class _QuickReplyTile extends StatelessWidget {
  const _QuickReplyTile({required this.reply, required this.onTap});

  final WaQuickReply reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final r = reply;
    return Semantics(
      button: true,
      label: '/${r.shortcut}، ${r.title}',
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl), side: BorderSide(color: c.border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: Text(
                        '/${r.shortcut}',
                        textDirection: TextDirection.ltr,
                        style: t.caption.copyWith(fontFamily: 'monospace', color: c.textSecondary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(r.title, style: t.listTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (r.usageCount > 0) Text(l.wa_qr_used('${r.usageCount}'), style: t.caption.copyWith(color: c.textTertiary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(r.text, style: t.bodySmall.copyWith(color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
