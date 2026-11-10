import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api.dart' show useRealApi;
import '../../../core/api/wd_api_provider.dart';
import '../domain/contact.dart';
import '../domain/contact_attribute.dart';
import '../domain/contact_note.dart';
import 'contacts_api.dart';

/// A row in "المحادثات السابقة" (Profile spec §5.9).
enum PastConversationState { closedBy, aiReplied, openNow }

@immutable
class PastConversation {
  const PastConversation({
    required this.id,
    required this.channel,
    required this.title,
    required this.date,
    required this.state,
    this.closedBy,
    this.assignedToSomeone = false,
  });

  final String id;
  final Channel channel;

  /// AI topic summary, or the first customer message.
  final String title;
  final DateTime date;
  final PastConversationState state;
  final String? closedBy;

  /// Still open and owned → open normally instead of read-only.
  final bool assignedToSomeone;
}

@immutable
class PastConversationsPage {
  const PastConversationsPage({required this.items, this.nextCursor});

  final List<PastConversation> items;
  final String? nextCursor;
}

/// Field edits from the Edit Contact screen (§7.1).
@immutable
class ContactEdit {
  const ContactEdit({this.name, this.phone, this.email, this.city, this.language, this.attributes});

  final String? name;
  final String? phone;
  final String? email;
  final String? city;
  final String? language;
  final List<ContactAttribute>? attributes;
}

abstract interface class ContactsRepository {
  /// Last known copy (cache-first render, §6 "Cached").
  Contact? cached(String id);
  Future<Contact> fetch(String id);

  /// Emits a contact id whenever that contact changed (realtime §8).
  Stream<String> get changes;

  Future<PastConversationsPage> conversations(String id, {Channel? channel, String? excludeId, String? cursor});

  Future<void> update(String id, ContactEdit edit);
  Future<void> setTags(String id, List<ContactTag> tags, {String? conversationId});
  Future<List<ContactTag>> searchTags(String q);

  Future<ContactNote> addNote(String id, {required String text, required List<String> mentions, required bool pinned});
  Future<void> editNote(String id, String noteId, String text);
  Future<void> setNotePinned(String id, String noteId, bool pinned);
  Future<void> deleteNote(String id, String noteId);

  Future<void> block(String id, {String? reason});
  Future<void> unblock(String id);
  Future<void> regenerateSummary(String id);

