import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import 'conversation_summary.dart';

/// Quick filter chips (Inbox spec §4.3), single-select.
enum QuickChip { all, unread, awaiting, ai, snoozed, closed }

/// Sort override from the Filters sheet (§7). `smart` = per-segment default.
enum InboxSort { smart, newest, oldest, waiting, priority }

/// Inbox v2 §4.2.1: the single row of quick filter pills. Each maps onto
/// the segment + quick chip pair the data layer already understands.
enum InboxPill {
  all(InboxSegment.all, QuickChip.all),
  mine(InboxSegment.mine, QuickChip.all),
  unread(InboxSegment.all, QuickChip.unread),
  unassigned(InboxSegment.unassigned, QuickChip.all),
  waiting(InboxSegment.all, QuickChip.awaiting),
  ai(InboxSegment.all, QuickChip.ai),
  closed(InboxSegment.all, QuickChip.closed);

  const InboxPill(this.segment, this.chip);

  final InboxSegment segment;
  final QuickChip chip;

  /// The pill a query shows as selected (older saved combos fold in).
  static InboxPill of(InboxQuery q) => switch (q.chip) {
    QuickChip.unread => InboxPill.unread,
    QuickChip.awaiting => InboxPill.waiting,
    QuickChip.ai => InboxPill.ai,
    QuickChip.closed => InboxPill.closed,
    QuickChip.all || QuickChip.snoozed => switch (q.segment) {
      InboxSegment.mine => InboxPill.mine,
      InboxSegment.unassigned => InboxPill.unassigned,
      InboxSegment.all => InboxPill.all,
    },
  };
}

/// Advanced filters › الحالة (multi-select). Empty = the pill decides.
enum StatusFilter { open, pending, snoozed, closed }

/// Advanced filters › ردّ الذكاء (single choice on the server).
enum AiFilter { any, handled, escalated, untouched }

@immutable
class AdvancedFilters {
  const AdvancedFilters({
    this.channels = const {},
    this.priorities = const {},
    this.assignee = AssigneeFilter.all,
    this.colleagueId,
    this.teamIds = const {},
    this.tags = const {},
    this.date = DateRangeFilter.any,
    this.from,
    this.to,
    this.sort = InboxSort.smart,
    this.statuses = const {},
    this.ai = AiFilter.any,
  });

  final Set<Channel> channels;
  final Set<Priority> priorities;

  /// Only applied in the "الكل" segment (§7).
  final AssigneeFilter assignee;

  /// Set when [assignee] is [AssigneeFilter.colleague] and a specific
  /// colleague was picked ("زميل محدد ▸").
  final String? colleagueId;
  final Set<String> teamIds;
  final Set<String> tags;
  final DateRangeFilter date;
  final DateTime? from;
  final DateTime? to;
  final InboxSort sort;
  final Set<StatusFilter> statuses;
  final AiFilter ai;

  static const empty = AdvancedFilters();

  /// Filters that show as chips in the ActiveFiltersBar (§4.4).
  bool get hasActive =>
      channels.isNotEmpty ||
      priorities.isNotEmpty ||
      teamIds.isNotEmpty ||
      tags.isNotEmpty ||
      date != DateRangeFilter.any ||
      assignee != AssigneeFilter.all ||
      statuses.isNotEmpty ||
      ai != AiFilter.any;

  int get activeCount =>
      channels.length +
      priorities.length +
      teamIds.length +
      tags.length +
      (date == DateRangeFilter.any ? 0 : 1) +
      (assignee == AssigneeFilter.all ? 0 : 1) +
      statuses.length +
      (ai == AiFilter.any ? 0 : 1) +
      (sort == InboxSort.smart || sort == InboxSort.newest ? 0 : 1);

  AdvancedFilters copyWith({
    Set<Channel>? channels,
    Set<Priority>? priorities,
    AssigneeFilter? assignee,
    String? colleagueId,
    bool clearColleague = false,
    Set<String>? teamIds,
    Set<String>? tags,
    DateRangeFilter? date,
    DateTime? from,
    DateTime? to,
    bool clearRange = false,
    InboxSort? sort,
    Set<StatusFilter>? statuses,
    AiFilter? ai,
  }) => AdvancedFilters(
    channels: channels ?? this.channels,
    priorities: priorities ?? this.priorities,
    assignee: assignee ?? this.assignee,
    colleagueId: clearColleague ? null : (colleagueId ?? this.colleagueId),
    teamIds: teamIds ?? this.teamIds,
    tags: tags ?? this.tags,
    date: date ?? this.date,
    from: clearRange ? null : (from ?? this.from),
    to: clearRange ? null : (to ?? this.to),
    sort: sort ?? this.sort,
    statuses: statuses ?? this.statuses,
    ai: ai ?? this.ai,
  );

  Map<String, Object?> toJson() => {
    'channels': [for (final c in channels) c.name],
    'priorities': [for (final p in priorities) p.name],
    'assignee': assignee.name,
    'colleague_id': colleagueId,
    'team_ids': teamIds.toList(),
    'tags': tags.toList(),
    'date': date.name,
    'from': from?.toIso8601String(),
    'to': to?.toIso8601String(),
    'sort': sort.name,
    'statuses': [for (final s in statuses) s.name],
    'ai': ai.name,
  };

