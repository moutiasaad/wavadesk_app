import 'package:flutter/foundation.dart';

import '../../../../core/api/wd_api.dart';
import 'whatsapp_api.dart' show WaApiException;

/// A closing title (the web panel's "Closing titles" page): offered when a
/// conversation is closed. Defaults have no creator.
@immutable
class CloseTitleItem {
  const CloseTitleItem({required this.id, required this.title, this.isDefault = false, this.creator, this.canEdit = false});

  factory CloseTitleItem.fromJson(Map<String, dynamic> j) => CloseTitleItem(
        id: '${j['id']}',
        title: '${j['title'] ?? ''}',
        isDefault: j['is_default'] == true,
        creator: j['creator'] as String?,
        canEdit: j['can_edit'] == true,
      );

  final String id;
  final String title;
  final bool isDefault;
  final String? creator;
  final bool canEdit;
}

@immutable
class CloseTitlesPage {
  const CloseTitlesPage({required this.items, this.canManage = false, this.missingDefaults = 0, this.max = 100});

  final List<CloseTitleItem> items;
  final bool canManage;
  final int missingDefaults;
  final int max;
}

/// `/mobile/v1/close-titles*`. Errors become [WaApiException]
/// (`duplicate_title`, `limit_reached`, `role_forbidden`, 404 before the
/// server update).
class CloseTitlesApi {
  CloseTitlesApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw WaApiException(e.status, code: e.code, message: e.message, details: e.details);
    }
  }

  CloseTitlesPage _page(WdResponse r) => CloseTitlesPage(
        items: [for (final m in r.list) CloseTitleItem.fromJson(m)],
        canManage: r.meta['can_manage'] == true,
        missingDefaults: r.meta['missing_defaults'] is num ? (r.meta['missing_defaults'] as num).toInt() : 0,
        max: r.meta['max'] is num ? (r.meta['max'] as num).toInt() : 100,
      );

  Future<CloseTitlesPage> list() => _guard(() async => _page(await _api.get('close-titles')));

  Future<CloseTitleItem> add(String title) =>
      _guard(() async => CloseTitleItem.fromJson((await _api.post('close-titles', body: {'title': title})).map));

  Future<CloseTitleItem> rename(String id, String title) =>
      _guard(() async => CloseTitleItem.fromJson((await _api.patch('close-titles/$id', body: {'title': title})).map));

  Future<void> delete(String id) => _guard(() => _api.delete('close-titles/$id'));

  Future<CloseTitlesPage> restoreDefaults() => _guard(() async => _page(await _api.post('close-titles/restore-defaults')));
}
