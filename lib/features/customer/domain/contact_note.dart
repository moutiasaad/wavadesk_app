import 'package:flutter/foundation.dart';

/// Contact-level team note (Profile spec §5.5, §7.3). Persists across
/// conversations, unlike chat internal notes (conversation-level).
@immutable
class ContactNote {
  const ContactNote({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.mentions = const [],
    this.pinned = false,
    this.updatedAt,
  });

  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Mentioned teammate names (rendered bold).
  final List<String> mentions;
  final bool pinned;

  ContactNote copyWith({String? text, bool? pinned, List<String>? mentions}) => ContactNote(
        id: id,
        text: text ?? this.text,
        authorId: authorId,
        authorName: authorName,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        mentions: mentions ?? this.mentions,
        pinned: pinned ?? this.pinned,
      );

  factory ContactNote.fromJson(Map<String, dynamic> j) {
    final author = j['author'] is Map ? Map<String, dynamic>.from(j['author'] as Map) : const <String, dynamic>{};
    return ContactNote(
      // `id` is null for the read-only legacy note (customers.notes text).
      id: '${j['id'] ?? 'legacy'}',
      text: (j['text'] as String?) ?? (j['body'] as String?) ?? '',
      authorId: '${author['id'] ?? j['author_id'] ?? ''}',
      authorName: (author['name'] as String?) ?? (j['author_name'] as String?) ?? '',
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? '')?.toLocal(),
      mentions: [
        for (final m in (j['mentions'] as List? ?? const [])) m is Map ? '${m['name']}' : '$m',
      ],
      pinned: j['pinned'] == true,
    );
  }

  /// Pinned first, then newest first (§5.5).
  static List<ContactNote> sorted(Iterable<ContactNote> notes) => [...notes]
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
}
