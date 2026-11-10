import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import 'dashboard_controller.dart';

/// My status + optional end time (Dashboard spec §4.1). The status itself
/// lives in [settingsProvider] (the Account tab shows the same value); this
/// adds the "until" and syncs `PUT /me/presence`.
@immutable
class PresenceState {
  const PresenceState({required this.presence, this.until});

  final Presence presence;
  final DateTime? until;
}

/// "حتى…" choices.
enum PresenceDuration { m30, h1, endOfDay }

extension PresenceDurationX on PresenceDuration {
  DateTime untilFrom(DateTime now) => switch (this) {
        PresenceDuration.m30 => now.add(const Duration(minutes: 30)),
        PresenceDuration.h1 => now.add(const Duration(hours: 1)),
        PresenceDuration.endOfDay => DateTime(now.year, now.month, now.day, 23, 59),
      };
}

final presenceControllerProvider = NotifierProvider<PresenceController, PresenceState>(PresenceController.new);

class PresenceController extends Notifier<PresenceState> {
  static const _kUntil = 'presence_until';

  @override
  PresenceState build() {
    final presence = ref.watch(settingsProvider.select((s) => s.presence));
    final raw = ref.read(sharedPrefsProvider).getString(_kUntil);
    final until = raw == null ? null : DateTime.tryParse(raw);
    if (until != null && until.isBefore(DateTime.now())) {
      // Expired "until": back to online (the server does the same).
      Future.microtask(() => set(Presence.online));
      return PresenceState(presence: presence);
    }
    return PresenceState(presence: presence, until: until);
  }

  /// Optimistic: the pill changes at once, the server call follows; on
  /// failure the previous status comes back and the error is rethrown.
  Future<void> set(Presence presence, {PresenceDuration? duration}) async {
    final prev = state;
    final until = presence == Presence.online ? null : duration?.untilFrom(DateTime.now());
    Analytics.log('dash_presence_change', {'from': prev.presence.name, 'to': presence.name, 'until': duration?.name});
    final prefs = ref.read(sharedPrefsProvider);
    ref.read(settingsProvider.notifier).setPresence(presence);
    until == null ? await prefs.remove(_kUntil) : await prefs.setString(_kUntil, until.toIso8601String());
    state = PresenceState(presence: presence, until: until);
    try {
      await ref.read(dashboardApiProvider).setPresence(presence.name, until: until);
    } catch (_) {
      ref.read(settingsProvider.notifier).setPresence(prev.presence);
      prev.until == null ? await prefs.remove(_kUntil) : await prefs.setString(_kUntil, prev.until!.toIso8601String());
      state = prev;
      rethrow;
    }
  }
}
