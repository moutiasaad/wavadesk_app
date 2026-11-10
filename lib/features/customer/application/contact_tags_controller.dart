import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/analytics.dart';
import '../data/contacts_repository.dart';
import '../domain/contact.dart';

final contactTagsProvider = Provider.family<ContactTagsActions, String>((ref, contactId) => ContactTagsActions(ref, contactId));

/// Tag editor actions (Profile spec §7.2): changes apply in one batch on
/// "تم"; added tags log a system event in the current conversation.
class ContactTagsActions {
  ContactTagsActions(this._ref, this.contactId);

  final Ref _ref;
  final String contactId;

  ContactsRepository get _repo => _ref.read(contactsRepositoryProvider);

  Future<List<ContactTag>> search(String q) => _repo.searchTags(q);

  /// New tags carry an id prefixed `new:` (created server-side).
  static ContactTag create(String name) => ContactTag(id: 'new:${name.trim()}', name: name.trim());

  Future<void> apply({required List<ContactTag> before, required List<ContactTag> after, String? conversationId}) {
    final added = after.where((t) => !before.any((b) => b.name == t.name)).length;
    final removed = before.where((t) => !after.any((a) => a.name == t.name)).length;
    Analytics.log('profile_tag_change', {'added': added, 'removed': removed});
    return _repo.setTags(contactId, after, conversationId: conversationId);
  }
}
