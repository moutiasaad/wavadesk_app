import '../../../core/models/models.dart';

/// Chat messages use the shared [Message] model; this file maps it to and
/// from the `Message` JSON contract (Chat spec §8).

MessageKind _kind(Object? t) => switch (t) {
  'image' => MessageKind.image,
  'album' => MessageKind.album,
  'video' => MessageKind.video,
  'voice' => MessageKind.voice,
  'file' => MessageKind.file,
  'location' => MessageKind.location,
  'contact' => MessageKind.contact,
  'sticker' => MessageKind.sticker,
  'template' => MessageKind.template,
  'email' => MessageKind.email,
  'deleted' => MessageKind.deleted,
  'text' || 'system' => MessageKind.text,
  _ => MessageKind.unsupported,
};

SystemEventKind _eventKind(Object? k) => switch (k) {
  'claimed' => SystemEventKind.claimed,
  'assigned' => SystemEventKind.assigned,
  'unassigned' => SystemEventKind.unassigned,
  'ai_handoff' => SystemEventKind.aiHandoff,
  'ai_paused' => SystemEventKind.aiPaused,
  'ai_resumed' => SystemEventKind.aiResumed,
  'resolved' => SystemEventKind.resolved,
  'reopened' => SystemEventKind.reopened,
  'snoozed' => SystemEventKind.snoozed,
  'priority' => SystemEventKind.priority,
  'tag_added' => SystemEventKind.tagAdded,
  'window_closed' => SystemEventKind.windowClosed,
  'blocked' => SystemEventKind.blocked,
  'unblocked' => SystemEventKind.unblocked,
  'called' => SystemEventKind.called,
  'assign_undone' => SystemEventKind.assignUndone,
  _ => SystemEventKind.started,
};

