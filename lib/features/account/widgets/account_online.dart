import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device connectivity for the Account tab (offline bar, presence guard).
/// Starts with the current state, then follows changes.
final accountOnlineProvider = StreamProvider<bool>((ref) async* {
  bool online(List<ConnectivityResult> r) => r.isNotEmpty && r.any((x) => x != ConnectivityResult.none);
  final conn = Connectivity();
  yield online(await conn.checkConnectivity());
  yield* conn.onConnectivityChanged.map(online);
});
