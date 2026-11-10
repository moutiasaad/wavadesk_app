import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
import '../application/conversation_filters_controller.dart';
import '../application/conversations_controller.dart';
import '../application/relative_time_ticker.dart';
import '../data/conversations_socket.dart';
import '../domain/conversation_filters.dart';
import '../domain/conversation_summary.dart';
import '../domain/row_tag_resolver.dart';
import 'inbox_actions.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/conversation_tile.dart';
import 'widgets/conversation_tile_skeleton.dart';
import 'widgets/conversations_app_bar.dart';
import 'widgets/conversations_empty_state.dart';
import 'widgets/filters_sheet.dart';
import 'widgets/inbox_segmented.dart';
import 'widgets/needs_reply_section.dart';
import 'widgets/new_message_sheet.dart';
import 'widgets/new_messages_pill.dart';
import 'widgets/quick_filter_chips.dart';

/// صندوق الوارد — implements `02 Inbox Screen.md` on the Design System.
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

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scroll = ScrollController();
  late final AnimationController _fade = AnimationController(vsync: this, duration: AppMotion.fast, value: 1);
  StreamSubscription<InboxSocketEvent>? _socketSub;

  bool _fabVisible = true;
  int _pill = 0;
  bool _needsExpanded = false;
  DateTime? _lastBack;

  /// Rows removed since the last frame, kept briefly to animate out.
  final Map<String, ({ConversationSummary item, int index})> _leaving = {};

  /// Rows that just arrived or moved up — animate in.
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
    _fade.dispose();
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
    if (p.pixels >= p.maxScrollExtent * 0.8) {
      ref.read(conversationsControllerProvider.notifier).loadMore();
    }
    if (_pill > 0 && p.pixels <= 0) setState(() => _pill = 0);
  }

  bool _onScrollNotification(UserScrollNotification n) {
    final visible = switch (n.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _fabVisible,
    };
    if (visible != _fabVisible) setState(() => _fabVisible = visible);
    return false;
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
        // Only assignments are announced to screen readers (§9).
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
    if (prev == null || prev.query != next.query) return;
    final before = prev.items;
    final reduced = AppMotion.reduced(context);
    final nextIds = {for (final i in next.items) i.id};

    // New rows while the agent is scrolled down > 1 screen → pill (§5).
    if (next.inserted.isNotEmpty && _scroll.hasClients && _scroll.offset > _scroll.position.viewportDimension) {
      setState(() => _pill += next.inserted.length);
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
        if (!nextIds.contains(before[i].id) && !_dismissed.remove(before[i].id))
          before[i].id: (item: before[i], index: i),
    };
    if (appearing.isEmpty && leaving.isEmpty) return;
    setState(() {
      _appearing = appearing;
      _leaving.addAll(leaving);
    });
    Future<void>.delayed(AppMotion.normal, () {
      if (!mounted) return;
      setState(() {
        for (final id in leaving.keys) {
          _leaving.remove(id);
        }
        _appearing = {};
      });
    });
  }

  void _onQueryChanged(InboxQuery? prev, InboxQuery next) {
    if (prev == null) return;
    if (prev.segment != next.segment || prev.chip != next.chip) {
      // Segment / chip switch: scroll to top + list cross-fade (§4.2).
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _leaving.clear();
      _pill = 0;
      if (!AppMotion.reduced(context)) _fade.forward(from: 0);
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

  void _open(ConversationSummary s, int position, InboxQuery q, DateTime now, String meId) {
    final tag = RowTagResolver.resolve(s, segment: q.segment, meId: meId, now: now);
    Analytics.log('inbox_open_conversation', {
      'segment': q.segment.name,
      'position': position,
      'had_tag': tag != null,
      'channel': s.channel.name,
    });
    ref.read(conversationsControllerProvider.notifier).markReadOptimistic(s.id);
    context.push(Routes.chat(s.id));
  }

  Widget _tile(
    ConversationSummary s,
    int position, {
    required InboxQuery q,
    required Set<String> selected,
    required DateTime now,
    required String meId,
    required bool showDivider,
  }) {
    final ctrl = ref.read(conversationsControllerProvider.notifier);
    final selecting = selected.isNotEmpty;
    final tile = ConversationTile(
      key: ValueKey(s.id),
      summary: s,
      segment: q.segment,
      showDivider: showDivider,
      selected: selected.contains(s.id) || (!selecting && widget.selectedConversationId == s.id),
      selecting: selecting,
      onTap: () => selecting ? ctrl.toggleSelected(s.id) : _open(s, position, q, now, meId),
      onLongPress: selecting ? null : () => ctrl.toggleSelected(s.id),
      onResolve: ({required fullSwipe}) {
        if (fullSwipe) _dismissed.add(s.id);
        InboxActions.resolve(context, ref, {s.id}, fullSwipe: fullSwipe);
      },
      onSnooze: ({required fullSwipe}) {
        if (fullSwipe) _dismissed.add(s.id);
        InboxActions.snooze(context, ref, {s.id}, fullSwipe: fullSwipe);
      },
      onAssign: ({required fullSwipe}) => InboxActions.assign(context, ref, {s.id}),
      onClaim: ({required fullSwipe}) => InboxActions.claim(context, ref, s.id),
    );
    if (AppMotion.reduced(context)) return tile;
    if (_leaving.containsKey(s.id)) {
      return _RowTransition(
        key: ValueKey('leave-${s.id}'),
        leaving: true,
        child: IgnorePointer(child: tile),
      );
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

  InboxEmptyKind _emptyKind(ConversationsState s, InboxQuery q, bool anyMine) {
    if (s.phase == InboxLoadPhase.error) return InboxEmptyKind.error;
    if (q.chip != QuickChip.all || q.advanced.hasActive) return InboxEmptyKind.noMatch;
    return switch (q.segment) {
      InboxSegment.mine => anyMine ? InboxEmptyKind.mineDone : InboxEmptyKind.mineNone,
      InboxSegment.unassigned => InboxEmptyKind.unassigned,
      InboxSegment.all => InboxEmptyKind.newWorkspace,
    };
  }

  void _emptyAction(InboxEmptyKind kind) {
    switch (kind) {
      case InboxEmptyKind.mineNone:
        ref.read(conversationFiltersProvider.notifier).setSegment(InboxSegment.unassigned);
      case InboxEmptyKind.newWorkspace:
        context.push(Routes.whatsapp);
      case InboxEmptyKind.noMatch:
        ref.read(conversationFiltersProvider.notifier).clearAll();
      case InboxEmptyKind.error:
        ref.read(conversationsControllerProvider.notifier).retry();
      case InboxEmptyKind.mineDone || InboxEmptyKind.unassigned:
        break;
    }
  }

  // ---- Build ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    // Provider changes can land while a frame is building (e.g. a pushed
    // route updating the inbox); setState then would dirty rows mid-build
    // and corrupt the list. Run those callbacks after the frame instead.
    ref.listen(conversationsControllerProvider, (p, n) => _afterBuild(() => _onItemsChanged(p, n)));
    ref.listen(conversationFiltersProvider, (p, n) => _afterBuild(() => _onQueryChanged(p, n)));

    final s = ref.watch(conversationsControllerProvider);
    final q = ref.watch(conversationFiltersProvider);
    final selected = ref.watch(inboxProvider.select((x) => x.selected));
    final selecting = selected.isNotEmpty;
    final now = ref.watch(inboxClockProvider);
    final meId = ref.watch(currentAgentProvider.select((a) => a.id));
    final unreadNotifications = ref.watch(unreadNotificationsProvider);
    final anyMine = ref.watch(inboxProvider.select((x) => x.conversations.any((c) => c.ownership == Ownership.mine)));
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final ctrl = ref.read(conversationsControllerProvider.notifier);
    final filters = ref.read(conversationFiltersProvider.notifier);

    final bannerHeight = s.network == NetworkState.online ? 0.0 : 32 * scale.clamp(1.0, 2.0);
    final segmentedHeight = 44 * scale.clamp(1.0, 1.6) + bannerHeight;
    final appBarDelegate = ConversationsAppBarDelegate(
      title: l.inbox_title,
      onSearch: () => context.push(Routes.search),
      onNotifications: () => context.push(Routes.notifications),
      unreadNotifications: unreadNotifications,
      selectedCount: selected.length,
      onExitSelection: ctrl.clearSelection,
      onSelectAll: ctrl.selectAll,
      textScale: scale,
    );

    Widget disabledWhileSelecting(Widget child) => IgnorePointer(
      ignoring: selecting,
      child: AnimatedOpacity(opacity: selecting ? 0.4 : 1, duration: AppMotion.fast, child: child),
    );

    // Rows: pinned "needs reply" section in Mine (§4.6), then the rest.
    final rows = _withLeaving(s.items);
    final waiting = q.segment == InboxSegment.mine
        ? [
            for (final i in rows)
              if (i.waitingOverSla(now)) i,
          ]
        : const <ConversationSummary>[];
    final shownWaiting = _needsExpanded ? waiting : waiting.take(3).toList();
    final shownWaitingIds = {for (final i in shownWaiting) i.id};
    final rest = [
      for (final i in rows)
        if (!shownWaitingIds.contains(i.id)) i,
    ];

    final content = <Widget>[];
    if (s.phase == InboxLoadPhase.loading && s.items.isEmpty) {
      content.add(SliverToBoxAdapter(child: ConversationTileSkeleton.list()));
    } else if (s.items.isEmpty && _leaving.isEmpty) {
      final kind = _emptyKind(s, q, anyMine);
      content.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: ConversationsEmptyState(kind: kind, onAction: () => _emptyAction(kind)),
        ),
      );
    } else {
      if (waiting.isNotEmpty) {
        content.add(
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: AppMotion.normal,
              curve: AppMotion.standard,
              alignment: AlignmentDirectional.topStart,
              child: Column(
                children: [
                  NeedsReplyHeader(
                    count: waiting.length,
                    expanded: _needsExpanded,
                    onToggle: () => setState(() => _needsExpanded = !_needsExpanded),
                  ),
                  for (var i = 0; i < shownWaiting.length; i++)
                    _tile(shownWaiting[i], i, q: q, selected: selected, now: now, meId: meId, showDivider: i > 0),
                  if (rest.isNotEmpty) const RestHeader(),
                ],
              ),
            ),
          ),
        );
      }
      content
        ..add(
          SliverList.builder(
            itemCount: rest.length,
            itemBuilder: (context, i) => _tile(
              rest[i],
              shownWaiting.length + i,
              q: q,
              selected: selected,
              now: now,
              meId: meId,
              showDivider: i > 0,
            ),
          ),
        )
        ..add(
          SliverToBoxAdapter(
            child: _PaginationFooter(state: s, onRetry: ctrl.loadMore),
          ),
        );
    }

    // Under `extendBody` the shell reports the real tab-bar height (labels,
    // padding, system nav area) as bottom padding; 56 + viewPadding alone
    // put the FAB behind the bar on phones with a gesture/nav area.
    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      AppTabBar.height + MediaQuery.viewPaddingOf(context).bottom,
    );
    final scrollView = NotificationListener<UserScrollNotification>(
      onNotification: _onScrollNotification,
      child: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        displacement: 24,
        edgeOffset: appBarDelegate.minExtent + segmentedHeight,
        onRefresh: ctrl.refresh,
        // Opening one row's swipe actions closes the others.
        child: SlidableAutoCloseBehavior(
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(pinned: true, delegate: appBarDelegate),
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedHeaderDelegate(
                  height: segmentedHeight,
                  child: Column(
                    children: [
                      disabledWhileSelecting(
                        InboxSegmented(selected: q.segment, counts: s.counts, onChanged: filters.setSegment),
                      ),
                      const Spacer(),
                      if (bannerHeight > 0) ConnectionBanner(state: s.network, offlineLabel: l.inbox_offline_cached),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                floating: true,
                delegate: FloatingHeaderDelegate(
                  vsync: this,
                  height: 48 * scale.clamp(1.0, 1.6),
                  child: disabledWhileSelecting(
                    QuickFilterChips(
                      selected: q.chip,
                      unreadCount: s.counts['unread'] ?? 0,
                      advancedCount: q.advanced.activeCount,
                      onSelected: filters.setChip,
                      onOpenFilters: () => showInboxFiltersSheet(context, ref),
                    ),
                  ),
                ),
              ),
              if (q.advanced.hasActive)
                SliverToBoxAdapter(
                  child: disabledWhileSelecting(
                    ActiveFiltersBar(filters: q.advanced, onChanged: filters.setAdvanced, onClearAll: filters.clearAll),
                  ),
                ),
              for (final sliver in content) SliverFadeTransition(opacity: _fade, sliver: sliver),
              SliverToBoxAdapter(child: SizedBox(height: bottomInset + 56 + AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Tablets: content max 720dp, centered (§3).
              Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: scrollView),
              ),
              PositionedDirectional(
                top: appBarDelegate.minExtent + segmentedHeight + AppSpacing.sm,
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
              if (!selecting)
                PositionedDirectional(
                  end: AppSpacing.lg,
                  bottom: bottomInset + AppSpacing.lg,
                  child: AppFab(
                    icon: AppIcons.compose,
                    semanticLabel: l.inbox_new_conversation,
                    visible: _fabVisible,
                    onPressed: () => showNewMessageSheet(context, ref),
                  ),
                ),
            ],
          ),
        ),
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
        child: Center(child: AppSpinner(size: 24, delayed: false)),
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
    if (!state.hasMore && state.items.length > 10) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l.inbox_end,
          textAlign: TextAlign.center,
          style: context.text.caption.copyWith(color: c.textTertiary),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.sm);
  }
}

/// Row insert / remove: size + fade, 200ms easeOutCubic (§11).
class _RowTransition extends StatefulWidget {
  const _RowTransition({super.key, required this.child, this.leaving = false});

  final Widget child;
  final bool leaving;

  @override
  State<_RowTransition> createState() => _RowTransitionState();
}

class _RowTransitionState extends State<_RowTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: widget.leaving ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _ctrl, curve: AppMotion.standard);

  @override
  void initState() {
    super.initState();
    widget.leaving ? _ctrl.reverse() : _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _curve,
    axisAlignment: -1,
    child: FadeTransition(opacity: _curve, child: widget.child),
  );
}
