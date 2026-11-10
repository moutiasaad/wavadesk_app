import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wd_api.dart';

/// The signed `/mobile/v1` client, or null when the app runs on sample data
/// (no `--dart-define=WAVADESK_API_URL`). Overridden in `main()`.
final wdApiProvider = Provider<WdApi?>((ref) => null);

/// Same as [wdApiProvider] but throws when the real API is not configured;
/// use only behind a `useRealApi` check.
final wdApiRequiredProvider = Provider<WdApi>((ref) {
  final api = ref.watch(wdApiProvider);
  if (api == null) throw StateError('WAVADESK_API_URL is not set');
  return api;
});
