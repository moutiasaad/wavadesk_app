import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_session.dart';
import '../../conversations/application/conversations_controller.dart' show inboxTabBadgeProvider;
import '../data/notifications_api.dart';
import '../data/notifications_repository.dart';
import '../domain/notification.dart';

@immutable
class NotificationsBadgeState {
  const NotificationsBadgeState({this.unreadCount = 0, this.counts = const {}, this.badgeTypeUnread = 0});

  /// Unread notifications excluding muted types (§8) → bell dot.
  final int unreadCount;

  /// Per-filter unread counts from `meta.counts`.
  final Map<String, int> counts;

  /// Unread `assigned` / `mention` / `sla_breach` / `transfer_request` rows
  /// seen in the latest poll (feeds the launcher badge, §8).
  final int badgeTypeUnread;

  NotificationsBadgeState copyWith({int? unreadCount, Map<String, int>? counts, int? badgeTypeUnread}) =>
      NotificationsBadgeState(
        unreadCount: unreadCount ?? this.unreadCount,
        counts: counts ?? this.counts,
        badgeTypeUnread: badgeTypeUnread ?? this.badgeTypeUnread,
      );
}

/// App-wide notifications poller (no push plugin / socket yet): every 30 s
/// while the app is in the foreground and signed in it fetches the newest
/// rows, updates the bell dot and emits new arrivals for the in-app banner
/// (§9.2) and the list's realtime insert (§14).
final unreadBadgeProvider = NotifierProvider<UnreadBadgeController, NotificationsBadgeState>(
  UnreadBadgeController.new,
);

/// Bell dot in the Inbox app bar and on the Dashboard (§2, §8).
final notificationsUnreadCountProvider = Provider<int>((ref) => ref.watch(unreadBadgeProvider).unreadCount);

/// Launcher badge value (§8): Mine unread conversations + unread rows of the
/// badge types. There is no launcher-badge plugin in the app yet; this is the
/// number to hand to one (e.g. `flutter_app_badger`) once added.
final appIconBadgeProvider = Provider<int>(
  (ref) => ref.watch(inboxTabBadgeProvider) + ref.watch(unreadBadgeProvider.select((s) => s.badgeTypeUnread)),
);

class UnreadBadgeController extends Notifier<NotificationsBadgeState> with WidgetsBindingObserver {
  static const interval = Duration(seconds: 30);

  final _arrivals = StreamController<NotificationItem>.broadcast();
  Timer? _timer;
  Set<String>? _seen;
  bool _foreground = true;
  bool _polling = false;

  /// New, unread, non-muted rows that arrived after the first poll.
  Stream<NotificationItem> get arrivals => _arrivals.stream;

  /// A foreground push (PushService) shown through the same in-app banner.
  void inject(NotificationItem n) => _arrivals.add(n);

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  NotificationsBadgeState build() {
    final signedIn = ref.watch(authProvider);
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
    });
    _seen = null;
    if (signedIn) {
      _timer = Timer.periodic(interval, (_) => poll());
      // Never mutate state synchronously inside build.
      Future.microtask(poll);
    }
    return const NotificationsBadgeState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(poll());
  }

  Future<void> poll() async {
    if (!_foreground || _polling || !ref.read(authProvider)) return;
    _polling = true;
    try {
      final page = await _repo.api.latest();
      apply(page);
    } on NotificationsApiException {
      // Keep the last known badge; the list screen shows errors.
    } finally {
      _polling = false;
    }
  }

  /// Updates the badge from any fresh page (also called by the list).
  void apply(NotificationsPage page) {
    final muted = _repo.mutedTypes;
    final mutedUnread = page.items.where((n) => !n.isRead && muted.contains(n.rawType)).length;
    state = state.copyWith(
      unreadCount: (page.unreadCount - mutedUnread).clamp(0, 1 << 30),
      counts: page.counts.isEmpty ? state.counts : page.counts,
      badgeTypeUnread: page.items.where((n) => !n.isRead && n.type.countsInAppBadge).length,
    );
    final seen = _seen;
    _seen = {...?seen, ...page.items.map((n) => n.id)};
    if (seen == null) return; // first poll seeds the set without banners
    for (final n in page.items.reversed) {
      if (!seen.contains(n.id) && !n.isRead && !muted.contains(n.rawType)) _arrivals.add(n);
    }
  }

  /// Local adjustment after a read / unread / delete in the list.
  void adjust(int delta) => state = state.copyWith(unreadCount: (state.unreadCount + delta).clamp(0, 1 << 30));

  void setUnread(int unread) => state = state.copyWith(unreadCount: unread.clamp(0, 1 << 30));
}
