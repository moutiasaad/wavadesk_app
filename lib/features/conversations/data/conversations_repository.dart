import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api.dart' show useRealApi;
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
  Future<UndoAction> snooze(List<ConversationSummary> items, DateTime until);
  Future<UndoAction> archive(List<ConversationSummary> items);
  Future<UndoAction> setReadBulk(List<ConversationSummary> items, {required bool read});
  Future<UndoAction> setPriority(List<ConversationSummary> items, Priority priority);
  Future<UndoAction> addTag(List<ConversationSummary> items, String tag);
}

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  if (!useRealApi) {
    final repo = SampleConversationsRepository(ref);
    ref.listen(inboxProvider.select((s) => s.conversations), (_, _) => repo.notifyChanged());
    ref.onDispose(repo.dispose);
    return repo;
  }
  final auth = ref.read(authRepositoryProvider);
  final repo = HttpConversationsRepository(
    ConversationsApi(ref.read(wdApiRequiredProvider)),
    prefs: ref.read(sharedPrefsProvider),
    userId: '${auth.session?.user['id'] ?? 'me'}',
  );
  ref.onDispose(repo.dispose);
  return repo;
});

// ---- Sample data (no backend) -----------------------------------------------------

/// Serves rows from the in-memory [InboxController] so the list, chat and
/// every other screen stay in sync. Mirrors server filtering/sorting via
/// [InboxRules]; pagination uses an offset cursor.
class SampleConversationsRepository implements ConversationsRepository {
  SampleConversationsRepository(this._ref);

  final Ref _ref;
  final _changes = StreamController<void>.broadcast();
  bool _firstLoad = true;

  InboxController get _inbox => _ref.read(inboxProvider.notifier);
  String get _meId => _ref.read(currentAgentProvider).id;

  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() => _changes.close();

  @override
  Stream<void> get changes => _changes.stream;

  List<String> _teamsFor(String customerId) {
    final teams = MockData.teams;
    var h = 0;
    for (final u in customerId.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return [teams[h % teams.length].id];
  }

  List<ConversationSummary> _all() => [
    for (final c in _ref.read(inboxProvider).conversations)
      ConversationSummary.fromConversation(c, meId: _meId, teamIds: _teamsFor(c.customer.id)),
  ];

  void _ensureOnline() {
    if (_ref.read(inboxProvider).network == NetworkState.offline) {
      throw const ConversationsApiException(0);
    }
  }

  @override
  Future<ConversationsPage> fetch(InboxQuery q, {String? cursor, int limit = 30}) async {
    if (_firstLoad) {
      _firstLoad = false;
      await Future<void>.delayed(const Duration(milliseconds: 900)); // first-load skeleton
    } else if (cursor != null) {
      await Future<void>.delayed(const Duration(milliseconds: 600)); // page latency
    }
    _ensureOnline();
    final now = DateTime.now();
    final all = _all();
    final matching = InboxRules.sort(
      [
        for (final c in all)
          if (InboxRules.matches(q, c, _meId, now)) c,
      ],
      q,
      now,
    );
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final end = (offset + limit).clamp(0, matching.length);
    final open = all.where((c) => c.isActive);
    return ConversationsPage(
      items: matching.sublist(offset.clamp(0, matching.length), end),
      nextCursor: end < matching.length ? '$end' : null,
      counts: {
        'mine': open.where((c) => c.isMine(_meId)).length,
        'unassigned': open.where((c) => c.assignee == null).length,
        'unread': all
            .where(
              (c) =>
                  InboxRules.inSegment(q.segment, c, _meId) &&
                  InboxRules.statusMatches(q.copyWith(chip: QuickChip.all), c, now) &&
                  c.isUnread,
            )
            .length,
      },
    );
  }

  @override
  Future<int> count(InboxQuery q) async {
    final now = DateTime.now();
    return _all().where((c) => InboxRules.matches(q, c, _meId, now)).length;
  }

  @override
  ConversationsPage? cached(InboxSegment segment) => null; // data is already in memory

  @override
  Future<void> saveCache(InboxSegment segment, ConversationsPage page) async {}

  @override
  Future<void> setRead(String id, {required bool read}) async => read ? _inbox.markRead(id) : _inbox.markUnread(id);

  @override
  Future<String?> claim(String id) async {
    _ensureOnline();
    return _inbox.claimChecked(id);
  }

  Future<UndoAction> _bulk(List<ConversationSummary> items, void Function(String id) action) async {
    final snapshots = _inbox.bulk({for (final i in items) i.id}, action);
    return () async => _inbox.restoreAll(snapshots);
  }

  @override
  Future<UndoAction> resolve(List<ConversationSummary> items) => _bulk(items, _inbox.resolve);

  @override
  Future<UndoAction> snooze(List<ConversationSummary> items, DateTime until) =>
      _bulk(items, (id) => _inbox.snooze(id, until));

  @override
  Future<UndoAction> archive(List<ConversationSummary> items) => _bulk(items, _inbox.archive);

  @override
  Future<UndoAction> setReadBulk(List<ConversationSummary> items, {required bool read}) =>
      _bulk(items, read ? _inbox.markRead : _inbox.markUnread);

  @override
  Future<UndoAction> setPriority(List<ConversationSummary> items, Priority priority) =>
      _bulk(items, (id) => _inbox.setPriority(id, priority));

  @override
  Future<UndoAction> addTag(List<ConversationSummary> items, String tag) => _bulk(items, (id) {
    if (!(_inbox.byId(id)?.tags.contains(tag) ?? true)) _inbox.toggleTag(id, tag);
  });
}

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
