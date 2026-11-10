import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen loading rules (production behaviour, same as the web panel):
///
/// 1. A screen starts in [LoadPhase.loading] unless it has cached data
///    (memory or disk) — then it starts [LoadPhase.ready] with that data and
///    refreshes silently (stale-while-revalidate).
/// 2. "Empty" / "not found" UI is shown ONLY after a fetch completed
///    successfully with nothing in it (or a real 404). Never before.
/// 3. A failed refresh keeps the data on screen (banner / snackbar); only a
///    failed FIRST load with nothing cached shows the error state + retry.
/// 4. Reopening a screen shows the last data instantly: keep autoDispose
///    providers alive for a while ([KeepAliveFor.cacheFor]) or read from
///    [MemoryCache].
/// 5. With the real API, never fall back to sample/mock data.
enum LoadPhase {
  /// First load in flight, nothing to show → skeleton.
  loading,

  /// Data (possibly empty) came back at least once.
  ready,

  /// First load failed and nothing is cached → error state + retry.
  error,
}

extension KeepAliveFor on Ref {
  /// Keeps an autoDispose provider (and its data) alive for [duration] after
  /// its last listener goes away, so reopening the screen is instant.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}

/// Process-wide last-known values for screens whose providers are rebuilt
/// (keyed by screen + argument). Cleared on sign-out via [clear].
class MemoryCache {
  MemoryCache._();

  static final _values = <String, (DateTime, Object)>{};
  static const _maxEntries = 200;

  static T? get<T>(String key, {Duration maxAge = const Duration(hours: 6)}) {
    final hit = _values[key];
    if (hit == null) return null;
    if (DateTime.now().difference(hit.$1) > maxAge) {
      _values.remove(key);
      return null;
    }
    final v = hit.$2;
    // ignore: unnecessary_cast
    return v is T ? v as T : null;
  }

  static void put(String key, Object value) {
    _values.remove(key);
    _values[key] = (DateTime.now(), value);
    if (_values.length > _maxEntries) _values.remove(_values.keys.first);
  }

  static void remove(String key) => _values.remove(key);

  static void clear() => _values.clear();
}

/// Picks skeleton / error / empty / content from a [LoadPhase] so every
/// screen follows the same order (rule 2 above).
class LoadSwitcher extends StatelessWidget {
  const LoadSwitcher({
    super.key,
    required this.phase,
    required this.isEmpty,
    required this.skeleton,
    required this.error,
    required this.empty,
    required this.content,
  });

  final LoadPhase phase;

  /// Only consulted once [phase] is [LoadPhase.ready].
  final bool isEmpty;
  final WidgetBuilder skeleton;
  final WidgetBuilder error;
  final WidgetBuilder empty;
  final WidgetBuilder content;

  @override
  Widget build(BuildContext context) => switch (phase) {
        LoadPhase.loading => skeleton(context),
        LoadPhase.error => error(context),
        LoadPhase.ready => isEmpty ? empty(context) : content(context),
      };
}
