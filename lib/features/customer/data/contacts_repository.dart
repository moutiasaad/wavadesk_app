import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api_provider.dart';
import '../domain/contact.dart';
import '../domain/contact_attribute.dart';
import '../domain/contact_note.dart';
import 'contacts_api.dart';
import '../../auth/application/auth_session.dart';

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
  // A new sign-in starts over: never show the previous account's data.
  ref.watch(authProvider);
  final repo = HttpContactsRepository(ContactsApi(ref.read(wdApiRequiredProvider)), ref.read(sharedPrefsProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

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
