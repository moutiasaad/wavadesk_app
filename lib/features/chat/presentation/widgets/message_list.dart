import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/chat_controller.dart';
import '../../application/messages_controller.dart';
import '../../domain/message_grouping.dart';
import 'bubbles/message_bubble.dart';
import 'bubbles/typing_bubble.dart';
import 'day_divider.dart';
import 'message_group.dart';
import 'unread_divider.dart';

/// The thread (Chat spec §4.3): reversed list (newest at the bottom), day
/// and unread dividers, sender grouping, typing row, paging, jump state,
/// read receipts and highlight.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({
    super.key,
    required this.conversationId,
    required this.controller,
    required this.bottomPadding,
    required this.onReply,
    required this.onJumpStateChanged,
    this.readOnly = false,
    this.preClaim = false,
  });

  final String conversationId;
  final ScrollController controller;

  /// Space reserved under the last bubble (AI card height + 8).
  final double bottomPadding;
  final void Function(Message message) onReply;

  /// show = scrolled more than one screen up; newCount = messages that
  /// arrived meanwhile.
  final void Function(bool show, int newCount) onJumpStateChanged;
  final bool readOnly;

  /// Unclaimed (Claim spec §5.3): read, copy, info and transcribe only — no
  /// reply, reactions, delete, save-to-KB or swipe-to-reply.
  final bool preClaim;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> with WidgetsBindingObserver {
  static const _atBottomSlop = 24.0;

  final _dividerKey = GlobalKey();
  final Map<String, GlobalKey> _rowKeys = {};
  final Set<String> _known = {};
  final Set<String> _animate = {};
  bool _initialised = false;
  bool _foreground = true;
  bool _showJump = false;
  int _newCount = 0;
  Timer? _unreadTimer;
  Timer? _readTimer;

  ScrollController get _scroll => widget.controller;
  String get _id => widget.conversationId;

  bool get _atBottom => !_scroll.hasClients || _scroll.offset <= _atBottomSlop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    // The unread divider disappears after 5s (§4.3).
    _unreadTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) ref.read(messagesControllerProvider(_id).notifier).clearUnreadDivider();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _positionInitially());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_onScroll);
    _unreadTimer?.cancel();
    _readTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _scheduleRead();
  }

  // ---- Scrolling --------------------------------------------------------------------

  /// Unread divider ~30% from the top (70% from the bottom of the reversed
  /// list); otherwise stay at the newest message.
  void _positionInitially() {
    if (!mounted) return;
    final ctx = _dividerKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.7);
    _scheduleRead();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    // Load older within 600dp of the top.
    if (p.maxScrollExtent - p.pixels < 600) {
      ref.read(messagesControllerProvider(_id).notifier).loadOlder();
    }
    _showJump = p.pixels > p.viewportDimension;
    if (_atBottom) _newCount = 0;
    _report();
    if (_atBottom) _scheduleRead();
  }

  (bool, int)? _reported;

  /// Calls [MessageList.onJumpStateChanged] only when the state changes.
  void _report() {
    final next = (_showJump || _newCount > 0, _newCount);
    if (next == _reported) return;
    _reported = next;
    widget.onJumpStateChanged(next.$1, next.$2);
  }

  /// Mark read once the latest inbound has been visible ≥ 1s in foreground.
  void _scheduleRead() {
    _readTimer?.cancel();
    final c = ref.read(conversationProvider(_id));
    if (c == null || c.unreadCount == 0 || widget.readOnly) return;
    _readTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && _foreground && _atBottom) ref.read(inboxProvider.notifier).markRead(_id);
    });
  }

  void _scrollToMessage(String messageId, List<ChatListItem> items, {int attempt = 0}) {
    final ctx = _rowKeys[messageId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.slow,
        curve: AppMotion.standard,
      );
      return;
    }
    if (attempt > 4 || !_scroll.hasClients) return;
    // Not built yet (lazy list): jump toward its estimated position, retry.
    final index = items.indexWhere((i) => i is MessageItem && i.message.id == messageId);
    if (index < 0) return;
    final p = _scroll.position;
    final target = (p.maxScrollExtent * index / items.length).clamp(0.0, p.maxScrollExtent);
    _scroll.jumpTo(target);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMessage(messageId, items, attempt: attempt + 1));
  }

  // ---- Real-time ---------------------------------------------------------------------

  void _onMessagesChanged(MessagesState? prev, MessagesState next) {
    if (prev == null || !_initialised) return;
    final fresh = [
      for (final m in next.messages)
        if (!_known.contains(m.id)) m,
    ];
    if (fresh.isEmpty) return;
    final previousNewest = prev.messages.isEmpty ? null : prev.messages.last.sentAt;
    final arrivedAtBottom = [
      for (final m in fresh)
        if (previousNewest == null || !m.sentAt.isBefore(previousNewest)) m,
    ];
    _animate.addAll(arrivedAtBottom.map((m) => m.id));
    if (arrivedAtBottom.isEmpty) return;

    final ownSend = arrivedAtBottom.every((m) => m.isOutgoing || m.type == MessageBubbleType.internalNote);
    if (_atBottom || ownSend) {
      // Already at the bottom (or I just sent): follow the conversation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && _scroll.offset > 0) {
          _scroll.animateTo(0, duration: AppMotion.normal, curve: AppMotion.standard);
        }
      });
      _scheduleRead();
    } else {
      _newCount += arrivedAtBottom.where((m) => !m.isOutgoing).length;
      _report();
    }

    // Polite announcement only for screen-reader users at the bottom (§11).
    if (MediaQuery.accessibleNavigationOf(context) && _atBottom) {
      final detail = ref.read(chatDetailProvider(_id));
      for (final m in arrivedAtBottom.where((m) => m.type == MessageBubbleType.incoming)) {
        if (detail != null) {
          SemanticsService.announce(MessageBubble.describe(context, m, detail), Directionality.of(context));
        }
      }
    }
  }

  void _onHighlight(String? prev, String? next) {
    if (next == null || next == prev) return;
    final s = ref.read(messagesControllerProvider(_id));
    final detail = ref.read(chatDetailProvider(_id));
    final items = MessageGrouping.build(
      s.messages,
      unreadAnchorId: s.unreadAnchorId,
      unreadCount: s.unreadCount,
      typing: detail?.conversation.customerTyping ?? false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMessage(next, items));
  }

  // ---- Build ------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(messagesControllerProvider(_id), _onMessagesChanged);
    ref.listen<String?>(messagesControllerProvider(_id).select((s) => s.highlightId), _onHighlight);
    ref.listen(conversationProvider(_id).select((c) => c?.unreadCount ?? 0), (_, n) {
      if (n > 0) _scheduleRead();
    });

    final s = ref.watch(messagesControllerProvider(_id));
    final detail = ref.watch(chatDetailProvider(_id));
    if (detail == null) return const SizedBox.shrink();
    // Never an empty thread before the first page arrives.
    if (s.loading) return Align(alignment: Alignment.bottomCenter, child: AppSkeleton.chat());
    if (s.loadFailed) {
      final l = context.l10n;
      return EmptyState(
        icon: AppIcons.offline,
        title: l.chatscreen_load_failed,
        actionLabel: l.common_retry,
        onAction: ref.read(messagesControllerProvider(_id).notifier).reload,
      );
    }

    final items = MessageGrouping.build(
      s.messages,
      unreadAnchorId: s.unreadAnchorId,
      unreadCount: s.unreadCount,
      typing: detail.conversation.customerTyping,
    );
    if (!_initialised) {
      _known.addAll(s.messages.map((m) => m.id));
      _initialised = true;
    } else {
      _known.addAll(s.messages.map((m) => m.id));
    }
    final showTopSpinner = s.loadingOlder;
    final messages = ref.read(messagesControllerProvider(_id).notifier);

    return LayoutBuilder(
      builder: (context, box) {
        final maxBubble = (box.maxWidth - 2 * AppSpacing.md) * 0.8;
        return ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, widget.bottomPadding),
          itemCount: items.length + (showTopSpinner ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == items.length) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Semantics(
                  label: context.l10n.chatlist_loading_older,
                  child: const Center(child: AppSpinner(size: 20, delayed: false)),
                ),
              );
            }
            final item = items[i];
            return switch (item) {
              DayDividerItem(:final day) => DayDivider(key: ValueKey(item.key), day: day),
              UnreadDividerItem(:final count) => KeyedSubtree(
                key: _dividerKey,
                child: UnreadDivider(count: count),
              ),
              TypingItem() => const Padding(
                key: ValueKey('typing'),
                padding: EdgeInsets.only(top: 10),
                child: TypingBubble(),
              ),
              MessageItem() => KeyedSubtree(
                key: _rowKeys.putIfAbsent(item.message.id, GlobalKey.new),
                child: MessageRow(
                  conversationId: _id,
                  item: item,
                  detail: detail,
                  maxWidth: maxBubble,
                  highlighted: s.highlightId == item.message.id,
                  animateIn: _animate.remove(item.message.id),
                  readOnly: widget.readOnly || widget.preClaim,
                  allowTranscribe: widget.preClaim,
                  onReply: widget.onReply,
                  onQuoteTap: messages.highlight,
                ),
              ),
            };
          },
        );
      },
    );
  }
}
