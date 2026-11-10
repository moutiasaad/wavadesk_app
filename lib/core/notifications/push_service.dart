import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_session.dart';
import '../../features/notifications/application/unread_badge_controller.dart';
import '../../features/notifications/domain/notification.dart';
import '../../features/notifications/domain/notification_type.dart';
import '../api/wd_api.dart';
import '../api/wd_api_provider.dart';
import '../router/app_router.dart';
import '../utils/analytics.dart';

/// OS notification permission (Notifications spec §4.3).
enum PushPermission { granted, denied, notDetermined }

/// Background isolate entry point. Notification messages are displayed by
/// the OS; the tap is handled by [PushService] when the app opens.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Push delivery over FCM (Notifications spec §9.1, Claim spec §7.4).
///
/// * The Laravel side sends FCM HTTP v1 messages (`App\Mobile\Push`) with
///   `data: {type, category, conversation_id, channel, workspace_id}`.
/// * Token: registered with `PUT me/push-token` after sign-in and on every
///   refresh; removed on sign-out ([unregister]).
/// * Background / terminated: the OS shows the notification; a tap opens
///   the conversation (claim-category pushes open it in claim state with the
///   one-time pulse, `?source=push`).
/// * Foreground: no system notification; the push goes to the in-app
///   banner (§9.2) and the inbox / bell refresh.
/// * iOS needs an APNs key in Firebase + the Push Notifications capability
///   before anything arrives (see README).
class PushService {
  PushService(this._ref);

  /// Set by `main()` once `Firebase.initializeApp` succeeded.
  static bool firebaseReady = false;

  /// Android notification channels (§9.1): id → (importance, sound).
  static const channels = {
    'assignments': ('high', true),
    'mentions': ('high', true),
    'ai': ('default', true),
    'system': ('low', false),
  };

  /// iOS categories / Android actions (§9.1).
  static const categories = {
    'assigned': ['claim', 'open'],
    'ai_handoff': ['claim', 'open'],
    'claim_needed': ['claim', 'open'],
    'mention': ['reply'],
  };

  final Ref _ref;
  final _subs = <StreamSubscription<Object?>>[];
  bool _started = false;

  static FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  Future<void> start() async {
    // Async gap first: providers must not be written while a widget builds.
    await Future<void>.delayed(Duration.zero);
    if (_started || !firebaseReady) return;
    _started = true;

    await _createChannels();
    _ref.read(pushPermissionProvider.notifier).state = _map((await _fcm.getNotificationSettings()).authorizationStatus);
    // iOS: show nothing while in foreground; the in-app banner does it.
    await _fcm.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);

    _subs
      ..add(FirebaseMessaging.onMessage.listen(_onForeground))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data)))
      // The server sends with `message.token` (FCM registration token), so
      // keep the token API; the newer register()/onRegistered gives an FID.
      // ignore: deprecated_member_use
      ..add(_fcm.onTokenRefresh.listen(_sync));

    _ref.listen<bool>(authProvider, (_, signedIn) {
      if (signedIn) unawaited(registerToken());
    });
    if (_ref.read(authProvider)) unawaited(registerToken());

    // App launched by tapping a notification.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(initial.data));
    }
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
  }

  /// Asks the OS (Android 13+ runtime permission, iOS prompt).
  static Future<PushPermission> requestPermission() async {
    Analytics.log('ntf_push_permission', {'status': 'prompted'});
    if (!firebaseReady) return PushPermission.denied;
    final s = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final status = _map(s.authorizationStatus);
    Analytics.log('ntf_push_permission', {'status': status.name});
    return status;
  }

  /// Sends the current FCM token to the server when signed in (real API).
  Future<void> registerToken() async {
    if (!firebaseReady) return;
    try {
      // ignore: deprecated_member_use
      final token = await _fcm.getToken();
      if (token != null) await _sync(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[push] token: $e');
    }
  }

  Future<void> _sync(String token) async {
    final api = _ref.read(wdApiProvider);
    if (api == null || !_ref.read(authProvider)) return;
    try {
      await syncToken(api, token);
      if (kDebugMode) debugPrint('[push] token registered');
    } catch (e) {
      if (kDebugMode) debugPrint('[push] token sync failed: $e');
    }
  }

  /// `PUT me/push-token {token, platform, app_version}` (§10).
  static Future<void> syncToken(WdApi api, String token) => api.put(
        'me/push-token',
        body: {
          'token': token,
          'platform': !kIsWeb && Platform.isIOS ? 'ios' : 'android',
          'app_version': api.appVersion,
        },
      );

  /// Sign-out: stop pushes to this device (server + local token).
  static Future<void> unregister(WdApi? api) async {
    if (api != null) {
      try {
        await api.delete('me/push-token');
      } catch (_) {}
    }
    if (firebaseReady) {
      try {
        // ignore: deprecated_member_use
        await _fcm.deleteToken();
      } catch (_) {}
    }
  }

  void _onForeground(RemoteMessage m) {
    final conv = m.data['conversation_id'] as String?;
    final raw = '${m.data['type'] ?? 'unknown'}';
    _ref.read(unreadBadgeProvider.notifier)
      ..inject(NotificationItem(
        id: 'push-${m.messageId ?? DateTime.now().microsecondsSinceEpoch}',
        type: NotificationType.parse(raw),
        rawType: raw,
        title: m.notification?.title ?? '',
        body: m.notification?.body ?? '',
        createdAt: DateTime.now(),
        target: conv == null ? null : NotificationTarget(kind: 'conversation', id: conv, conversationId: conv),
      ))
      ..poll();
  }

  /// Push tap → conversation (Claim spec §2 "Push … ClaimBar pulse").
  void _open(Map<String, dynamic> data) {
    final conv = data['conversation_id'] as String?;
    Analytics.log('push_opened', {'type': data['type'], 'category': data['category']});
    if (conv == null || !_ref.read(authProvider)) return;
    final router = _ref.read(routerProvider);
    unawaited(router.push(Routes.chat(conv, source: 'push')));
  }

  static PushPermission _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  static Future<void> _createChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final ar = PlatformDispatcher.instance.locale.languageCode != 'en';
    const names = {
      'assignments': ('المحادثات المسندة', 'Assignments'),
      'mentions': ('الإشارات', 'Mentions'),
      'ai': ('الذكاء الاصطناعي', 'AI'),
      'system': ('النظام', 'System'),
    };
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final e in channels.entries) {
      final (importance, sound) = e.value;
      final name = names[e.key]!;
      await android?.createNotificationChannel(AndroidNotificationChannel(
        e.key,
        ar ? name.$1 : name.$2,
        importance: switch (importance) {
          'high' => Importance.high,
          'low' => Importance.low,
          _ => Importance.defaultImportance,
        },
        playSound: sound,
      ));
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final s = PushService(ref);
  ref.onDispose(s.dispose);
  unawaited(s.start());
  return s;
});

final pushPermissionProvider = StateProvider<PushPermission>((ref) => PushPermission.notDetermined);
