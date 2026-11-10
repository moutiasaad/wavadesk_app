import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/api/wd_api.dart';
import '../../../../core/models/models.dart';
import '../domain/shortcut_validator.dart';
import 'whatsapp_api.dart' show WaApiException;

enum QuickReplyScope {
  team,
  mine;

  /// Server: `team` | `personal` (also accepts `mine` / `tenant`).
  static QuickReplyScope parse(Object? v) => v == 'personal' || v == 'mine' ? mine : team;

  String get wire => this == team ? 'team' : 'personal';

  /// `GET quick-replies?scope=team|mine`.
  String get query => name;
}

@immutable
class QuickReplyAttachment {
  const QuickReplyAttachment({required this.name, required this.mime, required this.sizeBytes, this.url, this.localPath});

  static QuickReplyAttachment? fromJson(Object? j) {
    if (j is! Map) return null;
    return QuickReplyAttachment(
      name: '${j['name'] ?? ''}',
      mime: '${j['mime'] ?? ''}',
      sizeBytes: j['size'] is num ? (j['size'] as num).toInt() : 0,
      url: j['url'] as String?,
    );
  }

  final String name;
  final String mime;
  final int sizeBytes;
  final String? url;

  /// Picked on this device, not uploaded yet.
  final String? localPath;

  bool get isImage => mime.startsWith('image/');
}

/// A saved reply (WhatsApp spec §5.4). The shortcut is stored without `/`.
@immutable
class WaQuickReply {
  const WaQuickReply({
    required this.id,
    required this.shortcut,
    required this.title,
    required this.text,
    this.scope = QuickReplyScope.team,
    this.usageCount = 0,
    this.attachment,
    this.canEdit = true,
  });

  factory WaQuickReply.fromJson(Map<String, dynamic> j) => WaQuickReply(
        id: '${j['id']}',
        shortcut: ShortcutValidator.normalize('${j['shortcut'] ?? ''}'),
        title: '${j['title'] ?? ''}',
        text: '${j['text'] ?? j['body'] ?? ''}',
        scope: QuickReplyScope.parse(j['scope']),
        usageCount: j['usage_count'] is num ? (j['usage_count'] as num).toInt() : 0,
        attachment: QuickReplyAttachment.fromJson(j['attachment']),
        canEdit: j['can_edit'] != false,
      );

  final String id;
  final String shortcut;
  final String title;
  final String text;
  final QuickReplyScope scope;
  final int usageCount;
  final QuickReplyAttachment? attachment;
  final bool canEdit;

  bool get shared => scope == QuickReplyScope.team;

  WaQuickReply copyWith({String? id, String? shortcut, String? title, String? text, QuickReplyScope? scope, QuickReplyAttachment? Function()? attachment}) =>
      WaQuickReply(
        id: id ?? this.id,
        shortcut: shortcut ?? this.shortcut,
        title: title ?? this.title,
        text: text ?? this.text,
        scope: scope ?? this.scope,
        usageCount: usageCount,
        attachment: attachment != null ? attachment() : this.attachment,
        canEdit: canEdit,
      );

  /// The server stores the shortcut with its `/`.
  Map<String, Object?> toWriteJson() => {'title': title, 'shortcut': '/$shortcut', 'body': text, 'scope': scope.wire};

  /// What the chat composer's `/` panel shows.
  QuickReply toComposer() => QuickReply(shortcut: shortcut, title: title, text: text);
}

abstract interface class QuickRepliesApi {
  Future<List<WaQuickReply>> list({QuickReplyScope? scope, String? q});
  Future<WaQuickReply> create(WaQuickReply r);
  Future<WaQuickReply> update(WaQuickReply r);
  Future<void> delete(String id);
  Future<void> reorder(List<String> ids);
}

class HttpQuickRepliesApi implements QuickRepliesApi {
  HttpQuickRepliesApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw WaApiException(e.status, code: e.code, message: e.message, details: e.details);
    }
  }

  @override
  Future<List<WaQuickReply>> list({QuickReplyScope? scope, String? q}) => _guard(() async {
        final r = await _api.get('quick-replies', query: {'scope': ?scope?.query, if (q != null && q.isNotEmpty) 'q': q, 'limit': 50});
        return [for (final m in r.list) WaQuickReply.fromJson(m)];
      });

  @override
  Future<WaQuickReply> create(WaQuickReply r) =>
      _guard(() async => WaQuickReply.fromJson((await _api.post('quick-replies', body: r.toWriteJson())).map));

  @override
  Future<WaQuickReply> update(WaQuickReply r) =>
      _guard(() async => WaQuickReply.fromJson((await _api.patch('quick-replies/${r.id}', body: r.toWriteJson())).map));

  @override
  Future<void> delete(String id) => _guard(() => _api.delete('quick-replies/$id'));

  @override
  Future<void> reorder(List<String> ids) => _guard(() => _api.put('quick-replies/order', body: {'ids': ids}));
}
