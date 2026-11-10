import '../../../core/models/models.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../conversations/domain/conversation_summary.dart';
import '../domain/search_intent_detector.dart';
import '../domain/search_query.dart';
import '../domain/snippet_parser.dart';

/// Searches data already on the device: contacts of cached conversations,
/// their last 200 messages, KB entries (Search spec §8 offline). Also the
/// sample-mode backend.
class SearchLocalIndex {
  SearchLocalIndex({
    required this.conversations,
    required this.knowledge,
    required this.agents,
    required this.meId,
    this.contactPhones = const {},
  });

  final List<Conversation> conversations;
  final List<KnowledgeEntry> knowledge;
  final List<Agent> agents;
  final String meId;

  /// Extra phone numbers from cached contact profiles (contactId → phones).
  final Map<String, List<String>> contactPhones;

  static const maxMessagesPerConversation = 200;
  static const allLimits = (contacts: 3, messages: 5, kb: 3, conversations: 3);
  static const pageSize = 20;

  static KbHitType _kbType(KnowledgeType t) => switch (t) {
    KnowledgeType.website => KbHitType.link,
    KnowledgeType.policy || KnowledgeType.product => KbHitType.file,
    _ => KbHitType.qa,
  };

  bool _inWindow(DateTime t, SearchFilters f, DateTime now) {
    final since = f.since(now);
    final until = f.until();
    if (since != null && t.isBefore(since)) return false;
    if (until != null && t.isAfter(until.add(const Duration(days: 1)))) return false;
    return true;
  }

  bool _conversationPasses(Conversation c, SearchFilters f) {
    if (f.channels.isNotEmpty && !f.channels.contains(c.channel)) return false;
    if (f.status == SearchStatusFilter.open && c.isClosed) return false;
    if (f.status == SearchStatusFilter.resolved && !c.isClosed) return false;
    if (f.assignee == SearchAssigneeFilter.me && c.assignee?.id != meId) return false;
    if (f.assignee == SearchAssigneeFilter.colleague) {
      if (c.assignee == null || c.assignee!.id == meId) return false;
      if (f.colleagueId != null && c.assignee!.id != f.colleagueId) return false;
    }
    return true;
  }

  HitSender _sender(Message m) => switch (m.type) {
    MessageBubbleType.incoming => HitSender.contact,
    MessageBubbleType.outgoingAi => HitSender.ai,
    MessageBubbleType.internalNote => HitSender.note,
    _ => HitSender.agent,
  };

  bool _messagePasses(Message m, SearchFilters f, DateTime now) {
    if (m.type == MessageBubbleType.system) return false;
    if (!_inWindow(m.sentAt, f, now)) return false;
    final s = _sender(m);
    final mine = m.senderId == meId;
    switch (f.sender) {
      case SearchSender.all:
        break;
      case SearchSender.contact:
        if (s != HitSender.contact) return false;
      case SearchSender.me:
        if (!mine || s == HitSender.note) return false;
      case SearchSender.colleagues:
        if (s != HitSender.agent || mine) return false;
      case SearchSender.ai:
        if (s != HitSender.ai) return false;
      case SearchSender.notes:
        if (s != HitSender.note) return false;
    }
    if (f.contains.isNotEmpty) {
      final ok =
          (f.contains.contains(SearchContains.attachments) && m.kind == MessageKind.file) ||
          (f.contains.contains(SearchContains.images) &&
              (m.kind == MessageKind.image || m.kind == MessageKind.album)) ||
          (f.contains.contains(SearchContains.voice) && m.kind == MessageKind.voice);
      if (!ok) return false;
    }
    return true;
  }

  String _searchable(Message m) => [m.text, m.fileName ?? ''].where((s) => s.isNotEmpty).join(' ');

