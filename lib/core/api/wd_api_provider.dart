import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wd_api.dart';

/// The signed `/mobile/v1` client. Overridden in `main()`; null only before
/// that (the app never starts without the API config).
final wdApiProvider = Provider<WdApi?>((ref) => null);

/// Same as [wdApiProvider], non-null.
final wdApiRequiredProvider = Provider<WdApi>((ref) {
  final api = ref.watch(wdApiProvider);
  if (api == null) throw StateError('WAVADESK_API_URL is not set');
  return api;
});
