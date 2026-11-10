import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../conversations/domain/conversation_summary.dart';
import '../../customer/data/contacts_repository.dart';
import '../../knowledge/application/knowledge_controller.dart';
import '../../knowledge/domain/kb_entry.dart';
import '../domain/search_query.dart';
import '../domain/snippet_parser.dart';
import 'search_local_index.dart';

class SearchApiException implements Exception {
  const SearchApiException(this.code, {this.statusCode = 0});

  /// network | error
  final String code;
  final int statusCode;

  bool get isNetwork => code == 'network';
}

abstract interface class SearchApi {
  Future<SearchResults> search(SearchQuery query, {String? cursor});

  /// Filters sheet live count (§7).
  Future<int> count(SearchQuery query);
}

/// Offline / sample index over what's on the device right now.
final searchLocalIndexProvider = Provider.autoDispose<SearchLocalIndex>((ref) {
  final inbox = ref.watch(inboxProvider);
  final contacts = ref.read(contactsRepositoryProvider);
  final phones = <String, List<String>>{};
  for (final c in inbox.conversations) {
    final cached = contacts.cached(c.customer.id);
    if (cached == null) continue;
    phones[c.customer.id] = [
      for (final ch in cached.channels)
        if (ch.channel == Channel.whatsapp || ch.channel == Channel.sms) ch.identifier,
    ];
  }
  return SearchLocalIndex(
    conversations: inbox.conversations,
    // Real API: the offline fallback indexes the real KB list (titles only),
    // never the sample data (core/state/load_state.dart rule 5).
    knowledge: useRealApi ? _realKb(ref) : ref.watch(knowledgeProvider),
    agents: [ref.read(currentAgentProvider), if (!useRealApi) ...ref.read(colleaguesProvider)],
    meId: ref.read(currentAgentProvider).id,
    contactPhones: phones,
  );
});

List<KnowledgeEntry> _realKb(Ref ref) => [
      for (final e in ref.watch(knowledgeControllerProvider.select((k) => k.items)))
        if (e.type == KbType.qa && e.status != KbStatus.draft)
          KnowledgeEntry(
            id: e.id,
            type: KnowledgeType.faq,
            title: e.title,
            body: '',
            updatedAt: e.updatedAt,
            enabled: e.enabled,
            usageCount: e.usage30d,
          ),
    ];

final searchApiProvider = Provider.autoDispose<SearchApi>((ref) {
  if (!useRealApi) return SampleSearchApi(() => ref.read(searchLocalIndexProvider));
  return HttpSearchApi(
    ref.read(wdApiRequiredProvider),
    conversationLookup: (id) => ref.read(inboxProvider.notifier).byId(id),
  );
});

// ---- Sample --------------------------------------------------------------------------

/// Demo triggers in the query: `#err` → error, `#slow` → 2s (slow bar).
class SampleSearchApi implements SearchApi {
  SampleSearchApi(this._index);

  final SearchLocalIndex Function() _index;

  SearchQuery _clean(SearchQuery q) =>
      SearchQuery(text: q.text.replaceAll(RegExp(r'#(err|slow)'), '').trim(), scope: q.scope, filters: q.filters);

  @override
  Future<SearchResults> search(SearchQuery query, {String? cursor}) async {
    await Future<void>.delayed(Duration(milliseconds: query.text.contains('#slow') ? 2000 : 220));
    if (query.text.contains('#err')) throw const SearchApiException('error', statusCode: 500);
    final r = _index().search(_clean(query), cursor: cursor);
    return SearchResults(
      query: query,
      normalized: r.normalized,
      intent: r.intent,
      suggestion: r.suggestion,
      bestMatch: r.bestMatch,
      totals: r.totals,
      contacts: r.contacts,
      messages: r.messages,
      kb: r.kb,
      conversations: r.conversations,
      agents: r.agents,
      nextCursor: r.nextCursor,
    );
  }

  @override
  Future<int> count(SearchQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _index().search(_clean(query)).totals.of(query.scope);
  }
}

// ---- HTTP (/mobile/v1) ---------------------------------------------------------------

/// `GET /mobile/v1/search` + `search/count`. Server sections:
/// `{contacts|conversations|messages|kb: {items, next_cursor}}`; highlights are
/// `{text, ranges: [[start, length]]}` (UTF-16) and are turned into the `<em>`
/// markup the result rows already render.
class HttpSearchApi implements SearchApi {
  HttpSearchApi(this._api, {this.conversationLookup});

  final WdApi _api;

  /// Local conversation (if loaded) for a message hit: the server's message
  /// rows carry no contact, so name/avatar/channel come from the inbox.
  final Conversation? Function(String conversationId)? conversationLookup;

  static String _scope(SearchScope s) => switch (s.name) {
    'contacts' => 'contacts',
    'conversations' => 'conversations',
    'messages' => 'messages',
    'kb' => 'kb',
    _ => 'all',
  };

  Map<String, Object?> _params(SearchQuery q, {String? cursor}) {
    final scope = _scope(q.scope);
    return {
      'q': q.text.trim(),
      'scope': scope,
      'limit': scope == 'all' ? null : SearchLocalIndex.pageSize,
      'cursor': scope == 'all' ? null : cursor,
    };
  }

