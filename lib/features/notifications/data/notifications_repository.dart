import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/wd_api_provider.dart';
import '../../../core/data/settings_controller.dart' show sharedPrefsProvider;
import '../../auth/application/auth_session.dart';
import '../domain/notification_type.dart';
import 'notifications_api.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) => HttpNotificationsApi(ref.watch(wdApiRequiredProvider)));

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  ref.watch(authProvider);
  final userId = '${ref.read(authRepositoryProvider).session?.user['id'] ?? ''}';
  return NotificationsRepository(ref.watch(notificationsApiProvider), ref.watch(sharedPrefsProvider), userId: userId);
});

/// API + local state: cached first page per filter (§7 "Cached"), last
/// filter (§4.2 "Persist last filter"), muted types (§4.6 long-press) and the
/// push-banner snooze (§4.3).
class NotificationsRepository {
  NotificationsRepository(this.api, this._prefs, {this.userId = ''});

  final NotificationsApi api;
  final SharedPreferences _prefs;

  /// Cache is per signed-in user.
  final String userId;

  static const _kFilter = 'ntf_filter';
  static const _kMuted = 'ntf_muted_types';
  static const _kBannerHiddenUntil = 'ntf_push_banner_hidden_until';
  String _kCache(NotificationFilter f) => 'ntf_cache_${userId}_${f.name}';

  NotificationFilter get lastFilter => NotificationFilter.parse(_prefs.getString(_kFilter));
  Future<void> saveFilter(NotificationFilter f) => _prefs.setString(_kFilter, f.name);

  NotificationsPage? cached(NotificationFilter f) {
    final raw = _prefs.getString(_kCache(f));
    if (raw == null) return null;
    try {
      return NotificationsPage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cache(NotificationFilter f, NotificationsPage page) =>
      _prefs.setString(_kCache(f), jsonEncode(page.toJson()));

  Set<String> get mutedTypes => (_prefs.getStringList(_kMuted) ?? const []).toSet();

  Future<void> mute(String type) async {
    await _prefs.setStringList(_kMuted, {...mutedTypes, type}.toList());
    try {
      await api.muteType(type);
    } on NotificationsApiException {
      // Older servers have no mute endpoint: the local mute still hides it.
    }
  }

  bool get pushBannerHidden {
    final until = DateTime.tryParse(_prefs.getString(_kBannerHiddenUntil) ?? '');
    return until != null && until.isAfter(DateTime.now());
  }

  /// ✕ on the push-disabled banner hides it for 7 days (§4.3).
  Future<void> hidePushBanner() =>
      _prefs.setString(_kBannerHiddenUntil, DateTime.now().add(const Duration(days: 7)).toIso8601String());
}
