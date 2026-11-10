import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One shared minute clock for every row (Inbox spec §5): relative
/// timestamps and waiting tags recompute together, never per-row timers.
/// Ticks on the minute boundary.
final inboxClockProvider = NotifierProvider<InboxClock, DateTime>(InboxClock.new);

class InboxClock extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final now = DateTime.now();
    _timer = Timer(Duration(seconds: 60 - now.second), () {
      state = DateTime.now();
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => state = DateTime.now());
    });
    return now;
  }

  /// Forces a recompute (e.g. after resume from background).
  void tick() => state = DateTime.now();
}
