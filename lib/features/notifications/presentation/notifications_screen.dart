import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart' show NetworkState;
import '../../../core/notifications/push_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../conversations/application/conversations_controller.dart';
import '../application/notifications_controller.dart';
import '../data/notifications_repository.dart';
import '../domain/day_grouping.dart';
import '../domain/notification.dart';
import '../domain/notification_type.dart';
import 'widgets/notification_day_group.dart';
import 'widgets/notification_inline_actions.dart';
import 'widgets/notification_skeleton.dart';
import 'widgets/notification_tile.dart';
import 'widgets/notifications_app_bar.dart';
import 'widgets/notifications_empty_state.dart';
import 'widgets/push_disabled_banner.dart';

/// الإشعارات (Notifications spec 09). Route `/notifications?filter=&highlight=`.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.filter, this.highlightId});

  final String? filter;
  final String? highlightId;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();
  bool _bannerHidden = false;
  bool _viewLogged = false;

  @override
  void initState() {
    super.initState();
    _bannerHidden = ref.read(notificationsRepositoryProvider).pushBannerHidden;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = ref.read(notificationsControllerProvider.notifier);
      final f = widget.filter;
      if (f != null && NotificationFilter.parse(f) != ref.read(notificationsControllerProvider).filter) {
        ctrl.setFilter(NotificationFilter.parse(f));
      } else {
        // Cached list is already on screen; refresh silently (§7).
        ctrl.refresh();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) ref.read(notificationsControllerProvider.notifier).loadMore();
  }

  NotificationsController get _ctrl => ref.read(notificationsControllerProvider.notifier);

  bool get _online =>
      ref.read(conversationsControllerProvider.select((s) => s.network)) == NetworkState.online;

  Future<void> _open(NotificationItem n) async {
    await _ctrl.setRead(n.id, read: true);
    if (!mounted) return;
    await NotificationOpener.open(context, ref, n, source: 'list');
  }

  Future<void> _readAll() async {
    final l = context.l10n;
    try {
      final undo = await _ctrl.readAll();
      if (!mounted || undo == null) return;
      AppSnackbar.show(context, message: l.ntf_read_all_done, kind: SnackKind.success, actionLabel: l.ntf_undo, onAction: undo);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.ntf_action_failed, kind: SnackKind.error);
    }
  }

  void _delete(NotificationItem n, {required bool fullSwipe}) {
    final l = context.l10n;
    final undo = _ctrl.delete(n.id);
    AppSnackbar.show(context, message: l.ntf_deleted, actionLabel: l.ntf_undo, onAction: undo);
  }

  Future<void> _deleteRead() async {
    try {
      await _ctrl.deleteRead();
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: context.l10n.ntf_action_failed, kind: SnackKind.error);
    }
  }

  Future<void> _menu(NotificationItem n) {
    final l = context.l10n;
    return AppBottomSheet.show<void>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(
            icon: n.isRead ? AppIcons.mailOpen : AppIcons.checkDouble,
            label: n.isRead ? l.ntf_mark_unread : l.ntf_mark_read,
            onTap: () {
              Navigator.of(ctx).pop();
              _ctrl.toggleRead(n.id);
            },
          ),
          SheetActionRow(
            icon: AppIcons.notificationsOff,
            label: l.ntf_mute_type,
            onTap: () {
              Navigator.of(ctx).pop();
              _ctrl.mute(n);
              AppSnackbar.show(context, message: l.ntf_muted);
            },
          ),
          SheetActionRow(
            icon: AppIcons.delete,
            label: l.ntf_delete,
            destructive: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _delete(n, fullSwipe: false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _enablePush() async {
    final status = await PushService.requestPermission();
    ref.read(pushPermissionProvider.notifier).state = status;
    if (mounted && status != PushPermission.granted) {
      AppSnackbar.show(context, message: context.l10n.ntf_push_unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(notificationsControllerProvider);
    final isAdmin = ref.watch(currentAgentProvider.select((a) => a.isAdmin));
    final network = ref.watch(conversationsControllerProvider.select((s) => s.network));
    final permission = ref.watch(pushPermissionProvider);
    final online = network == NetworkState.online;

    if (!_viewLogged && s.phase != NotificationsPhase.loading) {
      _viewLogged = true;
      Analytics.log('ntf_view', {'filter': s.filter.name, 'unread_count': s.unreadCount});
    }

    // Billing rows are owner/admin only (§5).
    final visible = [
      for (final n in s.items)
        if (isAdmin || !n.type.isBilling) n,
    ];
    final days = groupByDay(stackNotifications(visible), DateTime.now());
    final unread = s.unreadCount > 0 || visible.any((n) => !n.isRead);

    Widget body;
    if (s.phase == NotificationsPhase.loading && visible.isEmpty) {
      body = ListView(physics: const NeverScrollableScrollPhysics(), children: const [NotificationSkeleton()]);
    } else if (visible.isEmpty) {
      final kind = s.phase == NotificationsPhase.error
          ? NotificationsEmptyKind.error
          : (s.filter == NotificationFilter.all ? NotificationsEmptyKind.all : NotificationsEmptyKind.filter);
      body = LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Center(
              child: NotificationsEmptyState(
                kind: kind,
                filter: s.filter,
                onShowAll: () => _ctrl.setFilter(NotificationFilter.all),
                onRetry: _ctrl.retry,
              ),
            ),
          ),
        ),
      );
    } else {
      body = SlidableAutoCloseBehavior(
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            for (var d = 0; d < days.length; d++) ...[
              SliverToBoxAdapter(child: NotificationDayHeader(label: days[d].$1.label(l), first: d == 0)),
              SliverToBoxAdapter(
                child: NotificationGroupCard(
                  children: [
                    for (final g in days[d].$2)
                      _Appear(
                        key: ValueKey('ntf-${g.head.id}'),
                        animate: s.inserted.contains(g.head.id),
                        child: NotificationTile(
                          group: g,
                          rows: s.rows,
                          expanded: s.expanded.contains(g.head.id),
                          highlighted: widget.highlightId != null && g.items.any((i) => i.id == widget.highlightId),
                          online: online,
                          onTap: _open,
                          onAction: (n, id) => handleNotificationAction(context, ref, n, id, online: _online),
                          onToggleRead: (n) => _ctrl.toggleRead(n.id),
                          onDelete: _delete,
                          onLongPress: _menu,
                          onToggleExpand: () => _ctrl.toggleExpanded(g.head.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: _Footer(
                loading: s.loadingMore,
                failed: s.loadMoreFailed,
                end: !s.hasMore,
                onRetry: _ctrl.loadMore,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NotificationsAppBar(
              canReadAll: unread,
              onReadAll: _readAll,
              onSettings: () => context.push(Routes.notificationSettings),
              onDeleteRead: _deleteRead,
              filter: s.filter,
              onFilter: _ctrl.setFilter,
            ),
            if (permission != PushPermission.granted && !_bannerHidden)
              PushDisabledBanner(
                onEnable: _enablePush,
                onDismiss: () {
                  setState(() => _bannerHidden = true);
                  ref.read(notificationsRepositoryProvider).hidePushBanner();
                },
              ),
            ConnectionBanner(state: network),
            Expanded(
              child: RefreshIndicator(
                color: c.primary,
                backgroundColor: c.surface,
                onRefresh: _ctrl.refresh,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Realtime insert: size + fade 200ms (§14).
class _Appear extends StatefulWidget {
  const _Appear({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _c.forward() : null);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    final curve = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    return SizeTransition(sizeFactor: curve, child: FadeTransition(opacity: curve, child: widget.child));
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.loading, required this.failed, required this.end, required this.onRetry});

  final bool loading;
  final bool failed;
  final bool end;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final bottom = AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom;
    Widget child;
    if (loading) {
      child = const Center(child: AppSpinner());
    } else if (failed) {
      child = Center(child: TextButton(onPressed: onRetry, child: Text(l.ntf_retry)));
    } else if (end) {
      child = Column(
        children: [
          Text(l.ntf_end, style: t.caption.copyWith(color: c.textTertiary)),
          const SizedBox(height: AppSpacing.xs),
          Text(l.ntf_retention, style: t.caption.copyWith(color: c.textTertiary, fontWeight: FontWeight.w500)),
        ],
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: EdgeInsets.only(top: AppSpacing.lg, bottom: bottom), child: child);
  }
}
