import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../auth/application/auth_session.dart';
import '../domain/conversation_filters.dart';
import '../domain/conversation_summary.dart';
import 'conversations_api.dart';

/// Reverts an optimistic action (Undo snackbar).
typedef UndoAction = Future<void> Function();

/// Source of inbox rows + the actions on them (Inbox spec §6).
abstract interface class ConversationsRepository {
  /// Fires when local data changed and the visible window should be re-read.
  Stream<void> get changes;

  Future<ConversationsPage> fetch(InboxQuery q, {String? cursor, int limit = 30});

  /// Live count for the Filters sheet button.
  Future<int> count(InboxQuery q);

  /// Last page persisted for a segment → instant render on cold start.
  ConversationsPage? cached(InboxSegment segment);
  Future<void> saveCache(InboxSegment segment, ConversationsPage page);

  Future<void> setRead(String id, {required bool read});

  /// Returns the colleague's name when it was already claimed (409).
  Future<String?> claim(String id);

  Future<UndoAction> resolve(List<ConversationSummary> items);
  Future<UndoAction> reopen(List<ConversationSummary> items);

  /// Bulk claim (selection bar); undo releases them again.
  Future<UndoAction> claimBulk(List<ConversationSummary> items);
  Future<UndoAction> snooze(List<ConversationSummary> items, DateTime until);
  Future<UndoAction> archive(List<ConversationSummary> items);
  Future<UndoAction> setReadBulk(List<ConversationSummary> items, {required bool read});
  Future<UndoAction> setPriority(List<ConversationSummary> items, Priority priority);
  Future<UndoAction> addTag(List<ConversationSummary> items, String tag);
}

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  // A new sign-in starts over: never show the previous account's data.
  ref.watch(authProvider);
  final auth = ref.read(authRepositoryProvider);
  final repo = HttpConversationsRepository(
    ConversationsApi(ref.read(wdApiRequiredProvider)),
    prefs: ref.read(sharedPrefsProvider),
    userId: '${auth.session?.user['id'] ?? 'me'}',
  );
  ref.onDispose(repo.dispose);
  return repo;
});

// ---- Real backend ----------------------------------------------------------------

/// Network + local cache. The last page of each segment is persisted in
/// SharedPreferences (JSON) so a cold start renders instantly (§6 Caching).
class HttpConversationsRepository implements ConversationsRepository {
  HttpConversationsRepository(this._api, {required SharedPreferences prefs, required String userId})
    : _prefs = prefs,
      _userId = userId;

  final ConversationsApi _api;
  final SharedPreferences _prefs;
  final String _userId;
  final _changes = StreamController<void>.broadcast();

  void dispose() => _changes.close();

  @override
  Stream<void> get changes => _changes.stream;

  String _cacheKey(InboxSegment s) => 'inbox_cache_${_userId}_${s.name}';

  @override
  Future<ConversationsPage> fetch(InboxQuery q, {String? cursor, int limit = 30}) =>
      _api.list(q, cursor: cursor, limit: limit);

  @override
  Future<int> count(InboxQuery q) => _api.count(q);

  @override
  ConversationsPage? cached(InboxSegment segment) {
    final raw = _prefs.getString(_cacheKey(segment));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return ConversationsPage(
        items: [
          for (final i in (j['items'] as List)) ConversationSummary.fromJson(Map<String, dynamic>.from(i as Map)),
        ],
        nextCursor: j['next_cursor'] as String?,
        counts: {for (final e in (j['counts'] as Map).entries) '${e.key}': (e.value as num).toInt()},
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCache(InboxSegment segment, ConversationsPage page) => _prefs.setString(
    _cacheKey(segment),
    jsonEncode({
      'items': [for (final i in page.items.take(30)) i.toJson()],
      'next_cursor': page.nextCursor,
      'counts': page.counts,
    }),
  );

  @override
  Future<void> setRead(String id, {required bool read}) => read ? _api.read(id) : _api.unread(id);

  @override
  Future<String?> claim(String id) async {
    try {
      await _api.claim(id);
      return null;
    } on ConversationsApiException catch (e) {
      if (e.statusCode == 409) return e.claimedBy ?? '';
      rethrow;
    }
  }

  Set<String> _ids(List<ConversationSummary> items) => {for (final i in items) i.id};

  Future<UndoAction> _reopenUndo(List<ConversationSummary> items) async =>
      () => _api.bulk(_ids(items), 'reopen');

  @override
  Future<UndoAction> resolve(List<ConversationSummary> items) async {
    await _api.bulk(_ids(items), 'resolve');
    return _reopenUndo(items);
  }

  @override
  Future<UndoAction> reopen(List<ConversationSummary> items) async {
    await _api.bulk(_ids(items), 'reopen');
    return () => _api.bulk(_ids(items), 'resolve');
  }

  @override
  Future<UndoAction> claimBulk(List<ConversationSummary> items) async {
    await _api.bulk(_ids(items), 'claim');
    return () => _api.bulk(_ids(items), 'unassign');
  }

  @override
  Future<UndoAction> snooze(List<ConversationSummary> items, DateTime until) async {
    await _api.bulk(_ids(items), 'snooze', {'until': until.toUtc().toIso8601String()});
    return () => _api.bulk(_ids(items), 'unsnooze');
  }

  @override
  Future<UndoAction> archive(List<ConversationSummary> items) async {
    // The server has no archive state: archiving resolves the conversation.
    await _api.bulk(_ids(items), 'resolve');
    return _reopenUndo(items);
  }

  @override
  Future<UndoAction> setReadBulk(List<ConversationSummary> items, {required bool read}) async {
    await _api.bulk(_ids(items), read ? 'read' : 'unread');
    return () => _api.bulk(_ids(items), read ? 'unread' : 'read');
  }

  @override
  Future<UndoAction> setPriority(List<ConversationSummary> items, Priority priority) async {
    await _api.bulk(_ids(items), 'priority', {'priority': ConversationsApi.priorityValue(priority)});
    return () async {
      for (final i in items) {
        await _api.bulk({i.id}, 'priority', {'priority': ConversationsApi.priorityValue(i.priority)});
      }
    };
  }

  @override
  Future<UndoAction> addTag(List<ConversationSummary> items, String tag) async {
    await _api.bulk(_ids(items), 'tags', {'tags': [tag], 'mode': 'add'});
    final added = [
      for (final i in items)
        if (!i.tags.contains(tag)) i.id,
    ];
    return () => _api.bulk(added.toSet(), 'tags', {'tags': [tag], 'mode': 'remove'});
  }
}
