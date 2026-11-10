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

class SampleQuickRepliesApi implements QuickRepliesApi {
  SampleQuickRepliesApi({required List<QuickReply> seed}) {
    var i = 0;
    _rows.addAll([
      const WaQuickReply(id: 'qr_d1', shortcut: 'delivery', title: 'مدة التوصيل', text: 'يصل طلبك خلال 2–3 أيام عمل داخل المدن الرئيسية، و5–7 أيام لباقي المناطق.', usageCount: 48),
      const WaQuickReply(id: 'qr_d2', shortcut: 'return', title: 'سياسة الإرجاع', text: 'يمكنك الإرجاع خلال 30 يومًا من الاستلام بشرط أن يكون المنتج بحالته الأصلية.', usageCount: 31),
      const WaQuickReply(id: 'qr_d3', shortcut: 'thanks', title: 'شكر العميل', text: 'شكرًا لتواصلك معنا يا {اسم_العميل}! نسعد بخدمتك دائمًا 🌸', usageCount: 27),
      const WaQuickReply(id: 'qr_d4', shortcut: 'wait', title: 'لحظات من فضلك', text: 'لحظات من فضلك، أتحقق من التفاصيل وأعود إليك.', usageCount: 19),
      const WaQuickReply(id: 'qr_d5', shortcut: 'track', title: 'تتبع الطلب', text: 'تقدر تتابع طلبك من هنا: {رابط_التتبع}', usageCount: 12),
      for (final r in seed)
        WaQuickReply(id: 'qr_s${i++}', shortcut: 'reply${i + 5}', title: r.title, text: r.text, usageCount: 3),
      const WaQuickReply(id: 'qr_m1', shortcut: 'hi', title: 'تحية شخصية', text: 'أهلًا {اسم_العميل}، معك نورة من فريق الدعم 👋', scope: QuickReplyScope.mine, usageCount: 22),
      const WaQuickReply(id: 'qr_m2', shortcut: 'bye', title: 'ختام المحادثة', text: 'سعدت بخدمتك! لا تتردد بالتواصل معنا متى احتجت.', scope: QuickReplyScope.mine, usageCount: 9),
    ]);
  }

  final List<WaQuickReply> _rows = [];
  int _seq = 1;

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Future<List<WaQuickReply>> list({QuickReplyScope? scope, String? q}) async {
    await _wait();
    final term = (q ?? '').trim().toLowerCase();
    return [
      for (final r in _rows)
        if ((scope == null || r.scope == scope) &&
            (term.isEmpty || r.title.toLowerCase().contains(term) || r.shortcut.contains(term) || r.text.toLowerCase().contains(term)))
          r,
    ];
  }

  void _checkUnique(WaQuickReply r) {
    if (_rows.any((x) => x.id != r.id && x.scope == r.scope && x.shortcut == r.shortcut)) {
      throw const WaApiException(422, code: 'shortcut_taken');
    }
  }

  @override
  Future<WaQuickReply> create(WaQuickReply r) async {
    await _wait();
    _checkUnique(r);
    final saved = r.copyWith(id: 'qr_n${_seq++}');
    _rows.insert(0, saved);
    return saved;
  }

  @override
  Future<WaQuickReply> update(WaQuickReply r) async {
    await _wait();
    _checkUnique(r);
    final i = _rows.indexWhere((x) => x.id == r.id);
    if (i < 0) throw const WaApiException(404, code: 'not_found');
    _rows[i] = r;
    return r;
  }

  @override
  Future<void> delete(String id) async {
    await _wait();
    _rows.removeWhere((x) => x.id == id);
  }

  @override
  Future<void> reorder(List<String> ids) async {
    await _wait();
    final byId = {for (final r in _rows) r.id: r};
    final ordered = [for (final id in ids) ?byId.remove(id)];
    _rows
      ..clear()
      ..addAll([...ordered, ...byId.values]);
  }
}
