import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/application/claim_controller.dart';
import '../../l10n/app_localizations.dart';
import '../data/data.dart';

/// Push notification "استلم" action (Claim spec §7.4).
///
/// Wiring (not in the project yet — needs a push plugin, e.g.
/// `firebase_messaging` + `flutter_local_notifications`):
///  * Register an iOS category / Android action with id [actionId] on the
///    "محادثة جديدة بانتظار الاستلام" notification ([pushTitle]).
///  * App in background: from the notification-action handler, call
///    [claimFromNotification] and show [successText] / [conflictText] as a
///    local notification. Tapping the success one opens
///    `Routes.chat(id)` (composer focused).
///  * App opened from the notification: navigate to
///    `Routes.chat(id, autoClaim: true, source: 'push')` — the chat runs the
///    normal claim flow after 400ms.
abstract final class ClaimNotificationAction {
  static const actionId = 'claim_conversation';

  static String pushTitle(AppLocalizations l) => l.claim_push_title;
  static String actionLabel(AppLocalizations l) => l.claim_push_action;
  static String successText(AppLocalizations l, String customer) => l.claim_push_success(customer);
  static String conflictText(AppLocalizations l, String name) => l.claim_conflict(name);
}

@immutable
class ClaimNotificationResult {
  const ClaimNotificationResult({required this.phase, this.claimedBy, this.customerName});

  final ClaimPhase phase;
  final String? claimedBy;
  final String? customerName;

  bool get ok => phase == ClaimPhase.success;
}

/// Claims without opening the app UI. Uses the same [ClaimController] as
/// the chat (idempotency key, 409/403 handling), so a retry never
/// double-assigns.
Future<ClaimNotificationResult> claimFromNotification(ProviderContainer container, String conversationId) async {
  // Keep the auto-dispose controller alive for the duration of the call.
  final sub = container.listen(claimControllerProvider(conversationId), (_, _) {});
  try {
    final customer = container.read(inboxProvider.notifier).byId(conversationId)?.customer.name;
    final r = await container.read(claimControllerProvider(conversationId).notifier).claim(source: 'push');
    return ClaimNotificationResult(phase: r.phase, claimedBy: r.claimedBy, customerName: customer);
  } finally {
    sub.close();
  }
}