  factory AdvancedFilters.fromJson(Map<String, dynamic> j) {
    T pick<T extends Enum>(List<T> values, Object? raw, T fallback) =>
        values.firstWhere((v) => v.name == raw, orElse: () => fallback);
    Set<T> set<T extends Enum>(List<T> values, Object? raw) => {
      for (final v in (raw as List? ?? const []))
        for (final e in values)
          if (e.name == v) e,
    };
    return AdvancedFilters(
      channels: set(Channel.values, j['channels']),
      priorities: set(Priority.values, j['priorities']),
      assignee: pick(AssigneeFilter.values, j['assignee'], AssigneeFilter.all),
      colleagueId: j['colleague_id'] as String?,
      teamIds: {for (final t in (j['team_ids'] as List? ?? const [])) '$t'},
      tags: {for (final t in (j['tags'] as List? ?? const [])) '$t'},
      date: pick(DateRangeFilter.values, j['date'], DateRangeFilter.any),
      from: DateTime.tryParse(j['from'] as String? ?? ''),
      to: DateTime.tryParse(j['to'] as String? ?? ''),
      sort: pick(InboxSort.values, j['sort'], InboxSort.smart),
      statuses: set(StatusFilter.values, j['statuses']),
      ai: pick(AiFilter.values, j['ai'], AiFilter.any),
    );
  }
}

/// Everything that decides which rows the inbox shows.
@immutable
class InboxQuery {
  const InboxQuery({
    this.segment = InboxSegment.mine,
    this.chip = QuickChip.all,
    this.advanced = AdvancedFilters.empty,
  });

  final InboxSegment segment;
  final QuickChip chip;
  final AdvancedFilters advanced;

  InboxQuery copyWith({InboxSegment? segment, QuickChip? chip, AdvancedFilters? advanced}) =>
      InboxQuery(segment: segment ?? this.segment, chip: chip ?? this.chip, advanced: advanced ?? this.advanced);

  /// `GET /api/v1/conversations` query parameters (§6).
  Map<String, String> toQueryParameters() {
    String date(DateRangeFilter d) => switch (d) {
      DateRangeFilter.today => 'today',
      DateRangeFilter.last7 => '7d',
      DateRangeFilter.last30 => '30d',
      DateRangeFilter.custom => 'custom',
      DateRangeFilter.any => '',
    };
    final a = advanced;
    return {
      'segment': segment.name,
      'filter': chip.name,
      if (a.channels.isNotEmpty) 'channels': a.channels.map((c) => c.name).join(','),
      if (a.priorities.isNotEmpty) 'priority': a.priorities.map((p) => p.name).join(','),
      if (a.teamIds.isNotEmpty) 'team_ids': a.teamIds.join(','),
      if (a.tags.isNotEmpty) 'tags': a.tags.join(','),
      if (a.date != DateRangeFilter.any) 'date': date(a.date),
      if (a.date == DateRangeFilter.custom && a.from != null) 'from': a.from!.toIso8601String(),
      if (a.date == DateRangeFilter.custom && a.to != null) 'to': a.to!.toIso8601String(),
      if (segment == InboxSegment.all && a.assignee != AssigneeFilter.all) 'assignee': a.assignee.name,
      if (a.colleagueId != null) 'assignee_id': a.colleagueId!,
      'sort': a.sort.name,
      if (a.statuses.isNotEmpty) 'statuses': (a.statuses.map((s) => s.name).toList()..sort()).join(','),
      if (a.ai != AiFilter.any) 'ai': a.ai.name,
    };
  }
}

/// Local filtering + sorting, mirroring the server rules (§4.2, §4.3, §4.7).
/// Used to place real-time updates without a refetch.
abstract final class InboxRules {
  /// Ownership part of a segment (§4.2).
  static bool inSegment(InboxSegment s, ConversationSummary c, String meId) => switch (s) {
    InboxSegment.mine => c.isMine(meId),
    InboxSegment.unassigned => c.assignee == null,
    InboxSegment.all => true,
  };

  /// Status part: segments default to active work; the snoozed/closed chips
  /// replace it (§4.2, §4.3).
  static bool statusMatches(InboxQuery q, ConversationSummary c, DateTime now) {
    switch (q.chip) {
      case QuickChip.snoozed:
        return c.status == ConversationStatus.snoozed;
      case QuickChip.closed:
        final at = c.closedAt ?? c.lastActivityAt;
        return c.isClosed && now.difference(at).inDays <= 30;
      default:
        if (q.advanced.statuses.isNotEmpty) return true; // advancedMatches decides
        return q.segment == InboxSegment.all || c.isActive;
    }
  }

  static bool chipMatches(QuickChip chip, ConversationSummary c) => switch (chip) {
    QuickChip.all || QuickChip.snoozed || QuickChip.closed => true,
    QuickChip.unread => c.isUnread,
    // Last message from the customer and nobody answered yet.
    QuickChip.awaiting => c.isActive && c.lastMessage?.senderType == SenderType.contact,
    QuickChip.ai => c.isActive && c.lastMessage?.senderType == SenderType.ai,
  };

