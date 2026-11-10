import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_controllers.dart' show currentAgentProvider;
import 'settings_controller.dart';

/// Advanced filters from the Filters sheet (§9.4).
@immutable
class InboxFilters {
  const InboxFilters({
    this.channels = const {},
    this.statuses = const {},
    this.priorities = const {},
    this.assignee = AssigneeFilter.all,
    this.date = DateRangeFilter.any,
    this.tags = const {},
  });

  final Set<Channel> channels;
  final Set<ConversationStatus> statuses;
  final Set<Priority> priorities;
  final AssigneeFilter assignee;
  final DateRangeFilter date;
  final Set<String> tags;

  static const empty = InboxFilters();

  int get activeCount =>
      channels.length +
      statuses.length +
      priorities.length +
      tags.length +
      (assignee == AssigneeFilter.all ? 0 : 1) +
      (date == DateRangeFilter.any ? 0 : 1);

  bool get isActive => activeCount > 0;

  InboxFilters copyWith({
    Set<Channel>? channels,
    Set<ConversationStatus>? statuses,
    Set<Priority>? priorities,
    AssigneeFilter? assignee,
    DateRangeFilter? date,
    Set<String>? tags,
  }) => InboxFilters(
    channels: channels ?? this.channels,
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    assignee: assignee ?? this.assignee,
    date: date ?? this.date,
    tags: tags ?? this.tags,
  );

  bool matches(Conversation c) {
    if (channels.isNotEmpty && !channels.contains(c.channel)) return false;
    if (statuses.isNotEmpty && !statuses.contains(c.status)) return false;
    if (priorities.isNotEmpty && !priorities.contains(c.priority)) return false;
    if (tags.isNotEmpty && !tags.any((t) => c.tags.contains(t) || c.customer.tags.contains(t))) {
      return false;
    }
    final ok = switch (assignee) {
      AssigneeFilter.all => true,
      AssigneeFilter.me => c.ownership == Ownership.mine,
      AssigneeFilter.colleague => c.ownership == Ownership.colleague,
      AssigneeFilter.ai => c.ownership == Ownership.ai,
      AssigneeFilter.unassigned => c.ownership == Ownership.unassigned,
    };
    if (!ok) return false;
    final now = DateTime.now();
    final since = switch (date) {
      DateRangeFilter.any || DateRangeFilter.custom => null,
      DateRangeFilter.today => DateTime(now.year, now.month, now.day),
      DateRangeFilter.last7 => now.subtract(const Duration(days: 7)),
      DateRangeFilter.last30 => now.subtract(const Duration(days: 30)),
    };
    return since == null || c.lastActivity.isAfter(since);
  }
}

@immutable
class InboxState {
  const InboxState({
    required this.conversations,
    required this.segment,
    this.quickFilter = QuickFilter.all,
    this.filters = InboxFilters.empty,
    this.network = NetworkState.online,
    this.loading = true,
    this.suggestionLoading = const {},
    this.selected = const {},
  });

  final List<Conversation> conversations;
  final InboxSegment segment;
  final QuickFilter quickFilter;
  final InboxFilters filters;
  final NetworkState network;

  /// First load — lists show skeletons (§8.15).
  final bool loading;

  /// Conversation ids whose AI suggestion is being (re)generated.
  final Set<String> suggestionLoading;

  /// Multi-select (long press on a row).
  final Set<String> selected;

  bool get selecting => selected.isNotEmpty;

  InboxState copyWith({
    List<Conversation>? conversations,
    InboxSegment? segment,
    QuickFilter? quickFilter,
    InboxFilters? filters,
    NetworkState? network,
    bool? loading,
    Set<String>? suggestionLoading,
    Set<String>? selected,
  }) => InboxState(
    conversations: conversations ?? this.conversations,
    segment: segment ?? this.segment,
    quickFilter: quickFilter ?? this.quickFilter,
    filters: filters ?? this.filters,
    network: network ?? this.network,
    loading: loading ?? this.loading,
    suggestionLoading: suggestionLoading ?? this.suggestionLoading,
    selected: selected ?? this.selected,
  );
}

