import 'package:flutter/foundation.dart';

import 'notification_type.dart';

/// One row of the notifications list (Notifications spec §10 `Notification`).
@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.rawType,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actor,
    this.target,
    this.deeplink,
    this.actions = const [],
    this.groupKey,
    this.groupCount = 1,
    this.severity = NotificationSeverity.info,
    this.readAt,
    this.params = const {},
  });

  final String id;
  final NotificationType type;

  /// Server type string (kept for unknown types and analytics).
  final String rawType;

  /// Server-rendered copy; empty → client template (§5).
  final String title;
  final String body;
  final NotificationActor? actor;
  final NotificationTarget? target;
  final String? deeplink;
  final List<NotificationAction> actions;
  final String? groupKey;
  final int groupCount;
  final NotificationSeverity severity;
  final DateTime? readAt;
  final DateTime createdAt;

  /// Template variables (customer, n, m, topic…) for offline fallback copy.
  final Map<String, Object?> params;

  bool get isRead => readAt != null;

  String? get conversationId => target?.conversationId ?? (target?.kind == 'conversation' ? target?.id : null);

  NotificationItem copyWith({
    DateTime? readAt,
    bool clearRead = false,
    List<NotificationAction>? actions,
  }) =>
      NotificationItem(
        id: id,
        type: type,
        rawType: rawType,
        title: title,
        body: body,
        createdAt: createdAt,
        actor: actor,
        target: target,
        deeplink: deeplink,
        actions: actions ?? this.actions,
        groupKey: groupKey,
        groupCount: groupCount,
        severity: severity,
        readAt: clearRead ? null : (readAt ?? this.readAt),
        params: params,
      );

  /// Tolerates the current server shape too (`sender`, `read: bool`).
  factory NotificationItem.fromJson(Map<String, dynamic> j) {
    final raw = '${j['type'] ?? ''}';
    final created = DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal() ?? DateTime.now();
    DateTime? read = DateTime.tryParse('${j['read_at'] ?? ''}')?.toLocal();
    if (read == null && j['read'] == true) read = created;
    final actorJson = j['actor'] ?? j['sender'];
    final targetJson = j['target'];
    Map<String, Object?> params = j['params'] is Map ? Map<String, Object?>.from(j['params'] as Map) : const {};
    // Older payloads carry the conversation id at the top level.
    final convId = j['conversation_id'] as String?;
    return NotificationItem(
      id: '${j['id']}',
      type: NotificationType.parse(raw),
      rawType: raw,
      title: '${j['title'] ?? ''}',
      body: '${j['body'] ?? ''}',
      createdAt: created,
      actor: actorJson is Map ? NotificationActor.fromJson(Map<String, dynamic>.from(actorJson)) : null,
      target: targetJson is Map
          ? NotificationTarget.fromJson(Map<String, dynamic>.from(targetJson))
          : (convId != null ? NotificationTarget(kind: 'conversation', id: convId, conversationId: convId) : null),
      deeplink: j['deeplink'] as String?,
      actions: [
        for (final a in (j['actions'] as List? ?? const []))
          if (a is Map) NotificationAction.fromJson(Map<String, dynamic>.from(a)),
      ],
      groupKey: j['group_key'] as String?,
      groupCount: (j['group_count'] as num?)?.toInt() ?? 1,
      severity: NotificationSeverity.values.asNameMap()[j['severity']] ?? NotificationSeverity.info,
      readAt: read,
      params: params,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': rawType,
        'title': title,
        'body': body,
        'created_at': createdAt.toUtc().toIso8601String(),
        'read_at': readAt?.toUtc().toIso8601String(),
        'actor': actor?.toJson(),
        'target': target?.toJson(),
        'deeplink': deeplink,
        'actions': [for (final a in actions) a.toJson()],
        'group_key': groupKey,
        'group_count': groupCount,
        'severity': severity.name,
        'params': params,
      };
}

enum NotificationSeverity { info, warning, critical }

@immutable
class NotificationActor {
  const NotificationActor({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;

  factory NotificationActor.fromJson(Map<String, dynamic> j) =>
      NotificationActor(id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}', avatarUrl: j['avatar_url'] as String?);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'avatar_url': avatarUrl};
}

/// `kind`: conversation | message | kb_question | channel | team | billing |
/// store | url (§10).
@immutable
class NotificationTarget {
  const NotificationTarget({required this.kind, this.id, this.conversationId, this.url});

  final String kind;
  final String? id;
  final String? conversationId;
  final String? url;

  factory NotificationTarget.fromJson(Map<String, dynamic> j) => NotificationTarget(
        kind: '${j['kind'] ?? 'url'}',
        id: j['id'] as String?,
        conversationId: j['conversation_id'] as String?,
        url: j['url'] as String?,
      );

  Map<String, Object?> toJson() => {'kind': kind, 'id': id, 'conversation_id': conversationId, 'url': url};
}

enum NotificationActionStyle { primary, secondary }

enum NotificationActionState { available, done, expired }

@immutable
class NotificationAction {
  const NotificationAction({
    required this.id,
    this.label,
    this.style = NotificationActionStyle.primary,
    this.state = NotificationActionState.available,
  });

  /// claim | add_answer | approve | reject | open | reconnect | update
  /// (+ client ids view | reply | review | plans).
  final String id;
  final String? label;
  final NotificationActionStyle style;
  final NotificationActionState state;

  factory NotificationAction.fromJson(Map<String, dynamic> j) => NotificationAction(
        id: '${j['id']}',
        label: j['label'] as String?,
        style: j['style'] == 'secondary' ? NotificationActionStyle.secondary : NotificationActionStyle.primary,
        state: NotificationActionState.values.asNameMap()[j['state']] ?? NotificationActionState.available,
      );

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'style': style.name, 'state': state.name};
}

/// Collapsed run of same-type / same-target rows within 30 min (§4.6
/// "Grouped (stacked)"). [items] is newest first; [head] is the first.
@immutable
class NotificationGroup {
  const NotificationGroup(this.items);

  final List<NotificationItem> items;

  NotificationItem get head => items.first;

  /// Server-side grouping (`group_count`) or client-side stacking.
  int get count => items.length > 1 ? items.length : head.groupCount;

  bool get stacked => count > 1;

  bool get anyUnread => items.any((i) => !i.isRead);
}

/// Client-side stacking: consecutive rows (newest first) of the same type and
/// target within 30 minutes of the run's newest row collapse together.
List<NotificationGroup> stackNotifications(List<NotificationItem> items) {
  const window = Duration(minutes: 30);
  final out = <NotificationGroup>[];
  var run = <NotificationItem>[];
  String key(NotificationItem n) => n.groupKey ?? '${n.conversationId ?? n.id}:${n.rawType}';
  for (final n in items) {
    final canJoin = run.isNotEmpty &&
        n.conversationId != null &&
        key(run.first) == key(n) &&
        run.first.createdAt.difference(n.createdAt).abs() <= window;
    if (canJoin) {
      run.add(n);
    } else {
      if (run.isNotEmpty) out.add(NotificationGroup(run));
      run = [n];
    }
  }
  if (run.isNotEmpty) out.add(NotificationGroup(run));
  return out;
}