  /// Contacts to merge into (admin search).
  List<Contact> search(String q, {required String excludeId});
  Future<void> merge(String id, {required String intoId, required Map<String, String> fieldChoices});
  Future<void> erase(String id);
}

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  if (!useRealApi) {
    final repo = SampleContactsRepository(ref);
    ref.listen(inboxProvider.select((s) => s.conversations), (_, _) => repo.inboxChanged());
    ref.onDispose(repo.dispose);
    return repo;
  }
  final repo = HttpContactsRepository(ContactsApi(ref.read(wdApiRequiredProvider)), ref.read(sharedPrefsProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

// ---- Sample data ------------------------------------------------------------------

/// Builds profiles from the in-memory inbox (`conversations.json`) plus
/// `assets/fake/contacts.json`. Edits live in memory and propagate to every
/// conversation of the contact (name, tags, block…).
class SampleContactsRepository implements ContactsRepository {
  SampleContactsRepository(this._ref);

  final Ref _ref;
  final _changes = StreamController<String>.broadcast();
  final Map<String, Contact> _store = {};
  int _seq = 0;

  InboxController get _inbox => _ref.read(inboxProvider.notifier);

  void dispose() => _changes.close();

  /// Inbox changed (a block from the chat, a new conversation…): refresh
  /// derived fields of known contacts.
  void inboxChanged() {
    for (final id in _store.keys.toList()) {
      final fresh = _derive(id, _store[id]);
      if (fresh != null) {
        _store[id] = fresh;
        if (!_changes.isClosed) _changes.add(id);
      }
    }
  }

  @override
  Stream<String> get changes => _changes.stream;

  List<Conversation> _conversationsOf(String id) =>
      [for (final c in _ref.read(inboxProvider).conversations) if (c.customer.id == id) c];

  Customer? _customer(String id) {
    final list = _conversationsOf(id);
    return list.isEmpty ? null : list.first.customer;
  }

  /// Rebuilds a contact, keeping edits already held in [previous].
  Contact? _derive(String id, Contact? previous) {
    final cu = _customer(id);
    if (cu == null) return null;
    final x = MockData.contactExtras(id);
    final convs = _conversationsOf(id);
    final me = _ref.read(currentAgentProvider);

    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        [for (final v in (x[key] as List? ?? const [])) if (v is Map) f(Map<String, dynamic>.from(v))];

    final channelCounts = <Channel, int>{};
    for (final c in convs) {
      channelCounts[c.channel] = (channelCounts[c.channel] ?? 0) + 1;
    }
    final declared = list('channels', (m) => ContactChannel(
          channel: Channel.values.firstWhere((ch) => ch.name == m['channel'], orElse: () => Channel.other),
          identifier: '${m['identifier']}',
        ));
    final channels = [
      for (final d in declared) ContactChannel(channel: d.channel, identifier: d.identifier, conversations: channelCounts[d.channel] ?? 0),
      for (final e in channelCounts.entries)
        if (!declared.any((d) => d.channel == e.key))
          ContactChannel(
            channel: e.key,
            identifier: (e.key == Channel.email ? cu.email : cu.phone) ?? cu.channelIds[e.key] ?? '—',
            conversations: e.value,
          ),
    ];

    final via = x['created_via'] is Map ? Map<String, dynamic>.from(x['created_via'] as Map) : const <String, dynamic>{};
    final summary = x['ai_summary'] is Map ? Map<String, dynamic>.from(x['ai_summary'] as Map) : null;
    final store = MockData.storeIntegration != null;
    final visitor = x['visitor'] is Map ? Map<String, dynamic>.from(x['visitor'] as Map) : const <String, dynamic>{};

    final tags = x['tags'] is List
        ? list('tags', ContactTag.fromJson)
        : [for (final t in cu.tags) ContactTag(id: t, name: t, system: t == 'VIP')];
    final attributes = x['attributes'] is List
        ? list('attributes', ContactAttribute.fromJson)
        : [
            for (final e in cu.customFields.entries)
              ContactAttribute(key: e.key, label: e.key, type: AttributeType.text, value: e.value),
          ];
    final notes = x['notes'] is List
        ? list(
            'notes',
            (m) => ContactNote(
              id: '${m['id']}',
              text: '${m['text']}',
              authorId: '${m['author_id'] ?? ''}',
              authorName: '${m['author_name'] ?? ''}',
              createdAt: MockData.agoMinutes(m['ago_minutes']),
              mentions: [for (final v in (m['mentions'] as List? ?? const [])) '$v'],
              pinned: m['pinned'] == true,
            ),
          )
        : [
            for (var i = 0; i < cu.notes.length; i++)
              ContactNote(
                id: 'legacy-$i',
                text: cu.notes[i].text,
                authorId: '',
                authorName: cu.notes[i].author,
                createdAt: cu.notes[i].createdAt,
              ),
          ];
    final orders = store && x['orders'] is List
        ? list(
            'orders',
            (m) => ContactOrder(
              id: '${m['id']}',
              number: '${m['number']}',
              date: MockData.agoMinutes(m['ago_minutes']),
              itemsCount: (m['items_count'] as num?)?.toInt() ?? 0,
              total: (m['total'] as num?)?.toDouble() ?? 0,
              status: OrderStatus.values.firstWhere((s) => s.name == m['status'], orElse: () => OrderStatus.processing),
              url: m['url'] as String?,
            ),
          )
        : null;
    final firstContact = cu.firstContact ??
        convs.expand((c) => c.messages).map((m) => m.sentAt).fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);

    final base = Contact(
      id: id,
      name: cu.name.trim().isEmpty ? null : cu.name,
      avatarUrl: cu.avatarUrl,
      phone: cu.phone,
      email: cu.email,
      city: cu.city,
      language: x['language'] as String?,
      timezone: x['timezone'] as String?,
      isVip: x['is_vip'] == true || cu.tags.contains('VIP'),
      isBlocked: cu.blocked,
      tags: tags,
      attributes: attributes,
      createdAt: via['ago_minutes'] == null ? (firstContact ?? DateTime.now()) : MockData.agoMinutes(via['ago_minutes']),
      createdViaChannel: via['channel'] == null
          ? cu.channel
          : Channel.values.firstWhere((c) => c.name == via['channel'], orElse: () => cu.channel),
      createdViaAgent: via['agent_name'] as String?,
      conversationsCount: cu.conversationsCount > convs.length ? cu.conversationsCount : convs.length,
      ordersCount: store ? (orders?.length ?? cu.ordersCount) : null,
      csat: (x['csat'] as num?)?.toDouble(),
      firstContactAt: firstContact,
      // AI summary only with ≥ 2 past conversations (§5.4).
      aiSummary: summary != null && convs.length >= 2
          ? AiSummary(text: '${summary['text']}', generatedAt: MockData.agoMinutes(summary['ago_minutes']))
          : null,
      notes: notes,
      channels: channels,
      orders: orders,
      ordersTotalSpent: store ? (x['orders_total_spent'] as num?)?.toDouble() : null,
      permissions: ContactPermissions.forRole(me.role),
      visitorBrowser: visitor['browser'] as String?,
      visitorPage: visitor['page'] as String?,
    );
    if (previous == null) return base;
    // Keep in-app edits; refresh live fields from the inbox.
    return previous.copyWith(
      isBlocked: cu.blocked,
      conversationsCount: base.conversationsCount,
      channels: base.channels,
      name: cu.name.trim().isEmpty ? null : cu.name,
      phone: cu.phone,
      email: cu.email,
      city: cu.city,
    );
  }

  @override
  Contact? cached(String id) => _store[id];

  @override
  Future<Contact> fetch(String id) async {
    await Future<void>.delayed(Duration(milliseconds: _store.containsKey(id) ? 200 : 450));
    if (_ref.read(inboxProvider).network == NetworkState.offline) {
      final c = _store[id];
      if (c != null) return c;
      throw const ContactsApiException(0);
    }
    final c = _derive(id, _store[id]);
    if (c == null) throw const ContactsApiException(404);
    _store[id] = c;
    return c;
  }

  void _put(String id, Contact c) {
    _store[id] = c;
    if (!_changes.isClosed) _changes.add(id);
  }

  Contact _require(String id) => _store[id] ?? (throw const ContactsApiException(404));

  @override
  Future<PastConversationsPage> conversations(String id, {Channel? channel, String? excludeId, String? cursor}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final rows = <PastConversation>[];
    final convs = _conversationsOf(id).where((c) => c.id != excludeId && (channel == null || c.channel == channel)).toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    for (final c in convs) {
      final first = c.messages.where((m) => m.type == MessageBubbleType.incoming).firstOrNull;
      final title = first == null ? '' : (first.emailSubject ?? (first.text.isNotEmpty ? first.text : first.kind.name));
      final aiOnly = c.ownership == Ownership.ai || (c.messages.any((m) => m.type == MessageBubbleType.outgoingAi) &&
          !c.messages.any((m) => m.type == MessageBubbleType.outgoing || m.type == MessageBubbleType.outgoingColleague));
      rows.add(PastConversation(
        id: c.id,
        channel: c.channel,
        title: title,
        date: c.lastActivity,
        state: !c.isClosed ? PastConversationState.openNow : (aiOnly ? PastConversationState.aiReplied : PastConversationState.closedBy),
        closedBy: c.assignee?.name,
        assignedToSomeone: !c.isClosed && c.assignee != null,
      ));
    }
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final end = (offset + 10).clamp(0, rows.length);
    return PastConversationsPage(items: rows.sublist(offset.clamp(0, rows.length), end), nextCursor: end < rows.length ? '$end' : null);
  }

  @override
  Future<void> update(String id, ContactEdit e) async {
    final c = _require(id);
    _inbox.updateCustomer(
      id,
      (cu) => cu.copyWith(
        name: e.name,
        phone: e.phone,
        email: e.email,
        city: e.city,
        customFields: e.attributes == null ? null : {for (final a in e.attributes!) if (!a.isEmpty) a.label: '${a.value}'},
      ),
    );
    _put(id, c.copyWith(name: e.name, phone: e.phone, email: e.email, city: e.city, language: e.language, attributes: e.attributes));
  }

  @override
  Future<void> setTags(String id, List<ContactTag> tags, {String? conversationId}) async {
    final c = _require(id);
    final added = [for (final t in tags) if (!c.tags.any((x) => x.name == t.name)) t.name];
    _inbox.updateCustomer(id, (cu) => cu.copyWith(tags: [for (final t in tags) t.name]));
    // System event in the current conversation for each added tag (§7.2).
    if (conversationId != null) {
      for (final t in added) {
        _inbox.addSystemEvent(conversationId, SystemEventKind.tagAdded, value: t);
      }
    }
    _put(id, c.copyWith(tags: tags, isVip: tags.any((t) => t.name == 'VIP') || c.isVip && tags.any((t) => t.id == 'vip')));
  }

  @override
  Future<List<ContactTag>> searchTags(String q) async {
    final all = <String, ContactTag>{};
    for (final c in _store.values) {
      for (final t in c.tags) {
        all[t.name] = t;
      }
    }
    for (final t in _ref.read(allTagsProvider)) {
      all.putIfAbsent(t, () => ContactTag(id: t, name: t));
    }
    final query = q.trim().toLowerCase();
    return [for (final t in all.values) if (query.isEmpty || t.name.toLowerCase().contains(query)) t];
  }

  @override
  Future<ContactNote> addNote(String id, {required String text, required List<String> mentions, required bool pinned}) async {
    final c = _require(id);
    final me = _ref.read(currentAgentProvider);
    final note = ContactNote(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      text: text,
      authorId: me.id,
      authorName: me.name,
      createdAt: DateTime.now(),
      mentions: mentions,
      pinned: pinned,
    );
    _put(id, c.copyWith(notes: [note, ...c.notes]));
    return note;
  }

  @override
  Future<void> editNote(String id, String noteId, String text) async {
    final c = _require(id);
    _put(id, c.copyWith(notes: [for (final n in c.notes) n.id == noteId ? n.copyWith(text: text) : n]));
  }

  @override
  Future<void> setNotePinned(String id, String noteId, bool pinned) async {
    final c = _require(id);
    _put(id, c.copyWith(notes: [for (final n in c.notes) n.id == noteId ? n.copyWith(pinned: pinned) : n]));
  }

  @override
  Future<void> deleteNote(String id, String noteId) async {
    final c = _require(id);
    _put(id, c.copyWith(notes: [for (final n in c.notes) if (n.id != noteId) n]));
  }

  @override
  Future<void> block(String id, {String? reason}) async {
    final c = _require(id);
    _inbox.setCustomerBlocked(id, true);
    _put(id, c.copyWith(isBlocked: true, blockedReason: reason));
  }

  @override
  Future<void> unblock(String id) async {
    final c = _require(id);
    _inbox.setCustomerBlocked(id, false);
    _put(id, c.copyWith(isBlocked: false, clearBlockedReason: true));
  }

  @override
  Future<void> regenerateSummary(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final c = _require(id);
    final convs = _conversationsOf(id).length;
    _put(
      id,
      c.copyWith(
        aiSummary: AiSummary(
          text: '${c.name ?? ''} تواصلت معنا $convs مرات عبر ${c.channels.length} قنوات. '
              'تهتم بسرعة التوصيل والمقاسات، وتفضّل الرد السريع عبر واتساب. آخر طلباتها قيد التجهيز.',
          generatedAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  List<Contact> search(String q, {required String excludeId}) {
    final query = q.trim().toLowerCase();
    final seen = <String>{};
    final out = <Contact>[];
    for (final conv in _ref.read(inboxProvider).conversations) {
      final cu = conv.customer;
      if (cu.id == excludeId || !seen.add(cu.id)) continue;
      final hay = '${cu.name} ${cu.phone ?? ''} ${cu.email ?? ''}'.toLowerCase();
      if (query.isNotEmpty && !hay.contains(query)) continue;
      out.add(_store[cu.id] ?? Contact(id: cu.id, name: cu.name, phone: cu.phone, email: cu.email, city: cu.city, createdAt: DateTime.now()));
      if (out.length >= 20) break;
    }
    return out;
  }

  @override
  Future<void> merge(String id, {required String intoId, required Map<String, String> fieldChoices}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final from = _require(id);
    final intoCustomer = _customer(intoId);
    if (intoCustomer == null) return;
    String? pick(String field, String? fromV, String? intoV) => fieldChoices[field] == 'from' ? fromV : (intoV ?? fromV);
    final merged = intoCustomer.copyWith(
      name: pick('name', from.name, intoCustomer.name),
      phone: pick('phone', from.phone, intoCustomer.phone),
      email: pick('email', from.email, intoCustomer.email),
      city: pick('city', from.city, intoCustomer.city),
    );
    _inbox.mergeCustomer(id, merged);
    _inbox.updateCustomer(intoId, (_) => merged);
    final into = _store[intoId];
    if (into != null) _put(intoId, into.copyWith(notes: [...from.notes, ...into.notes]));
    _store.remove(id);
    if (!_changes.isClosed) _changes.add(id);
  }

  @override
  Future<void> erase(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _inbox.eraseCustomer(id);
    _store.remove(id);
    if (!_changes.isClosed) _changes.add(id);
  }
}

// ---- Real backend --------------------------------------------------------------

/// `/mobile/v1/contacts` + per-contact cache in SharedPreferences (TTL 10
/// min, always revalidated on open — §9). The cache holds the raw API JSON.
///
/// Server limits (v1): only the display name and tags are editable, tags
/// are plain strings, contacts exist for WhatsApp customers only (`ct_…`).
class HttpContactsRepository implements ContactsRepository {
  HttpContactsRepository(this._api, this._prefs);

  final ContactsApi _api;
  final SharedPreferences _prefs;
  final _changes = StreamController<String>.broadcast();
  final Map<String, Contact> _memory = {};
  static const _ttl = Duration(minutes: 10);

  void dispose() => _changes.close();

  @override
  Stream<String> get changes => _changes.stream;

  void _touch(String id) {
    if (!_changes.isClosed) _changes.add(id);
  }

  @override
  Contact? cached(String id) {
    final m = _memory[id];
    if (m != null) return m;
    final raw = _prefs.getString('contact_cache_$id');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(j['_cached_at'] as String? ?? '');
      if (at == null || DateTime.now().difference(at) > _ttl) return null;
      return Contact.fromMobileJson(Map<String, dynamic>.from(j['data'] as Map));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Contact> fetch(String id) async {
    final Map<String, dynamic> j;
    try {
      j = await _api.getRaw(id);
    } on ContactsApiException catch (e) {
      if (e.statusCode == 404) _forget(id); // FLUTTER_CLIENT_NOTES §6: drop on 404
      rethrow;
    }
    final c = Contact.fromMobileJson(j);
    _memory[id] = c;
    unawaited(_prefs.setString('contact_cache_$id', jsonEncode({'_cached_at': DateTime.now().toIso8601String(), 'data': j})));
    return c;
  }

  void _forget(String id) {
    _memory.remove(id);
    _prefs.remove('contact_cache_$id');
  }

  @override
  Future<PastConversationsPage> conversations(String id, {Channel? channel, String? excludeId, String? cursor}) async {
    final r = await _api.conversations(id, cursor: cursor);
    return PastConversationsPage(
      nextCursor: r.nextCursor,
      items: [
        for (final row in r.list)
          if (row['id'] != excludeId && (channel == null || row['channel'] == channel.name)) _past(row),
      ],
    );
  }

  /// A conversation summary (server ConversationPresenter::summary).
  static PastConversation _past(Map<String, dynamic> r) {
    final status = r['status'] as String?;
    final assignee = r['assignee'] is Map ? (r['assignee'] as Map)['name'] as String? : null;
    final open = status != 'resolved';
    return PastConversation(
      id: '${r['id']}',
      channel: Channel.values.firstWhere((c) => c.name == r['channel'], orElse: () => Channel.whatsapp),
      title: ((r['title'] as String?)?.trim().isNotEmpty ?? false) ? r['title'] as String : '${r['preview'] ?? ''}',
      date: DateTime.tryParse('${r['last_activity_at']}')?.toLocal() ?? DateTime.now(),
      state: open
          ? PastConversationState.openNow
          // Closed with nobody holding it and the AI on it → the AI handled it.
          : (assignee == null && r['ai_handling'] == true ? PastConversationState.aiReplied : PastConversationState.closedBy),
      closedBy: assignee,
      assignedToSomeone: open && assignee != null,
    );
  }

  @override
  Future<void> update(String id, ContactEdit e) async {
    // v1 server: only the display name is editable (phone, email, city,
    // language and custom attributes are not part of the mobile contract).
    if (e.name != null) await _api.patch(id, {'display_name': e.name!.trim().isEmpty ? null : e.name!.trim()});
    _touch(id);
  }

  @override
  Future<void> setTags(String id, List<ContactTag> tags, {String? conversationId}) async {
    await _api.putTags(id, [for (final t in tags) t.name]);
    _touch(id);
  }

  @override
  Future<List<ContactTag>> searchTags(String q) => _api.searchTags(q);

  @override
  Future<ContactNote> addNote(String id, {required String text, required List<String> mentions, required bool pinned}) async {
    // Mentions are not stored by the server; the names stay in the text.
    final j = await _api.addNote(id, body: text, pinned: pinned);
    _touch(id);
    return ContactNote.fromJson(j);
  }

  @override
  Future<void> editNote(String id, String noteId, String text) async {
    await _api.patchNote(id, noteId, body: text);
    _touch(id);
  }

  @override
  Future<void> setNotePinned(String id, String noteId, bool pinned) async {
    await _api.patchNote(id, noteId, pinned: pinned);
    _touch(id);
  }

  @override
  Future<void> deleteNote(String id, String noteId) async {
    await _api.deleteNote(id, noteId);
    _touch(id);
  }

  @override
  Future<void> block(String id, {String? reason}) async {
    await _api.block(id, reason: reason);
    _touch(id);
  }

  @override
  Future<void> unblock(String id) async {
    await _api.unblock(id);
    _touch(id);
  }

  @override
  Future<void> regenerateSummary(String id) async {
    await _api.regenerateSummary(id);
    _touch(id);
  }

  /// Merge targets among contacts already opened in this session (the
  /// mobile API has no contact search endpoint).
  @override
  List<Contact> search(String q, {required String excludeId}) {
    final query = q.trim().toLowerCase();
    return [
      for (final c in _memory.values)
        if (c.id != excludeId && '${c.name ?? ''} ${c.phone ?? ''}'.toLowerCase().contains(query)) c,
    ];
  }

  /// App semantics: [id] goes away, [intoId] stays. The server merges the
  /// `source_id` into the path contact. [fieldChoices] are not supported by
  /// the server (the kept contact keeps its own fields).
  @override
  Future<void> merge(String id, {required String intoId, required Map<String, String> fieldChoices}) async {
    await _api.merge(targetId: intoId, sourceId: id);
    _forget(id);
    _touch(id);
    _touch(intoId);
  }

  @override
  Future<void> erase(String id) async {
    await _api.erase(id);
    _forget(id);
    _touch(id);
  }
}