  static bool advancedMatches(InboxQuery q, ConversationSummary c, String meId, DateTime now) {
    final a = q.advanced;
    if (a.channels.isNotEmpty && !a.channels.contains(c.channel)) return false;
    if (a.priorities.isNotEmpty && !a.priorities.contains(c.priority ?? Priority.low)) return false;
    if (a.teamIds.isNotEmpty && !c.teamIds.any(a.teamIds.contains)) return false;
    if (a.tags.isNotEmpty && !c.tags.any(a.tags.contains)) return false;
    if (a.statuses.isNotEmpty && q.chip != QuickChip.closed) {
      final s = switch (c.status) {
        ConversationStatus.snoozed => StatusFilter.snoozed,
        ConversationStatus.resolved || ConversationStatus.closed => StatusFilter.closed,
        _ => c.assignee == null ? StatusFilter.pending : StatusFilter.open,
      };
      if (!a.statuses.contains(s) && !(s == StatusFilter.pending && a.statuses.contains(StatusFilter.open))) return false;
    }
    switch (a.ai) {
      case AiFilter.handled when !c.handledByAi:
      case AiFilter.escalated when !c.escalated:
      case AiFilter.untouched when c.handledByAi || c.escalated:
        return false;
      default:
        break;
    }
    if (q.segment == InboxSegment.all) {
      final ok = switch (a.assignee) {
        AssigneeFilter.all => true,
        AssigneeFilter.me => c.isMine(meId),
        AssigneeFilter.colleague =>
          c.assignee != null && !c.isMine(meId) && (a.colleagueId == null || c.assignee!.id == a.colleagueId),
        AssigneeFilter.ai => c.handledByAi,
        AssigneeFilter.unassigned => c.assignee == null && !c.handledByAi,
      };
      if (!ok) return false;
    }
    final at = c.lastActivityAt;
    return switch (a.date) {
      DateRangeFilter.any => true,
      DateRangeFilter.today => at.isAfter(DateTime(now.year, now.month, now.day)),
      DateRangeFilter.last7 => at.isAfter(now.subtract(const Duration(days: 7))),
      DateRangeFilter.last30 => at.isAfter(now.subtract(const Duration(days: 30))),
      DateRangeFilter.custom =>
        (a.from == null || !at.isBefore(a.from!)) && (a.to == null || at.isBefore(a.to!.add(const Duration(days: 1)))),
    };
  }

  static bool matches(InboxQuery q, ConversationSummary c, String meId, DateTime now) =>
      inSegment(q.segment, c, meId) &&
      statusMatches(q, c, now) &&
      chipMatches(q.chip, c) &&
      advancedMatches(q, c, meId, now);

  /// §4.7 sorting (smart = per-segment default; the sheet can override).
  static List<ConversationSummary> sort(List<ConversationSummary> items, InboxQuery q, DateTime now) {
    int byActivityDesc(ConversationSummary a, ConversationSummary b) => b.lastActivityAt.compareTo(a.lastActivityAt);
    int byWaitingAsc(ConversationSummary a, ConversationSummary b) =>
        (a.waitingSince ?? a.lastActivityAt).compareTo(b.waitingSince ?? b.lastActivityAt);

    final list = [...items];
    final sort = q.advanced.sort;
    if (sort == InboxSort.newest) return list..sort(byActivityDesc);
    if (sort == InboxSort.oldest) return list..sort((a, b) => a.lastActivityAt.compareTo(b.lastActivityAt));
    if (sort == InboxSort.priority) {
      int rank(ConversationSummary c) => switch (c.priority) {
        Priority.urgent => 3,
        Priority.high => 2,
        Priority.medium || null => 1,
        Priority.low => 0,
      };
      return list..sort((a, b) {
        final r = rank(b).compareTo(rank(a));
        return r != 0 ? r : byActivityDesc(a, b);
      });
    }
    if (sort == InboxSort.waiting) {
      return list..sort((a, b) {
        if (a.waitingSince == null && b.waitingSince == null) return byActivityDesc(a, b);
        if (a.waitingSince == null) return 1;
        if (b.waitingSince == null) return -1;
        return byWaitingAsc(a, b);
      });
    }

    if (q.chip == QuickChip.closed) {
      return list..sort((a, b) => (b.closedAt ?? b.lastActivityAt).compareTo(a.closedAt ?? a.lastActivityAt));
    }
    switch (q.segment) {
      case InboxSegment.mine:
        // Waiting-over-SLA first (longest wait first), then latest activity.
        list.sort((a, b) {
          final aw = a.waitingOverSla(now);
          final bw = b.waitingOverSla(now);
          if (aw && bw) return byWaitingAsc(a, b);
          if (aw != bw) return aw ? -1 : 1;
          return byActivityDesc(a, b);
        });
      case InboxSegment.unassigned:
        list.sort(byWaitingAsc); // oldest first — fairness
      case InboxSegment.all:
        list.sort(byActivityDesc);
    }
    return list;
  }
}
