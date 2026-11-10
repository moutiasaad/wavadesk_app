import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/analytics.dart';
import '../data/contacts_repository.dart';
import '../domain/contact_note.dart';

final contactNotesProvider = Provider.family<ContactNotesActions, String>((ref, contactId) => ContactNotesActions(ref, contactId));

/// Team-note actions (Profile spec §5.5, §7.3). The repository applies them
/// optimistically and the profile controller re-renders from its change
/// stream.
class ContactNotesActions {
  ContactNotesActions(this._ref, this.contactId);

  final Ref _ref;
  final String contactId;

  ContactsRepository get _repo => _ref.read(contactsRepositoryProvider);

  /// Max 2,000 chars (§7.3).
  static const maxLength = 2000;
  static const counterFrom = 1800;

  Future<ContactNote> add(String text, {List<String> mentions = const [], bool pinned = false}) {
    Analytics.log('profile_note_add', {'pinned': pinned, 'mentions_count': mentions.length});
    return _repo.addNote(contactId, text: text.trim(), mentions: mentions, pinned: pinned);
  }

  Future<void> edit(String noteId, String text) => _repo.editNote(contactId, noteId, text.trim());

  Future<void> setPinned(String noteId, bool pinned) => _repo.setNotePinned(contactId, noteId, pinned);

  Future<void> delete(String noteId) => _repo.deleteNote(contactId, noteId);
}
