import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import '../../conversations/domain/conversation_summary.dart';

/// Scope chips (Search spec §4.2).
enum SearchScope { all, contacts, messages, kb, conversations }

/// Query shape (§6.6).
enum SearchIntent { text, phone, email, order, mention }

enum SearchDateRange { any, today, days7, days30, custom }

/// "المرسل" (§7). `notes` = internal notes.
enum SearchSender { all, contact, me, colleagues, ai, notes }

enum SearchStatusFilter { all, open, resolved }

enum SearchAssigneeFilter { all, me, colleague }

enum SearchContains { attachments, images, voice }

/// Filters sheet state (§7).
@immutable
class SearchFilters {
  const SearchFilters({
    this.channels = const {},
    this.date = SearchDateRange.any,
    this.from,
    this.to,
    this.sender = SearchSender.all,
    this.status = SearchStatusFilter.all,
    this.assignee = SearchAssigneeFilter.all,
    this.colleagueId,
    this.contains = const {},
  });

  static const empty = SearchFilters();

  final Set<Channel> channels;
  final SearchDateRange date;
  final DateTime? from;
  final DateTime? to;
  final SearchSender sender;
  final SearchStatusFilter status;
  final SearchAssigneeFilter assignee;
  final String? colleagueId;
  final Set<SearchContains> contains;