  SearchResults search(SearchQuery query, {String? cursor, bool local = false}) {
    final now = DateTime.now();
    final raw = query.text.trim();
    final q = ArabicNormalizer.normalize(raw);
    final intent = SearchIntentDetector.detect(raw);
    final f = query.filters;
    final convs = [
      for (final c in conversations)
        if (_conversationPasses(c, f)) c,
    ];

    // ---- Contacts
    final contacts = <ContactHit>[];
    final seen = <String>{};
    for (final c in convs) {
      final cu = c.customer;
      if (!seen.add(cu.id)) continue;
      final phones = [?cu.phone, ...?contactPhones[cu.id]];
      MatchedField? field;
      var value = '';
      if (intent == SearchIntent.phone || (q.length >= 3 && RegExp(r'^\+?[\d\s-]+$').hasMatch(q))) {
        for (final p in phones) {
          if (SearchIntentDetector.phoneMatches(p, raw)) {
            field = MatchedField.phone;
            value = p;
            break;
          }
        }
      }
      if (field == null && ArabicNormalizer.matches(cu.name, q)) {
        field = MatchedField.name;
        value = cu.phone ?? cu.email ?? '';
      }
      if (field == null && cu.email != null && ArabicNormalizer.matches(cu.email!, q)) {
        field = MatchedField.email;
        value = cu.email!;
      }
      if (field == null) {
        for (final t in cu.tags) {
          if (ArabicNormalizer.matches(t, q)) {
            field = MatchedField.tag;
            value = t;
            break;
          }
        }
      }
      if (field == null && cu.city != null && ArabicNormalizer.matches(cu.city!, q)) {
        field = MatchedField.attribute;
        value = cu.city!;
      }
      if (field == null) continue;
      final open = conversations.any((x) => x.customer.id == cu.id && !x.isClosed);
      final last =
          (conversations.where((x) => x.customer.id == cu.id).toList()
                ..sort((a, b) => _lastAt(b).compareTo(_lastAt(a))))
              .firstOrNull;
      contacts.add(
        ContactHit(
          id: cu.id,
          name: cu.name,
          avatarUrl: cu.avatarUrl,
          channel: cu.channel,
          matchedField: field,
          matchedValue: value,
          highlight: field == MatchedField.name ? SnippetParser.mark(cu.name, q) : null,
          hasOpenConversation: open,
          phone: cu.phone,
          lastConversationId: last?.id,
        ),
      );
    }

    // ---- Messages (best hit per conversation + "+n")
    final messages = <MessageHit>[];
    var messageTotal = 0;
    if (intent != SearchIntent.mention && q.isNotEmpty) {
      for (final c in convs) {
        final list = c.messages.length > maxMessagesPerConversation
            ? c.messages.sublist(c.messages.length - maxMessagesPerConversation)
            : c.messages;
        final hits = [
          for (final m in list.reversed)
            if (_messagePasses(m, f, now) && ArabicNormalizer.matches(_searchable(m), q)) m,
        ];
        if (hits.isEmpty) continue;
        messageTotal += hits.length;
        final m = hits.first; // newest
        final s = _sender(m);
        messages.add(
          MessageHit(
            id: m.id,
            conversationId: c.id,
            contactId: c.customer.id,
            contactName: c.customer.name,
            contactAvatarUrl: c.customer.avatarUrl,
            channel: c.channel,
            senderType: s,
            senderName: m.senderName,
            isMe: m.senderId == meId,
            snippet: SnippetParser.build(_searchable(m), q),
            createdAt: m.sentAt,
            moreInConversation: hits.length - 1,
            conversationClosed: c.isClosed,
          ),
        );
      }
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // ---- KB (titles + body)
    final kb = <KbHit>[];
    if (intent == SearchIntent.text && q.isNotEmpty && f.isEmpty) {
      for (final e in knowledge) {
        final inTitle = ArabicNormalizer.matches(e.title, q) || e.keywords.any((k) => ArabicNormalizer.matches(k, q));
        final inBody = !local && ArabicNormalizer.matches(e.body, q);
        if (!inTitle && !inBody) continue;
        kb.add(
          KbHit(
            id: e.id,
            type: _kbType(e.type),
            title: e.title,
            titleHighlight: SnippetParser.mark(e.title, q),
            snippet: inTitle ? null : SnippetParser.build(e.body, q),
            usageMonth: e.usageCount,
            answer: e.body,
          ),
        );
      }
    }

    // ---- Conversations: order numbers and tags (§6.5)
    final convHits = <ConversationHit>[];
    final order = intent == SearchIntent.order ? SearchIntentDetector.orderNumber(raw) : null;
    if (intent == SearchIntent.order || (q.isNotEmpty && intent == SearchIntent.text)) {
      for (final c in convs) {
        ConversationHit? hit;
        if (intent == SearchIntent.order) {
          final re = order == null ? RegExp(r'#?\b(\d{3,})\b') : RegExp('#?\\b$order\\d*\\b');
          for (final m in c.messages.reversed) {
            final mm = re.firstMatch(ArabicNormalizer.normalize(m.text));
            if (mm != null && _inWindow(m.sentAt, f, now)) {
              hit = ConversationHit(
                summary: ConversationSummary.fromConversation(c, meId: meId, teamIds: const []),
                reason: ConversationMatchReason.order,
                label: '#${mm.group(0)!.replaceAll('#', '')}',
              );
              break;
            }
          }
        } else {
          for (final t in {...c.tags, ...c.customer.tags}) {
            if (ArabicNormalizer.matches(t, q)) {
              hit = ConversationHit(
                summary: ConversationSummary.fromConversation(c, meId: meId, teamIds: const []),
                reason: ConversationMatchReason.tag,
                label: t,
              );
              break;
            }
          }
        }
        if (hit != null) convHits.add(hit);
      }
    }

    // ---- Teammates for "@"
    final agentHits = intent == SearchIntent.mention
        ? [
            for (final a in agents)
              if (ArabicNormalizer.matches(a.name, ArabicNormalizer.normalize(raw.substring(1)))) AgentHit(agent: a),
          ]
        : const <AgentHit>[];

    // Best match: one exact phone / email contact (§6.6).
    BestMatch? best;
    if ((intent == SearchIntent.phone || intent == SearchIntent.email) && contacts.length == 1) {
      final c = contacts.first;
      final exact = intent == SearchIntent.phone
          ? SearchIntentDetector.phoneCore(c.matchedValue) == SearchIntentDetector.phoneCore(raw)
          : ArabicNormalizer.normalize(c.matchedValue) == q;
      if (exact) best = BestMatch(contactId: c.id, confidence: 0.97);
    }

    final totals = SearchTotals(
      contacts: contacts.length,
      messages: messageTotal,
      kb: kb.length,
      conversations: convHits.length,
    );

    // Scoped pages vs. "الكل" previews.
    int offset = int.tryParse(cursor ?? '') ?? 0;
    List<T> page<T>(List<T> all, SearchScope s, int preview) {
      if (query.scope == SearchScope.all) return all.take(preview).toList();
      if (query.scope != s) return const [];
      return all.skip(offset).take(pageSize).toList();
    }

    final scopedLen = switch (query.scope) {
      SearchScope.contacts => contacts.length,
      SearchScope.messages => messages.length,
      SearchScope.kb => kb.length,
      SearchScope.conversations => convHits.length,
      SearchScope.all => 0,
    };
    final next = query.scope != SearchScope.all && offset + pageSize < scopedLen ? '${offset + pageSize}' : null;

    return SearchResults(
      query: query,
      normalized: q,
      intent: intent,
      suggestion: totals.all == 0 && agentHits.isEmpty ? _didYouMean(q) : null,
      bestMatch: best,
      totals: totals,
      contacts: page(contacts, SearchScope.contacts, allLimits.contacts),
      messages: page(messages, SearchScope.messages, allLimits.messages),
      kb: page(kb, SearchScope.kb, allLimits.kb),
      conversations: page(convHits, SearchScope.conversations, allLimits.conversations),
      agents: agentHits,
      nextCursor: next,
      local: local,
    );
  }

  DateTime _lastAt(Conversation c) => c.messages.isEmpty ? DateTime(2000) : c.messages.last.sentAt;

  /// Closest known word (edit distance ≤ 1, or 2 for long words).
  String? _didYouMean(String q) {
    if (q.length < 3 || q.contains(' ')) return null;
    final vocab = <String>{};
    void add(String s) {
      for (final w in ArabicNormalizer.normalize(s).split(RegExp(r'[^\p{L}\d]+', unicode: true))) {
        if (w.length >= 3) vocab.add(w.startsWith('ال') && w.length > 4 ? w.substring(2) : w);
      }
    }

    for (final c in conversations) {
      add(c.customer.name);
      for (final m in c.messages) {
        add(m.text);
      }
    }
    for (final e in knowledge) {
      add(e.title);
    }
    final limit = q.length >= 6 ? 2 : 1;
    String? best;
    var bestD = limit + 1;
    for (final w in vocab) {
      if ((w.length - q.length).abs() > limit) continue;
      final d = _distance(q, w, limit);
      if (d > 0 && d < bestD) {
        bestD = d;
        best = w;
      }
    }
    return best;
  }

  static int _distance(String a, String b, int cap) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
        if (cur[j] < rowMin) rowMin = cur[j];
      }
      if (rowMin > cap) return cap + 1;
      prev = cur;
    }
    return prev[b.length];
  }
}