/// Real-time events the UI reacts to (snackbars, haptics).
sealed class InboxEvent {
  const InboxEvent(this.conversationId);
  final String conversationId;
}

class ColleagueClaimedEvent extends InboxEvent {
  const ColleagueClaimedEvent(super.conversationId, this.agent);
  final Agent agent;
}

class NewMessageEvent extends InboxEvent {
  const NewMessageEvent(super.conversationId, {required this.assignedToMe});
  final bool assignedToMe;
}

/// A colleague assigned a conversation to the signed-in agent.
class AssignedToMeEvent extends InboxEvent {
  const AssignedToMeEvent(super.conversationId, this.byName);
  final String byName;
}

/// A brand-new conversation arrived.
class NewConversationEvent extends InboxEvent {
  const NewConversationEvent(super.conversationId);
}

final inboxProvider = NotifierProvider<InboxController, InboxState>(InboxController.new);

/// Conversations loaded from the API (via [upsertFromApi]) and the
/// optimistic local mirror of every action on them.
class InboxController extends Notifier<InboxState> {
  final _events = StreamController<InboxEvent>.broadcast();
  int _seq = 0;

  Stream<InboxEvent> get events => _events.stream;

  @override
  InboxState build() {
    ref.onDispose(_events.close);
    // Conversations arrive via upsertFromApi.
    return InboxState(conversations: const [], segment: ref.read(settingsProvider).lastSegment, loading: false);
  }

  /// The signed-in agent (the API user).
  Agent get _me => ref.read(currentAgentProvider);

