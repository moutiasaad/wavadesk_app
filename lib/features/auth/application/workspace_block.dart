import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import 'auth_session.dart';

/// Why the server closed the workspace (`403 workspace_unavailable`,
/// `details.reason` from App\Support\WorkspaceAccess::denialFor).
enum WorkspaceBlockReason {
  trialExpired,
  subscriptionExpired,
  subscriptionInactive,
  planNotSelected,
  workspaceBlocked,
  workspaceArchived;

  static WorkspaceBlockReason parse(String v) => switch (v) {
        'trial_expired' => trialExpired,
        'subscription_expired' => subscriptionExpired,
        'plan_not_selected' => planNotSelected,
        'workspace_blocked' => workspaceBlocked,
        'workspace_archived' => workspaceArchived,
        _ => subscriptionInactive,
      };

  /// Paying (choosing a plan) lifts it; a blocked or archived workspace needs
  /// Wavadesk support instead.
  bool get billingFixes => this != workspaceBlocked && this != workspaceArchived;
}

/// Set while the signed-in workspace is closed; the app then shows
/// [WorkspaceBlockedScreen] over everything. Cleared on sign-in / sign-out
/// and when a re-check succeeds (the admin paid on the web meanwhile).
final workspaceBlockProvider =
    NotifierProvider<WorkspaceBlockController, WorkspaceBlockReason?>(WorkspaceBlockController.new);

class WorkspaceBlockController extends Notifier<WorkspaceBlockReason?> {
  @override
  WorkspaceBlockReason? build() {
    // Re-runs on every sign-in / sign-out, which clears the notice.
    ref.watch(authProvider);
    final api = ref.read(wdApiProvider);
    if (api != null) {
      final sub = api.workspaceBlocked.listen((reason) {
        // At sign-in the login screen explains it itself.
        if (ref.read(authProvider)) state = WorkspaceBlockReason.parse(reason);
      });
      ref.onDispose(sub.cancel);
    }
    return null;
  }

  /// "Try again": true when the workspace is open again.
  Future<bool> recheck() async {
    final api = ref.read(wdApiProvider);
    if (api == null) return false;
    try {
      await api.get('me');
      state = null;
      return true;
    } on WdApiException {
      // Still closed (the stream set the reason again) or offline.
      return false;
    }
  }
}
