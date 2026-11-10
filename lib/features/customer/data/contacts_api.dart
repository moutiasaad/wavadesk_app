import '../../../core/api/wd_api.dart';
import '../domain/contact.dart';

class ContactsApiException implements Exception {
  const ContactsApiException(this.statusCode, {this.code, this.message});

  /// 0 = transport failure.
  final int statusCode;

  /// `/mobile/v1` error code (`not_found`, `role_forbidden`, …).
  final String? code;

  /// Server message, already localised.
  final String? message;
  bool get isNetwork => statusCode == 0;
}

/// Client for `/mobile/v1/contacts/*` (Profile spec §9, server
/// `Mobile\V1\ContactController`). Contact ids are opaque `ct_…`.
class ContactsApi {
  ContactsApi(this._api);

  final WdApi _api;

  /// Profile includes the app renders. `orders` is skipped: the server has no
  /// e-commerce integration and always answers `[]`.
  static const _include = 'stats,notes,channels,ai_summary';

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw ContactsApiException(e.status, code: e.code, message: e.message);
    }
  }

  /// Raw `data` of `GET contacts/{id}` (the repository caches it as-is).
  Future<Map<String, dynamic>> getRaw(String id) =>
      _wrap(() async => (await _api.get('contacts/$id', query: {'include': _include})).map);

  /// `GET contacts/{id}/conversations` → conversation summaries, newest first.
  Future<WdResponse> conversations(String id, {String? cursor, int limit = 10}) =>
      _wrap(() => _api.get('contacts/$id/conversations', query: {'limit': limit, 'cursor': cursor}));

  /// Only `display_name` (and `tags`) are editable on the server.
  Future<void> patch(String id, Map<String, Object?> body) => _wrap(() => _api.patch('contacts/$id', body: body));

  /// Replaces the contact's tags (plain strings; new ones are created).
  Future<void> putTags(String id, List<String> tags) => _wrap(() => _api.put('contacts/$id/tags', body: {'tags': tags}));

  Future<Map<String, dynamic>> addNote(String id, {required String body, required bool pinned}) =>
      _wrap(() async => (await _api.post('contacts/$id/notes', body: {'body': body, 'pinned': pinned})).map);

  Future<void> patchNote(String id, String noteId, {String? body, bool? pinned}) => _wrap(
        () => _api.patch('contacts/$id/notes/$noteId', body: {'body': ?body, 'pinned': ?pinned}),
      );

  Future<void> deleteNote(String id, String noteId) => _wrap(() => _api.delete('contacts/$id/notes/$noteId'));

  Future<void> block(String id, {String? reason}) =>
      _wrap(() => _api.post('contacts/$id/block', body: {'reason': reason}));

  Future<void> unblock(String id) => _wrap(() => _api.delete('contacts/$id/block'));

  /// Returns the new `ai_summary` object (or null).
  Future<Map<String, dynamic>?> regenerateSummary(String id) => _wrap(() async {
        final s = (await _api.post('contacts/$id/ai-summary/regenerate', body: const <String, Object?>{})).map['ai_summary'];
        return s is Map ? Map<String, dynamic>.from(s) : null;
      });

  /// The server merges [sourceId] INTO [targetId] and keeps the target.
  Future<void> merge({required String targetId, required String sourceId}) =>
      _wrap(() => _api.post('contacts/$targetId/merge', body: {'source_id': sourceId}));

  /// GDPR/PDPL erase (admins). 202 + job reference. The server reads
  /// `?erase=true` from the query string.
  Future<void> erase(String id) => _wrap(() => _api.delete('contacts/$id', query: {'erase': 'true'}));

  /// Workspace tags (`GET tags`), most used first.
  Future<List<ContactTag>> searchTags(String q) => _wrap(() async {
        final r = await _api.get('tags', query: {'q': q.trim(), 'limit': 50});
        return [
          for (final t in r.list) ContactTag(id: '${t['name']}', name: '${t['name']}', system: t['name'] == 'VIP'),
        ];
      });
}