  String _id() => 'local-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  Conversation? byId(String id) {
    for (final c in state.conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _update(String id, Conversation Function(Conversation c) fn, {bool toTop = false}) {
    final list = [...state.conversations];
    final i = list.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final updated = fn(list[i]);
    if (toTop) {
      list
        ..removeAt(i)
        ..insert(0, updated);
    } else {
      list[i] = updated;
    }
    state = state.copyWith(conversations: list);
  }

  // ---- List controls ------------------------------------------------------

  void setSegment(InboxSegment segment) {
    state = state.copyWith(segment: segment, selected: {});
    ref.read(settingsProvider.notifier).setLastSegment(segment);
  }

  void setQuickFilter(QuickFilter f) => state = state.copyWith(quickFilter: f);

  void setFilters(InboxFilters filters) => state = state.copyWith(filters: filters);

  void clearFilters() => state = state.copyWith(filters: InboxFilters.empty, quickFilter: QuickFilter.all);

  void setNetwork(NetworkState network) => state = state.copyWith(network: network);

  /// Cycles online → connecting → offline (hidden debug affordance).
  void cycleNetwork() {
    final next = NetworkState.values[(state.network.index + 1) % NetworkState.values.length];
    setNetwork(next);
  }

  void toggleSelected(String id) {
    final s = {...state.selected};
    s.contains(id) ? s.remove(id) : s.add(id);
    state = state.copyWith(selected: s);
  }

  void clearSelection() => state = state.copyWith(selected: {});

  // ---- Conversation actions ----------------------------------------------

  void markRead(String id) => _update(id, (c) => c.copyWith(unreadCount: 0));

  void markUnread(String id) => _update(id, (c) => c.copyWith(unreadCount: 1));

  Conversation? archive(String id) {
    final before = byId(id);
    _update(id, (c) => c.copyWith(status: ConversationStatus.closed, unreadCount: 0, clearWaiting: true));
    return before;
  }

  /// Applies [action] to every id and returns the snapshots for Undo.
  List<Conversation> bulk(Set<String> ids, void Function(String id) action) {
    final before = [for (final id in ids) ?byId(id)];
    for (final id in ids) {
      action(id);
    }
    clearSelection();
    return before;
  }

  void setSelection(Set<String> ids) => state = state.copyWith(selected: ids);

  /// Appends a structured system event (Chat spec §9). [actor] defaults to
  /// the signed-in agent.
  Message _sys(SystemEventKind kind, {Agent? actor, String? target, String? value}) {
    final a = actor ?? _me;
    return Message(
      id: _id(),
      type: MessageBubbleType.system,
      sentAt: DateTime.now(),
      systemEvent: SystemEvent(kind: kind, actorId: a.id, actorName: a.name, target: target, value: value),
    );
  }

  void claim(String id) {
    _update(
      id,
      (c) => c.copyWith(
        ownership: Ownership.mine,
        assignee: _me,
        status: c.status == ConversationStatus.ai ? ConversationStatus.open : c.status,
        viewers: const [],
        messages: [...c.messages, _sys(SystemEventKind.claimed)],
      ),
    );
  }

  /// [by] is who performed the assignment (defaults to me).
  void assign(String id, Agent agent, {Agent? by}) {
    final mine = agent.id == _me.id;
    _update(
      id,
      (c) => c.copyWith(
        ownership: mine ? Ownership.mine : Ownership.colleague,
        assignee: agent,
        status: c.status == ConversationStatus.ai ? ConversationStatus.open : c.status,
        messages: [
          ...c.messages,
          _sys(SystemEventKind.assigned, actor: by, target: agent.name),
        ],
      ),
    );
  }

  /// "تحرير من المسؤولية": back to the Unassigned pool.
  void unassign(String id) => _update(
    id,
    (c) => c.copyWith(
      ownership: Ownership.unassigned,
      clearAssignee: true,
      waitingSince: DateTime.now(),
      messages: [...c.messages, _sys(SystemEventKind.unassigned)],
    ),
  );

  void assignToAi(String id) =>
      _update(id, (c) => c.copyWith(ownership: Ownership.ai, status: ConversationStatus.ai, clearAssignee: true));

  /// Returns the previous value so the UI can offer Undo (§2.2).
  Conversation? resolve(String id) {
    final before = byId(id);
    _update(
      id,
      (c) => c.copyWith(
        status: ConversationStatus.resolved,
        unreadCount: 0,
        clearWaiting: true,
        clearSnooze: true,
        messages: [...c.messages, _sys(SystemEventKind.resolved)],
      ),
    );
    return before;
  }

  Conversation? reopen(String id) {
    final before = byId(id);
    _update(
      id,
      (c) => c.copyWith(
        status: ConversationStatus.open,
        clearSnooze: true,
        messages: [...c.messages, _sys(SystemEventKind.reopened)],
      ),
    );
    return before;
  }

  Conversation? snooze(String id, DateTime until) {
    final before = byId(id);
    _update(
      id,
      (c) => c.copyWith(
        status: ConversationStatus.snoozed,
        snoozedUntil: until,
        messages: [
          ...c.messages,
          _sys(SystemEventKind.snoozed, value: until.toIso8601String()),
        ],
      ),
    );
    return before;
  }

  void unsnooze(String id) => _update(id, (c) => c.copyWith(status: ConversationStatus.open, clearSnooze: true));

  /// Puts back a snapshot captured before a reversible action.
  void restore(Conversation snapshot) => _update(snapshot.id, (_) => snapshot);

  /// Assign → Undo (Assign spec §7): ownership goes back to [snapshot] but
  /// the note and events stay, plus "ألغى {actor} الإسناد".
  void undoAssign(Conversation snapshot) => _update(
    snapshot.id,
    (c) => c.copyWith(
      ownership: snapshot.ownership,
      assignee: snapshot.assignee,
      clearAssignee: snapshot.assignee == null,
      status: snapshot.status,
      waitingSince: snapshot.waitingSince,
      messages: [...c.messages, _sys(SystemEventKind.assignUndone)],
    ),
  );

  void restoreAll(List<Conversation> snapshots) {
    for (final s in snapshots) {
      restore(s);
    }
  }

  void setPriority(String id, Priority p) => _update(
    id,
    (c) => c.priority == p
        ? c
        : c.copyWith(
            priority: p,
            messages: [
              ...c.messages,
              _sys(SystemEventKind.priority, value: p.name),
            ],
          ),
  );

  void toggleTag(String id, String tag) => _update(id, (c) {
    final tags = [...c.tags];
    final adding = !tags.contains(tag);
    adding ? tags.add(tag) : tags.remove(tag);
    return c.copyWith(
      tags: tags,
      messages: adding ? [...c.messages, _sys(SystemEventKind.tagAdded, value: tag)] : null,
    );
  });

  void setBlocked(String id, bool blocked) => _update(
    id,
    (c) => c.copyWith(
      customer: c.customer.copyWith(blocked: blocked),
      status: blocked ? ConversationStatus.closed : ConversationStatus.open,
      messages: [...c.messages, _sys(blocked ? SystemEventKind.blocked : SystemEventKind.unblocked)],
    ),
  );

  /// Per-conversation AI pause (actions sheet / "تولَّ المحادثة").
  void setAiPaused(String id, bool paused) => _update(
    id,
    (c) => c.copyWith(
      aiPaused: paused,
      messages: [...c.messages, _sys(paused ? SystemEventKind.aiPaused : SystemEventKind.aiResumed)],
    ),
  );

  /// "تولَّ المحادثة" on an AI-handled chat: claim + pause the AI.
  void takeOver(String id) {
    claim(id);
    setAiPaused(id, true);
  }

  // ---- Customer-level (Profile spec) ------------------------------------------

  /// Applies [fn] to the customer in every conversation with that contact.
  void updateCustomer(String customerId, Customer Function(Customer c) fn) {
    state = state.copyWith(
      conversations: [
        for (final c in state.conversations) c.customer.id == customerId ? c.copyWith(customer: fn(c.customer)) : c,
      ],
    );
  }

  /// Block/unblock across channels: open chats close with a system event.
  void setCustomerBlocked(String customerId, bool blocked) {
    for (final c in [...state.conversations]) {
      if (c.customer.id != customerId) continue;
      if (blocked && !c.isClosed || !blocked && c.customer.blocked && c.status == ConversationStatus.closed) {
        setBlocked(c.id, blocked);
      } else {
        _update(c.id, (x) => x.copyWith(customer: x.customer.copyWith(blocked: blocked)));
      }
    }
  }

  /// GDPR/PDPL erase: drops every conversation of the contact.
  void eraseCustomer(String customerId) => state = state.copyWith(
    conversations: [
      for (final c in state.conversations)
        if (c.customer.id != customerId) c,
    ],
  );

  /// Merge: conversations of [fromId] now belong to [into].
  void mergeCustomer(String fromId, Customer into) => state = state.copyWith(
    conversations: [for (final c in state.conversations) c.customer.id == fromId ? c.copyWith(customer: into) : c],
  );

  /// Public system event (tag added from the profile, call logged…).
  void addSystemEvent(String id, SystemEventKind kind, {String? value, String? target}) => _update(
    id,
    (c) => c.copyWith(
      messages: [
        ...c.messages,
        _sys(kind, value: value, target: target),
      ],
    ),
  );

  void addCustomerNote(String id, String text) => _update(
    id,
    (c) => c.copyWith(
      customer: c.customer.copyWith(
        notes: [
          TeamNote(author: _me.name, text: text, createdAt: DateTime.now()),
          ...c.customer.notes,
        ],
      ),
    ),
  );

  List<Conversation> bulkResolve(Set<String> ids) {
    final before = [for (final id in ids) ?byId(id)];
    for (final id in ids) {
      resolve(id);
    }
    clearSelection();
    return before;
  }

  List<Conversation> bulkAssign(Set<String> ids, Agent agent) {
    final before = [for (final id in ids) ?byId(id)];
    for (final id in ids) {
      assign(id, agent);
    }
    clearSelection();
    return before;
  }

  // ---- Messaging ----------------------------------------------------------

  /// Local optimistic bubble (`sending`) for [startConversation]. Real
  /// messages go through the messages repository. Returns the new id.
  String sendMessage(
    String id,
    String text, {
    MessageKind kind = MessageKind.text,
    QuotedMessage? quote,
    String sentVia = 'manual',
    String? fileName,
    String? fileSize,
    Duration? mediaDuration,
    int albumCount = 0,
    String? locationLabel,
    String? templateName,
    List<String> templateButtons = const [],
  }) {
    final msgId = _id();
    _update(
      id,
      (c) => c.copyWith(
        status: c.status == ConversationStatus.resolved ? ConversationStatus.open : c.status,
        clearWaiting: true,
        messages: [
          ...c.messages,
          Message(
            id: msgId,
            type: MessageBubbleType.outgoing,
            kind: kind,
            text: text,
            sentAt: DateTime.now(),
            senderId: _me.id,
            senderName: _me.name,
            delivery: DeliveryState.sending,
            quote: quote,
            sentVia: sentVia,
            mediaDuration: mediaDuration ?? (kind == MessageKind.voice ? const Duration(seconds: 7) : null),
            fileName: fileName ?? (kind == MessageKind.file ? 'document.pdf' : null),
            fileSize: fileSize ?? (kind == MessageKind.file ? '120 KB' : null),
            albumCount: albumCount,
            locationLabel: locationLabel ?? (kind == MessageKind.location ? text : null),
            templateName: templateName,
            templateButtons: templateButtons,
          ),
        ],
      ),
      toTop: true,
    );
    return msgId;
  }

  void deleteMessage(String convId, String msgId) => _update(
    convId,
    (c) => c.copyWith(
      messages: [for (final m in c.messages) m.id == msgId ? m.copyWith(kind: MessageKind.deleted, text: '') : m],
    ),
  );

  /// Removes a failed message that was never delivered.
  void discardMessage(String convId, String msgId) => _update(
    convId,
    (c) => c.copyWith(
      messages: [
        for (final m in c.messages)
          if (m.id != msgId) m,
      ],
    ),
  );

  /// Toggles the agent's reaction (one per agent).
  void react(String convId, String msgId, String emoji) => _update(
    convId,
    (c) => c.copyWith(
      messages: [
        for (final m in c.messages)
          if (m.id != msgId)
            m
          else
            m.copyWith(
              reactions: [
                for (final r in m.reactions)
                  if (r.byContact) r,
                if (!m.reactions.any((r) => !r.byContact && r.emoji == emoji)) Reaction(emoji: emoji, byContact: false),
              ],
            ),
      ],
    ),
  );

  void setAiFeedback(String convId, String msgId, String rating) => _update(
    convId,
    (c) => c.copyWith(messages: [for (final m in c.messages) m.id == msgId ? m.copyWith(aiFeedback: rating) : m]),
  );

  void addNote(String id, String text, {List<String> mentions = const []}) => _update(
    id,
    (c) => c.copyWith(
      messages: [
        ...c.messages,
        Message(
          id: _id(),
          type: MessageBubbleType.internalNote,
          senderId: _me.id,
          senderName: _me.name,
          text: text,
          mentions: mentions,
          sentAt: DateTime.now(),
        ),
      ],
    ),
  );

  // ---- Presence / real-time ----------------------------------------------

  /// Called when a chat opens.
  void startViewing(String id) {
    markRead(id);
  }

  /// "اطلب التحويل": an @mention note to the owner (push is server-side).
  void requestTransfer(String id, String noteText) {
    final owner = byId(id)?.assignee;
    addNote(id, noteText, mentions: [?owner?.name]);
  }

  // ---- Real API (/mobile/v1) -------------------------------------------------

  /// Inserts or replaces a conversation loaded from the server
  /// (`GET conversations/{id}`), keeping messages already held locally.
  void upsertFromApi(Conversation c) {
    final list = [...state.conversations];
    final i = list.indexWhere((x) => x.id == c.id);
    if (i < 0) {
      list.insert(0, c);
    } else {
      list[i] = c.copyWith(messages: c.messages.isEmpty ? list[i].messages : c.messages);
    }
    state = state.copyWith(conversations: list);
  }

  // ---- Outbound ------------------------------------------------------------

  /// FAB → new outbound message from an approved template.
  /// No `/mobile/v1` endpoint starts an outbound conversation yet, so this
  /// stays local (the server lists no sendable templates today).
  String startConversation({required String name, required String phone, required MessageTemplate template}) {
    final id = _id();
    final customer = Customer(id: 'cu-$id', name: name.isEmpty ? phone : name, channel: Channel.whatsapp, phone: phone);
    final conv = Conversation(
      id: id,
      customer: customer,
      status: ConversationStatus.pending,
      ownership: Ownership.mine,
      assignee: _me,
      messages: const [],
    );
    state = state.copyWith(conversations: [conv, ...state.conversations]);
    sendMessage(id, template.body.replaceAll('{{1}}', customer.name).replaceAll('{{2}}', '—'));
    return id;
  }
}

// ---- Derived providers ------------------------------------------------------

bool _segmentMatch(InboxSegment s, Conversation c) => switch (s) {
  InboxSegment.mine => c.ownership == Ownership.mine,
  InboxSegment.unassigned => c.ownership == Ownership.unassigned,
  InboxSegment.all => true,
};

bool _quickMatch(QuickFilter f, Conversation c) => switch (f) {
  QuickFilter.all => !c.isClosed,
  QuickFilter.unread => c.isUnread,
  QuickFilter.awaitingReply => !c.isClosed && c.lastPreviewMessage?.type == MessageBubbleType.incoming,
  QuickFilter.aiReplied => c.ownership == Ownership.ai || c.lastPreviewMessage?.type == MessageBubbleType.outgoingAi,
  QuickFilter.closed => c.isClosed,
};

/// The list shown on the Conversations tab, sorted per §9.1.
final visibleConversationsProvider = Provider<List<Conversation>>((ref) {
  final s = ref.watch(inboxProvider);
  final list = s.conversations
      .where((c) => _segmentMatch(s.segment, c))
      .where((c) => s.filters.isActive && s.filters.statuses.isNotEmpty || _quickMatch(s.quickFilter, c))
      .where(s.filters.matches)
      .toList();
  if (s.segment == InboxSegment.unassigned) {
    // Waiting longest first.
    list.sort((a, b) => (a.waitingSince ?? a.lastActivity).compareTo(b.waitingSince ?? b.lastActivity));
  } else {
    list.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  }
  return list;
});

/// Open-conversation counts per segment for the segmented control.
final segmentCountsProvider = Provider<Map<InboxSegment, int>>((ref) {
  final list = ref.watch(inboxProvider.select((s) => s.conversations));
  final open = list.where((c) => !c.isClosed);
  return {
    InboxSegment.mine: open.where((c) => c.ownership == Ownership.mine).length,
    InboxSegment.unassigned: open.where((c) => c.ownership == Ownership.unassigned).length,
    InboxSegment.all: open.length,
  };
});

/// Tab-bar badge: unread Mine conversations (§8.2).
final mineUnreadProvider = Provider<int>((ref) {
  final list = ref.watch(inboxProvider.select((s) => s.conversations));
  return list.where((c) => c.ownership == Ownership.mine && c.isUnread).length;
});

/// Count shown on the Filters sheet's pinned button (live).
final filterPreviewCountProvider = Provider.family<int, InboxFilters>((ref, filters) {
  final s = ref.watch(inboxProvider);
  return s.conversations.where((c) => _segmentMatch(s.segment, c)).where(filters.matches).length;
});

final conversationProvider = Provider.family<Conversation?, String>((ref, id) {
  final list = ref.watch(inboxProvider.select((s) => s.conversations));
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

/// All distinct tags in use (filters sheet, tag picker).
final allTagsProvider = Provider<List<String>>((ref) {
  final list = ref.watch(inboxProvider.select((s) => s.conversations));
  return {
    for (final c in list) ...c.tags,
    for (final c in list) ...c.customer.tags,
    'توصيل',
    'دفع',
    'إرجاع',
    'شكوى',
  }.toList();
});

/// Previous conversations of the same customer (profile sheet).
final customerHistoryProvider = Provider.family<List<Conversation>, String>((ref, customerId) {
  final list = ref.watch(inboxProvider.select((s) => s.conversations));
  return list.where((c) => c.customer.id == customerId).toList();
});
