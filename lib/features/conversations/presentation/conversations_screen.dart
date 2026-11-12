import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../channels/whatsapp/application/whatsapp_channel_controller.dart';
import '../../channels/whatsapp/domain/wa_status.dart';
import '../application/conversation_filters_controller.dart';
import '../application/conversations_controller.dart';
import '../application/relative_time_ticker.dart';
import '../data/conversations_repository.dart';
import '../data/conversations_socket.dart';
import '../domain/conversation_filters.dart';
import '../domain/conversation_summary.dart';
import 'inbox_actions.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/conversation_tile.dart';
import 'widgets/conversation_tile_skeleton.dart';
import 'widgets/conversations_empty_state.dart';
import 'widgets/filters_sheet.dart';
import 'widgets/inbox_filter_bar.dart';
import 'widgets/inbox_header.dart';
import 'widgets/inbox_palette.dart';
import 'widgets/new_message_sheet.dart';
import 'widgets/new_messages_pill.dart';

/// صندوق الوارد — Inbox v2: fixed teal header + fixed pill filter bar over
/// the conversation list.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key, this.segment, this.filter, this.selectedConversationId});

  /// Deep-link `?segment=mine|unassigned|all`.
  final String? segment;

  /// Deep-link `&filter=<chipId>`.
  final String? filter;

  /// Two-pane (≥ 840dp, future): highlights the conversation open beside the list.
  final String? selectedConversationId;

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> with WidgetsBindingObserver {
  static const _maxSelected = 50;

  final _scroll = ScrollController();
  StreamSubscription<InboxSocketEvent>? _socketSub;

  int _pill = 0;
  DateTime? _lastBack;
  int? _matching;

  /// Previous pill's rows, kept dimmed until the new ones arrive (§4.2.1).
  List<ConversationSummary>? _stale;
  bool _switching = false;

  /// Rows removed since the last frame, kept briefly to animate out.
  final Map<String, ({ConversationSummary item, int index})> _leaving = {};

  /// Rows that just arrived or moved up — slide in + highlight.
  Set<String> _appearing = {};

  /// Full-swipe dismissals already animated by the Slidable.
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(conversationFiltersProvider.notifier).applyDeepLink(segment: widget.segment, filter: widget.filter);
      _socketSub = ref.read(conversationsSocketProvider).events.listen(_onSocketEvent);
      _refreshMatching(ref.read(conversationFiltersProvider));
    });
  }

  @override
  void didUpdateWidget(ConversationsScreen old) {
    super.didUpdateWidget(old);
    if (old.segment != widget.segment || old.filter != widget.filter) {
      ref.read(conversationFiltersProvider.notifier).applyDeepLink(segment: widget.segment, filter: widget.filter);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume: recompute relative times / waiting tags immediately.
    if (state == AppLifecycleState.resumed) ref.read(inboxClockProvider.notifier).tick();
  }

  // ---- Scroll ---------------------------------------------------------------------

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    // Next page 600dp before the end (§5.1).
    if (p.maxScrollExtent - p.pixels < 600) ref.read(conversationsControllerProvider.notifier).loadMore();
    if (_pill > 0 && p.pixels <= 0) setState(() => _pill = 0);
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    if (AppMotion.reduced(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: AppMotion.slow, curve: AppMotion.standard);
    }
  }

  // ---- Real-time ------------------------------------------------------------------

  void _onSocketEvent(InboxSocketEvent e) {
    if (!mounted) return;
    final l = context.l10n;
    switch (e) {
      case InboxAssignedToMe(:final conversationId, :final byName):
        final message = l.inbox_assigned_to_you(byName);
        SemanticsService.announce(message, Directionality.of(context));
        AppSnackbar.show(
          context,
          message: message,
          actionLabel: l.inbox_open,
          onAction: () => context.push(Routes.chat(conversationId)),
        );
      case InboxInboundMessage(:final assignedToMe):
        if (assignedToMe) HapticFeedback.lightImpact();
      case InboxClaimedByColleague() || InboxNewConversation() || InboxRefreshNeeded():
        break;
    }
  }

  void _afterBuild(VoidCallback fn) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) fn();
      });
    } else {
      fn();
    }
  }

  void _onItemsChanged(ConversationsState? prev, ConversationsState next) {
    if (prev == null) return;
    if (prev.query != next.query) {
      // Pill / filter switch: keep the old rows dimmed until results arrive.
      setState(() {
        _stale = prev.items.isNotEmpty ? prev.items : _stale;
        _switching = true;
      });
      return;
    }
    if (_switching && next.phase != InboxLoadPhase.loading && !next.fromCache) {
      setState(() {
        _switching = false;
        _stale = null;
      });
    }

    final before = prev.items;
    final reduced = AppMotion.reduced(context);
    final nextIds = {for (final i in next.items) i.id};

    // Scrolled down more than 2 screens: don't move the list, show the
    // "{n} رسائل جديدة" pill instead (§5.2).
    if (next.inserted.isNotEmpty && _scroll.hasClients && _scroll.offset > 2 * _scroll.position.viewportDimension) {
      setState(() => _pill += next.inserted.length);
      return;
    }
    if (reduced) return;

    final oldIndex = {for (var i = 0; i < before.length; i++) before[i].id: i};
    final appearing = <String>{
      ...next.inserted,
      for (var i = 0; i < next.items.length; i++)
        if ((oldIndex[next.items[i].id] ?? i) > i) next.items[i].id, // moved up
    };
    final leaving = <String, ({ConversationSummary item, int index})>{
      for (var i = 0; i < before.length; i++)
        if (!nextIds.contains(before[i].id) && !_dismissed.remove(before[i].id)) before[i].id: (item: before[i], index: i),
    };
    if (appearing.isEmpty && leaving.isEmpty) return;
    setState(() {
      _appearing = appearing;
      _leaving.addAll(leaving);
    });
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        for (final id in leaving.keys) {
          _leaving.remove(id);
        }
      });
    });
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _appearing = {});
    });
  }

  void _onQueryChanged(InboxQuery? prev, InboxQuery next) {
    if (prev == null) return;
    if (prev.segment != next.segment || prev.chip != next.chip) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _leaving.clear();
      _pill = 0;
    }
    if (prev.advanced != next.advanced || prev.segment != next.segment || prev.chip != next.chip) {
      _refreshMatching(next);
    }
  }

  /// Header subtitle "{n} محادثة مطابقة" while advanced filters are on.
  Future<void> _refreshMatching(InboxQuery q) async {
    if (!q.advanced.hasActive) {
      if (_matching != null) setState(() => _matching = null);
      return;
    }
    try {
      final n = await ref.read(conversationsRepositoryProvider).count(q);
      if (mounted && ref.read(conversationFiltersProvider) == q) setState(() => _matching = n);
    } catch (_) {
      // Keep the subtitle as it was.
    }
  }

  // ---- Back ----------------------------------------------------------------------

  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    final ctrl = ref.read(conversationsControllerProvider.notifier);
    if (ref.read(inboxProvider).selecting) {
      ctrl.clearSelection();
      return;
    }
    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    AppSnackbar.show(context, message: context.l10n.inbox_exit_hint);
  }

  // ---- Rows -----------------------------------------------------------------------

  void _open(ConversationSummary s, int position, InboxPill pill) {
    Analytics.log('inbox_open_conversation', {'pill': pill.name, 'position': position, 'channel': s.channel.name});
    ref.read(conversationsControllerProvider.notifier).markReadOptimistic(s.id);
    context.push(Routes.chat(s.id));
  }

  void _toggle(String id, Set<String> selected) {
    if (!selected.contains(id) && selected.length >= _maxSelected) {
      HapticFeedback.heavyImpact();
      return;
    }
    ref.read(conversationsControllerProvider.notifier).toggleSelected(id);
  }

  Widget _tile(
    ConversationSummary s,
    int position, {
    required InboxPill pill,
    required Set<String> selected,
    required bool showDivider,
  }) {
    final selecting = selected.isNotEmpty;
    final tile = ConversationTile(
      key: ValueKey(s.id),
      summary: s,
      allPill: pill == InboxPill.all,
      showDivider: showDivider,
      selected: selected.contains(s.id) || (!selecting && widget.selectedConversationId == s.id),
      selecting: selecting,
      onTap: () => selecting ? _toggle(s.id, selected) : _open(s, position, pill),
      onLongPress: selecting ? null : () => _toggle(s.id, selected),
      onClaim: ({required fullSwipe}) => InboxActions.claim(context, ref, s.id),
      onAssign: ({required fullSwipe}) => InboxActions.assign(context, ref, {s.id}),
      onClose: ({required fullSwipe}) {
        if (fullSwipe) _dismissed.add(s.id);
        InboxActions.resolve(context, ref, {s.id}, fullSwipe: fullSwipe);
      },
      onReopen: ({required fullSwipe}) => InboxActions.reopen(context, ref, {s.id}),
      onToggleRead: ({required fullSwipe}) => InboxActions.setRead(context, ref, {s.id}, read: s.isUnread),
    );
    if (AppMotion.reduced(context)) return tile;
    if (_leaving.containsKey(s.id)) {
      return _RowTransition(key: ValueKey('leave-${s.id}'), leaving: true, child: IgnorePointer(child: tile));
    }
    if (_appearing.contains(s.id)) return _RowTransition(key: ValueKey('in-${s.id}'), child: tile);
    return tile;
  }

  /// Merges rows that are animating out back in at their old position.
  List<ConversationSummary> _withLeaving(List<ConversationSummary> items) {
    if (_leaving.isEmpty) return items;
    final list = [...items];
    final ghosts = _leaving.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    for (final g in ghosts) {
      if (list.any((i) => i.id == g.item.id)) continue;
      list.insert(g.index.clamp(0, list.length), g.item);
    }
    return list;
  }

  InboxEmptyKind _emptyKind(ConversationsState s, InboxQuery q) {
    if (s.phase == InboxLoadPhase.error) return InboxEmptyKind.error;
    if (q.advanced.hasActive) return InboxEmptyKind.filtered;
    return switch (InboxPill.of(q)) {
      InboxPill.all => InboxEmptyKind.none,
      InboxPill.mine => InboxEmptyKind.mine,
      InboxPill.unread => InboxEmptyKind.unread,
      InboxPill.unassigned => InboxEmptyKind.unassigned,
      InboxPill.waiting => InboxEmptyKind.waiting,
      InboxPill.ai => InboxEmptyKind.ai,
      InboxPill.closed => InboxEmptyKind.closed,
    };
  }

  void _emptyAction(InboxEmptyKind kind) {
    final filters = ref.read(conversationFiltersProvider.notifier);
    switch (kind) {
      case InboxEmptyKind.mine:
        filters.setPill(InboxPill.unassigned);
      case InboxEmptyKind.none:
        context.push(Routes.whatsapp);
      case InboxEmptyKind.filtered:
        filters.setAdvanced(AdvancedFilters.empty);
      case InboxEmptyKind.error:
        ref.read(conversationsControllerProvider.notifier).retry();
      default:
        break;
    }
  }

  // ---- Selection ------------------------------------------------------------------

  Future<void> _bulk(String action, Future<void> Function(Set<String>) run) async {
    final ids = {...ref.read(inboxProvider).selected};
    if (ids.isEmpty) return;
    Analytics.log('inbox_bulk_action', {'action': action, 'count': ids.length});
    await run(ids);
    ref.read(conversationsControllerProvider.notifier).clearSelection();
  }

  void _moreActions() {
    final l = context.l10n;
    AppBottomSheet.show<void>(
      context,
      builder: (ctx) => Column(
        children: [
          SheetActionRow(
            icon: AppIcons.snooze,
            label: l.inbox_swipe_snooze,
            onTap: () {
              Navigator.pop(ctx);
              _bulk('snooze', (s) => InboxActions.pickSnooze(context, ref, s));
            },
          ),
          SheetActionRow(
            icon: AppIcons.tag,
            label: l.inbox_tag,
            onTap: () {
              Navigator.pop(ctx);
              _bulk('tag', (s) => InboxActions.pickTag(context, ref, s));
            },
          ),
          SheetActionRow(
            icon: AppIcons.priority,
            label: l.inbox_priority,
            onTap: () {
              Navigator.pop(ctx);
              _bulk('priority', (s) => InboxActions.pickPriority(context, ref, s));
            },
          ),
          SheetActionRow(
            icon: AppIcons.archive,
            label: l.inbox_archive,
            onTap: () {
              Navigator.pop(ctx);
              _bulk('archive', (s) => InboxActions.archive(context, ref, s));
            },
          ),
        ],
      ),
    );
  }

  // ---- Build ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final p = InboxPalette.of(context);
    // Provider changes can land while a frame is building (e.g. a pushed
    // route updating the inbox); setState then would dirty rows mid-build
    // and corrupt the list. Run those callbacks after the frame instead.
    ref.listen(conversationsControllerProvider, (a, b) => _afterBuild(() => _onItemsChanged(a, b)));
    ref.listen(conversationFiltersProvider, (a, b) => _afterBuild(() => _onQueryChanged(a, b)));

    final s = ref.watch(conversationsControllerProvider);
    final q = ref.watch(conversationFiltersProvider);
    final pill = InboxPill.of(q);
    final selected = ref.watch(inboxProvider.select((x) => x.selected));
    final selecting = selected.isNotEmpty;
    final unreadNotifications = ref.watch(unreadNotificationsProvider);
    final wa = ref.watch(whatsAppChannelControllerProvider.select((x) => x.channel));
    final waDown = wa != null && wa.status == WaStatus.disconnected;
    final ctrl = ref.read(conversationsControllerProvider.notifier);
    final filters = ref.read(conversationFiltersProvider.notifier);

    // Rows: the new pill's rows, or the previous pill's (dimmed) meanwhile.
    final fresh = s.items.isNotEmpty || s.phase != InboxLoadPhase.loading;
    final rows = _withLeaving(fresh ? s.items : (_stale ?? const []));
    final loadingOver = _switching && (s.phase == InboxLoadPhase.loading || s.fromCache) && rows.isNotEmpty;

    final content = <Widget>[];
    if (waDown) {
      content.add(SliverToBoxAdapter(child: _WhatsAppDownCard(onReconnect: () => context.push(Routes.whatsapp))));
    }
    if (rows.isEmpty && s.phase == InboxLoadPhase.loading) {
      content.add(SliverToBoxAdapter(child: ConversationTileSkeleton.list()));
    } else if (rows.isEmpty && _leaving.isEmpty) {
      final kind = _emptyKind(s, q);
      content.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: ConversationsEmptyState(
            kind: kind,
            canConnect: wa == null || !wa.status.isHealthy,
            onAction: () => _emptyAction(kind),
          ),
        ),
      );
    } else {
      content
        ..add(
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) => _tile(rows[i], i, pill: pill, selected: selected, showDivider: i > 0),
          ),
        )
        ..add(SliverToBoxAdapter(child: _PaginationFooter(state: s, onRetry: ctrl.loadMore)));
    }

    // Under `extendBody` the shell reports the real tab-bar height as bottom
    // padding; keep the last row above it.
    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      AppTabBar.height + MediaQuery.viewPaddingOf(context).bottom,
    );

    final list = RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      displacement: 24,
      onRefresh: ctrl.refresh,
      // Opening one row's swipe actions closes the others.
      child: SlidableAutoCloseBehavior(
        child: AnimatedOpacity(
          opacity: loadingOver ? 0.6 : 1,
          duration: AppMotion.fast,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              ...content,
              SliverToBoxAdapter(child: SizedBox(height: bottomInset + AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );

    Widget disabledWhileSelecting(Widget child) => IgnorePointer(
          ignoring: selecting,
          child: AnimatedOpacity(opacity: selecting ? 0.4 : 1, duration: AppMotion.fast, child: child),
        );

    final anyUnread = s.items.any((i) => selected.contains(i.id) && i.isUnread);
    final header = selecting
        ? InboxSelectionBar(
            key: const ValueKey('select'),
            count: selected.length,
            anyUnread: anyUnread,
            onExit: ctrl.clearSelection,
            onClaim: () => _bulk('claim', (ids) => InboxActions.claimMany(context, ref, ids)),
            onAssign: () => _bulk('assign', (ids) => InboxActions.assign(context, ref, ids)),
            onClose: () => _bulk('resolve', (ids) => InboxActions.resolve(context, ref, ids)),
            onRead: () => _bulk('read', (ids) => InboxActions.setRead(context, ref, ids, read: anyUnread)),
            onMore: _moreActions,
          )
        : InboxHeader(
            key: const ValueKey('header'),
            matching: q.advanced.hasActive ? _matching : null,
            unreadNotifications: unreadNotifications,
            onSearch: () => context.push(Routes.search),
            onBell: () => context.push(Routes.notifications),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        backgroundColor: p.list,
        body: Column(
          children: [
            AnimatedSwitcher(duration: AppMotion.fast, child: header),
            disabledWhileSelecting(
              InboxFilterBar(
                pill: pill,
                counts: s.counts,
                advancedCount: q.advanced.activeCount,
                onPill: filters.setPill,
                onFilters: () => showInboxFiltersSheet(context, ref),
              ),
            ),
            if (q.advanced.hasActive)
              disabledWhileSelecting(
                ActiveFiltersBar(filters: q.advanced, onChanged: filters.setAdvanced, onClearAll: filters.clearAll),
              ),
            if (s.network != NetworkState.online)
              Container(
                width: double.infinity,
                color: c.warningContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  l.inbox_offline_bar,
                  textAlign: TextAlign.center,
                  style: context.text.caption.copyWith(fontWeight: FontWeight.w600, color: c.textWarning),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  // Tablets: content max 720dp, centered.
                  Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: list)),
                  if (loadingOver)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 2, color: InboxPalette.headerStart, backgroundColor: Colors.transparent),
                    ),
                  if (!selecting)
                    PositionedDirectional(
                      end: AppSpacing.lg,
                      bottom: bottomInset + AppSpacing.lg,
                      child: AppFab(
                        icon: AppIcons.compose,
                        semanticLabel: l.inbox_new_conversation,
                        onPressed: () => showNewMessageSheet(context, ref),
                      ),
                    ),
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: 0,
                    end: 0,
                    child: Center(
                      child: NewMessagesPill(
                        count: _pill,
                        onTap: () {
                          Analytics.log('inbox_new_pill_tap', {'count': _pill});
                          setState(() => _pill = 0);
                          _scrollToTop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red card above the list while WhatsApp is disconnected (§7).
class _WhatsAppDownCard extends StatelessWidget {
  const _WhatsAppDownCard({required this.onReconnect});

  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = InboxPalette.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: p.waitBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.waitFg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.warning, dp: 18, color: p.waitFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.inbox_wa_down,
              style: context.text.bodySmall.copyWith(fontWeight: FontWeight.w700, color: p.waitFg),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.waitFg, textStyle: context.text.buttonSmall, minimumSize: const Size(48, 40)),
            onPressed: onReconnect,
            child: Text(l.inbox_wa_reconnect),
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state, required this.onRetry});

  final ConversationsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: AppSpinner(size: 20, delayed: false)),
      );
    }
    if (state.pageError) {
      return Center(
        child: TextButton(
          style: TextButton.styleFrom(foregroundColor: c.textError, textStyle: context.text.buttonSmall),
          onPressed: onRetry,
          child: Text(l.inbox_load_error),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.sm);
  }
}

/// Row insert / remove: size + fade 250ms; a new row also flashes a soft
/// teal highlight that fades out over 1.5 s (§5.2).
class _RowTransition extends StatefulWidget {
  const _RowTransition({super.key, required this.child, this.leaving = false});

  final Widget child;
  final bool leaving;

  @override
  State<_RowTransition> createState() => _RowTransitionState();
}

class _RowTransitionState extends State<_RowTransition> with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.leaving ? 1 : 0,
  );
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final Animation<double> _curve = CurvedAnimation(parent: _ctrl, curve: AppMotion.standard);

  @override
  void initState() {
    super.initState();
    if (widget.leaving) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
      _glow.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = InboxPalette.of(context);
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _curve,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) => ColoredBox(
            color: widget.leaving ? Colors.transparent : Color.lerp(p.suggestBg, Colors.transparent, _glow.value)!,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
