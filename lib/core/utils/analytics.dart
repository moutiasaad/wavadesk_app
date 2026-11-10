import 'package:flutter/foundation.dart';

/// Product analytics sink. Swap [Analytics.sink] for a real provider
/// (Firebase, Amplitude…). Callers must never pass identifiers, passwords,
/// tokens or message content as props.
abstract final class Analytics {
  static void Function(String event, Map<String, Object?> props) sink = _debugSink;

  static void log(String event, [Map<String, Object?> props = const {}]) => sink(event, props);

  static void _debugSink(String event, Map<String, Object?> props) {
    if (kDebugMode) debugPrint('[analytics] $event $props');
  }
}
