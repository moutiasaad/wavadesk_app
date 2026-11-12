import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api_provider.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/state/load_state.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/biometric_service.dart';

/// Overridden in `main()` with a repository whose [AuthRepository.load] has
/// completed, so routing can decide synchronously on the first frame.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider must be overridden'),
);

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

/// Set when the server ended the session (not a manual logout): the login
/// screen shows "انتهت جلستك" once (Login v2 §5.3). Cleared on next sign-in.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

/// True while a valid session exists. Drives the router's login redirect.
final authProvider = NotifierProvider<AuthController, bool>(AuthController.new);

class AuthController extends Notifier<bool> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  bool build() {
    // The server ended the session (refresh token reused, device revoked…).
    final sub = ref.read(wdApiProvider)?.sessionEnded.listen((_) {
      ref.read(sessionExpiredProvider.notifier).state = true;
      signOut();
    });
    ref.onDispose(() => sub?.cancel());
    final repo = ref.read(authRepositoryProvider);
    // An expired access token is fine while the refresh token is still valid:
    // the API client refreshes it before the first call.
    if (ref.read(wdApiProvider) != null) return repo.session != null && repo.signingSecret != null;
    return repo.hasValidSession;
  }

  /// Persists the session (and the identifier that produced it) and flips
  /// the app into the signed-in state; the router then replaces the stack.
  Future<void> establish(Session session, {String? identifier}) async {
    await _repo.saveSession(session, identifier: identifier);
    ref.read(sessionExpiredProvider.notifier).state = false;
    state = true;
  }

  /// Logout: deletes tokens + the biometric flag (Login spec §13).
  Future<void> signOut() async {
    final api = ref.read(wdApiProvider);
    if (api != null && _repo.session != null) {
      // Stop pushes to this device before the session is revoked.
      await PushService.unregister(api);
      try {
        await api.post('auth/logout');
      } catch (_) {}
    }
    await _repo.clearSession();
    // Never show the previous account's data to the next sign-in.
    MemoryCache.clear();
    state = false;
  }

  /// Local-only sign-out after the account was deleted: the server already
  /// revoked every session (and its push tokens), so no logout call.
  Future<void> signOutLocal() async {
    await _repo.clearSession();
    MemoryCache.clear();
    state = false;
  }
}