String _fmtSize(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Parses one `Message` from the API.
Message messageFromJson(Map<String, dynamic> j, {required String meId}) {
  // Laravel /mobile/v1 shape: `sender` is a string (customer|agent|ai|system).
  if (j['sender'] is String) return _fromMobileV1(j, meId: meId);
  final senderType = j['sender_type'] as String? ?? 'contact';
  final sender = j['sender'] is Map ? Map<String, dynamic>.from(j['sender'] as Map) : null;
  final senderId = sender?['id']?.toString();
  final media = j['media'] is Map ? Map<String, dynamic>.from(j['media'] as Map) : null;
  final location = j['location'] is Map ? Map<String, dynamic>.from(j['location'] as Map) : null;
  final template = j['template'] is Map ? Map<String, dynamic>.from(j['template'] as Map) : null;
  final reply = j['reply_to'] is Map ? Map<String, dynamic>.from(j['reply_to'] as Map) : null;
  final ai = j['ai_meta'] is Map ? Map<String, dynamic>.from(j['ai_meta'] as Map) : null;
  final event = j['system_event'] is Map ? Map<String, dynamic>.from(j['system_event'] as Map) : null;
  final actor = event?['actor'] is Map ? Map<String, dynamic>.from(event!['actor'] as Map) : null;
  final target = event?['target'];

  final type = switch (senderType) {
    'contact' => MessageBubbleType.incoming,
    'ai' => MessageBubbleType.outgoingAi,
    'note' => MessageBubbleType.internalNote,
    'system' => MessageBubbleType.system,
    _ => senderId == meId ? MessageBubbleType.outgoing : MessageBubbleType.outgoingColleague,
  };
  final kind = _kind(j['type']);
  final sources = [
    for (final s in (ai?['kb_sources'] as List? ?? const []))
      if (s is Map) '${s['title']}',
  ];

  return Message(
    id: '${j['id'] ?? j['client_id']}',
    type: type,
    kind: kind,
    text: (j['text'] ?? j['html'] ?? '') as String,
    sentAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    senderId: senderId,
    senderName: sender?['name'] as String?,
    delivery: DeliveryState.values.firstWhere((d) => d.name == j['delivery'], orElse: () => DeliveryState.read),
    quote: reply == null
        ? null
        : QuotedMessage(
            sender: (reply['sender_name'] as String?) ?? '',
            text: (reply['preview'] as String?) ?? '',
            messageId: reply['id']?.toString(),
          ),
    mediaUrl: media?['url'] as String?,
    // Server sends `media.duration` (seconds); `duration_sec` is the older name.
    mediaDuration: switch (media?['duration'] ?? media?['duration_sec']) {
      final num secs => Duration(seconds: secs.round()),
      _ => null,
    },
    fileName: media?['file_name'] as String?,
    fileSize: _fmtSize((media?['size_bytes'] as num?)?.toInt()),
    locationLabel: location?['address'] as String?,
    aiSource: sources.isEmpty ? null : sources.first,
    aiConfidence: (ai?['confidence'] as num?)?.toDouble(),
    reactions: [
      for (final r in (j['reactions'] as List? ?? const []))
        if (r is Map) Reaction(emoji: '${r['emoji']}', byContact: r['by'] == 'contact'),
    ],
    edited: j['edited'] == true,
    mentions: [
      for (final m in (j['mentions'] as List? ?? const []))
        if (m is Map) '${m['name']}',
    ],
    templateName: template?['name'] as String?,
    templateButtons: [for (final b in (template?['buttons'] as List? ?? const [])) '$b'],
    emailSubject: j['subject'] as String?,
    systemEvent: event == null
        ? null
        : SystemEvent(
            kind: _eventKind(event['kind']),
            actorId: actor?['id']?.toString(),
            actorName: actor?['name'] as String? ?? (event['actor'] is String ? event['actor'] as String : null),
            target: target is Map ? target['name'] as String? : target?.toString(),
            value: event['value']?.toString(),
          ),
  );
}

/// Request body for `POST /conversations/{id}/messages`.
Map<String, Object?> outgoingMessageJson({
  required String clientId,
  required MessageKind kind,
  String? text,
  String? mediaUploadId,
  String? replyToId,
  bool isNote = false,
  List<String> mentionIds = const [],
  String? templateName,
  List<String> templateParams = const [],
  String sentVia = 'manual',
  String? rewriteId,
}) => {
  'client_id': clientId,
  'type': kind.name,
  'text': ?text,
  'media_upload_id': ?mediaUploadId,
  'reply_to_id': ?replyToId,
  'is_note': isNote,
  if (mentionIds.isNotEmpty) 'mentions': mentionIds,
  if (templateName != null) 'template': {'name': templateName, 'params': templateParams},
  'sent_via': sentVia,
  'rewrite_id': ?rewriteId,
};

/// `GET /mobile/v1/conversations/{id}/messages` item (MessagePresenter):
/// id, direction, sender, is_note, type, body, media{kind,mime,file_name,
/// voice_note,duration,available}, status, reply_to_id, mentions, sent_at,
/// author{id,name,avatar_url}, reactions[{emoji,count,mine}], created_at.
///
/// Media has no URL here: the repository asks `GET media/{id}/url`.
Message _fromMobileV1(Map<String, dynamic> j, {required String meId}) {
  final sender = j['sender'] as String;
  final isNote = j['is_note'] == true;
  final author = j['author'] is Map ? Map<String, dynamic>.from(j['author'] as Map) : null;
  final media = j['media'] is Map ? Map<String, dynamic>.from(j['media'] as Map) : null;
  final authorId = author?['id']?.toString();
  final type = isNote
      ? MessageBubbleType.internalNote
      : switch (sender) {
          'customer' => MessageBubbleType.incoming,
          'ai' => MessageBubbleType.outgoingAi,
          'system' => MessageBubbleType.system,
          _ => authorId != null && authorId == meId ? MessageBubbleType.outgoing : MessageBubbleType.outgoingColleague,
        };
  final rawType = j['type'] as String? ?? 'text';
  final mediaKind = media?['kind'] as String? ?? rawType;
  final kind = switch (mediaKind) {
    'text' || 'system' || 'chat' => MessageKind.text,
    'image' => MessageKind.image,
    'video' => MessageKind.video,
    'audio' || 'voice' || 'ptt' => MessageKind.voice,
    'document' || 'file' => MessageKind.file,
    'sticker' => MessageKind.sticker,
    'location' => MessageKind.location,
    'contact' || 'vcard' => MessageKind.contact,
    'template' => MessageKind.template,
    'deleted' || 'revoked' => MessageKind.deleted,
    _ => media != null ? MessageKind.file : MessageKind.text,
  };
  final status = j['status'] as String?;
  final delivery = switch (status) {
    'pending' || 'queued' || 'sending' => DeliveryState.sending,
    'sent' => DeliveryState.sent,
    'delivered' => DeliveryState.delivered,
    'read' || 'played' => DeliveryState.read,
    'failed' || 'error' => DeliveryState.failed,
    _ => DeliveryState.read,
  };
  final duration = (media?['duration'] as num?)?.toInt();
  return Message(
    id: '${j['id']}',
    type: type,
    kind: kind,
    text: (j['body'] as String?) ?? '',
    sentAt: DateTime.tryParse((j['sent_at'] ?? j['created_at'] ?? '') as String)?.toLocal() ?? DateTime.now(),
    senderId: authorId,
    senderName: author?['name'] as String?,
    delivery: delivery,
    mediaDuration: duration == null ? null : Duration(seconds: duration),
    fileName: media?['file_name'] as String?,
    mediaAvailable: media?['available'] != false,
    reactions: [
      for (final r in (j['reactions'] as List? ?? const []))
        if (r is Map) Reaction(emoji: '${r['emoji']}', byContact: r['mine'] != true),
    ],
    mentions: [
      for (final m in (j['mentions'] as List? ?? const []))
        m is Map ? '${m['name'] ?? m['id']}' : '$m',
    ],
    quote: j['reply_to_id'] == null ? null : QuotedMessage(sender: '', text: '', messageId: '${j['reply_to_id']}'),
  );
}

/// True when the server said the message has media we host (fetch its URL).
bool mobileV1HasViewableMedia(Map<String, dynamic> j) =>
    j['media'] is Map && (j['media'] as Map)['available'] == true;