  int get activeCount =>
      (channels.isNotEmpty ? 1 : 0) +
      (date != SearchDateRange.any ? 1 : 0) +
      (sender != SearchSender.all ? 1 : 0) +
      (status != SearchStatusFilter.all ? 1 : 0) +
      (assignee != SearchAssigneeFilter.all ? 1 : 0) +
      (contains.isNotEmpty ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  /// Inclusive start of the date window, or null for "any".
  DateTime? since(DateTime now) => switch (date) {
    SearchDateRange.any => null,
    SearchDateRange.today => DateTime(now.year, now.month, now.day),
    SearchDateRange.days7 => now.subtract(const Duration(days: 7)),
    SearchDateRange.days30 => now.subtract(const Duration(days: 30)),
    SearchDateRange.custom => from,
  };

  DateTime? until() => date == SearchDateRange.custom ? to : null;

  /// §9 query parameters.
  Map<String, String> toQuery() => {
    if (channels.isNotEmpty) 'channels': channels.map((c) => c.name).join(','),
    if (date != SearchDateRange.any)
      'date': date == SearchDateRange.custom
          ? '${from?.toIso8601String() ?? ''}..${to?.toIso8601String() ?? ''}'
          : switch (date) {
              SearchDateRange.today => 'today',
              SearchDateRange.days7 => '7d',
              _ => '30d',
            },
    if (sender != SearchSender.all) 'sender': sender.name,
    if (status != SearchStatusFilter.all) 'status': status.name,
    if (assignee != SearchAssigneeFilter.all)
      'assignee': assignee == SearchAssigneeFilter.colleague ? (colleagueId ?? 'colleague') : 'me',
    if (contains.isNotEmpty) 'has': contains.map((c) => c.name).join(','),
  };

  SearchFilters copyWith({
    Set<Channel>? channels,
    SearchDateRange? date,
    DateTime? from,
    DateTime? to,
    SearchSender? sender,
    SearchStatusFilter? status,
    SearchAssigneeFilter? assignee,
    String? colleagueId,
    bool clearColleague = false,
    Set<SearchContains>? contains,
  }) => SearchFilters(
    channels: channels ?? this.channels,
    date: date ?? this.date,
    from: from ?? this.from,
    to: to ?? this.to,
    sender: sender ?? this.sender,
    status: status ?? this.status,
    assignee: assignee ?? this.assignee,
    colleagueId: clearColleague ? null : (colleagueId ?? this.colleagueId),
    contains: contains ?? this.contains,
  );

  String get cacheKey => toQuery().entries.map((e) => '${e.key}=${e.value}').join('&');

  @override
  bool operator ==(Object other) => other is SearchFilters && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

@immutable
class SearchQuery {
  const SearchQuery({required this.text, this.scope = SearchScope.all, this.filters = SearchFilters.empty});

  final String text;
  final SearchScope scope;
  final SearchFilters filters;

  String get cacheKey => '${scope.name}|${text.trim()}|${filters.cacheKey}';
}

// ---- Results (§9) ---------------------------------------------------------------------

enum MatchedField { name, phone, email, tag, attribute }

@immutable
class ContactHit {
  const ContactHit({
    required this.id,
    required this.name,
    required this.channel,
    required this.matchedField,
    required this.matchedValue,
    this.avatarUrl,
    this.highlight,
    this.hasOpenConversation = false,
    this.phone,
    this.lastConversationId,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final Channel channel;
  final MatchedField matchedField;
  final String matchedValue;

  /// Server `<em>` markup for the name, when the match is there.
  final String? highlight;
  final bool hasOpenConversation;
  final String? phone;
  final String? lastConversationId;
}

enum HitSender { contact, agent, ai, note }

@immutable
class MessageHit {
  const MessageHit({
    required this.id,
    required this.conversationId,
    required this.contactId,
    required this.contactName,
    required this.channel,
    required this.senderType,
    required this.snippet,
    required this.createdAt,
    this.contactAvatarUrl,
    this.senderName,
    this.isMe = false,
    this.moreInConversation = 0,
    this.conversationClosed = false,
  });

  final String id;
  final String conversationId;
  final String contactId;
  final String contactName;
  final String? contactAvatarUrl;
  final Channel channel;
  final HitSender senderType;
  final String? senderName;
  final bool isMe;

  /// `<em>` markup, ±40 chars around the first match.
  final String snippet;
  final DateTime createdAt;
  final int moreInConversation;
  final bool conversationClosed;
}

enum KbHitType { qa, file, link }

@immutable
class KbHit {
  const KbHit({
    required this.id,
    required this.type,
    required this.title,
    this.titleHighlight,
    this.snippet,
    this.usageMonth = 0,
    this.answer = '',
  });

  final String id;
  final KbHitType type;
  final String title;
  final String? titleHighlight;
  final String? snippet;
  final int usageMonth;

  /// Full answer for "إدراج في الرد".
  final String answer;
}

enum ConversationMatchReason { order, tag, subject }

@immutable
class ConversationHit {
  const ConversationHit({required this.summary, required this.reason, required this.label});

  final ConversationSummary summary;
  final ConversationMatchReason reason;

  /// "#2841" / "VIP" — the chip text after the reason prefix.
  final String label;
}

@immutable
class AgentHit {
  const AgentHit({required this.agent});
  final Agent agent;
}

@immutable
class BestMatch {
  const BestMatch({required this.contactId, required this.confidence});
  final String contactId;
  final double confidence;
}

@immutable
class SearchTotals {
  const SearchTotals({this.contacts = 0, this.messages = 0, this.kb = 0, this.conversations = 0});

  final int contacts;
  final int messages;
  final int kb;
  final int conversations;

  int get all => contacts + messages + kb + conversations;

  int of(SearchScope s) => switch (s) {
    SearchScope.all => all,
    SearchScope.contacts => contacts,
    SearchScope.messages => messages,
    SearchScope.kb => kb,
    SearchScope.conversations => conversations,
  };
}

@immutable
class SearchResults {
  const SearchResults({
    required this.query,
    this.normalized = '',
    this.intent = SearchIntent.text,
    this.suggestion,
    this.bestMatch,
    this.totals = const SearchTotals(),
    this.contacts = const [],
    this.messages = const [],
    this.kb = const [],
    this.conversations = const [],
    this.agents = const [],
    this.nextCursor,
    this.local = false,
  });

  final SearchQuery query;
  final String normalized;
  final SearchIntent intent;
  final String? suggestion;
  final BestMatch? bestMatch;
  final SearchTotals totals;
  final List<ContactHit> contacts;
  final List<MessageHit> messages;
  final List<KbHit> kb;
  final List<ConversationHit> conversations;

  /// `@` intent — teammates (§6.6).
  final List<AgentHit> agents;
  final String? nextCursor;

  /// From the offline local index (§8) — headers say "(محليًا)".
  final bool local;

  bool get isEmpty => totals.all == 0 && agents.isEmpty;

  SearchResults appendPage(SearchResults next) => SearchResults(
    query: query,
    normalized: normalized,
    intent: intent,
    suggestion: suggestion,
    bestMatch: bestMatch,
    totals: totals,
    contacts: [...contacts, ...next.contacts],
    messages: [...messages, ...next.messages],
    kb: [...kb, ...next.kb],
    conversations: [...conversations, ...next.conversations],
    agents: agents,
    nextCursor: next.nextCursor,
    local: local,
  );
}