  static String? markup(Object? h) {
    if (h is! Map) return h is String ? h : null;
    final text = '${h['text'] ?? ''}';
    final ranges = <(int, int)>[
      for (final r in (h['ranges'] as List? ?? const []))
        if (r is List && r.length == 2) ((r[0] as num).toInt(), (r[1] as num).toInt()),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final b = StringBuffer();
    var last = 0;
    for (final (start, len) in ranges) {
      if (start < last || start + len > text.length) continue;
      b
        ..write(text.substring(last, start))
        ..write('<em>')
        ..write(text.substring(start, start + len))
        ..write('</em>');
      last = start + len;
    }
    b.write(text.substring(last));
    return b.toString();
  }

  static Channel _channel(Object? v) => switch (v) {
    'wacloud' || 'whatsapp' => Channel.whatsapp,
    _ => Channel.values.where((c) => c.name == v).firstOrNull ?? Channel.other,
  };

  static SearchResults _empty(SearchQuery q) => SearchResults(
    query: q,
    normalized: q.text,
    intent: SearchIntent.text,
    totals: const SearchTotals(contacts: 0, messages: 0, kb: 0, conversations: 0),
  );

  @override
  Future<SearchResults> search(SearchQuery query, {String? cursor}) async {
    final WdResponse r;
    try {
      r = await _api.get('search', query: _params(query, cursor: cursor));
    } on WdApiException catch (e) {
      // "at least 2 characters" etc.: nothing to show, not an error state.
      if (e.code == 'validation_failed') return _empty(query);
      throw SearchApiException(e.isNetwork ? 'network' : 'error', statusCode: e.status);
    }
    final j = r.map;
    final sections = j['sections'] is Map ? Map<String, dynamic>.from(j['sections'] as Map) : const <String, dynamic>{};
    List<Map<String, dynamic>> items(String k) {
      final sec = sections[k];
      final raw = sec is Map ? sec['items'] : null;
      return [
        for (final x in (raw as List? ?? const []))
          if (x is Map) Map<String, dynamic>.from(x),
      ];
    }

    String? cursorOf(String k) {
      final sec = sections[k];
      return sec is Map ? sec['next_cursor'] as String? : null;
    }

    final t = j['totals'] is Map ? Map<String, dynamic>.from(j['totals'] as Map) : const <String, dynamic>{};
    int n(String k) => (t[k] as num?)?.toInt() ?? 0;
    final best = j['best_match'];
    final bestItem = best is Map && best['item'] is Map ? best['item'] as Map : null;
    final scope = _scope(query.scope);

    return SearchResults(
      query: query,
      normalized: (j['normalized'] as String?) ?? query.text,
      intent: SearchIntent.values.where((i) => i.name == j['intent']).firstOrNull ?? SearchIntent.text,
      suggestion: j['suggestion'] as String?,
      bestMatch: best is Map && best['type'] == 'contact' && bestItem != null
          ? BestMatch(contactId: '${bestItem['id']}', confidence: 1)
          : null,
      totals: SearchTotals(
        contacts: n('contacts'),
        messages: n('messages'),
        kb: n('kb'),
        conversations: n('conversations'),
      ),
      contacts: [
        for (final c in items('contacts'))
          ContactHit(
            id: '${c['id']}',
            name: (c['name'] as String?) ?? (c['phone'] as String?) ?? '',
            avatarUrl: c['avatar_url'] as String?,
            channel: Channel.whatsapp,
            matchedField: MatchedField.name,
            matchedValue: (c['name'] as String?) ?? '',
            highlight: markup(c['highlight']),
            hasOpenConversation: false,
            phone: c['phone'] as String?,
          ),
      ],
      messages: [
        for (final m in items('messages'))
          () {
            final convId = '${m['conversation_id']}';
            final conv = conversationLookup?.call(convId);
            final author = m['author'] is Map ? Map<String, dynamic>.from(m['author'] as Map) : null;
            final sender = '${m['sender'] ?? ''}';
            return MessageHit(
              id: '${m['id']}',
              conversationId: convId,
              contactId: conv?.customer.id ?? '',
              contactName: conv?.customer.name ?? '',
              contactAvatarUrl: null,
              channel: conv?.channel ?? _channel(m['channel']),
              senderType: switch (sender) {
                'agent' => HitSender.agent,
                'ai' => HitSender.values.where((s) => s.name == 'ai').firstOrNull ?? HitSender.agent,
                _ => HitSender.contact,
              },
              senderName: author?['name'] as String?,
              isMe: false,
              snippet: markup(m['highlight']) ?? '${m['text'] ?? m['body'] ?? ''}',
              createdAt: DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
              conversationClosed: conv?.isClosed ?? false,
            );
          }(),
      ],
      kb: [
        for (final k in items('kb'))
          () {
            final snippet = markup(k['highlight']);
            final plain = snippet == null ? '' : SnippetParser.plain(snippet);
            final title = (k['title'] as String?) ?? '';
            // Highlight text is "title — body": the answer is what follows.
            final sep = plain.indexOf(' — ');
            return KbHit(
              id: '${k['id']}',
              type: KbHitType.values.where((x) => x.name == k['type']).firstOrNull ?? KbHitType.qa,
              title: title,
              snippet: snippet,
              answer: sep >= 0 ? plain.substring(sep + 3) : plain,
            );
          }(),
      ],
      conversations: [
        for (final c in items('conversations'))
          ConversationHit(
            summary: ConversationSummary.fromJson(c),
            reason: ConversationMatchReason.subject,
            label: SnippetParser.plain(markup(c['highlight']) ?? ''),
          ),
      ],
      nextCursor: scope == 'all' ? null : cursorOf(scope),
    );
  }

  @override
  Future<int> count(SearchQuery query) async {
    try {
      final r = await _api.get('search/count', query: {'q': query.text.trim()});
      final t = r.map['totals'] is Map ? Map<String, dynamic>.from(r.map['totals'] as Map) : const <String, dynamic>{};
      return (t[_scope(query.scope)] as num?)?.toInt() ?? 0;
    } on WdApiException catch (e) {
      if (e.code == 'validation_failed') return 0;
      throw SearchApiException(e.isNetwork ? 'network' : 'error', statusCode: e.status);
    }
  }
}
