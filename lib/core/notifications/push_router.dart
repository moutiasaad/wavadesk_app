import 'package:flutter/foundation.dart';

import '../../features/notifications/domain/notification.dart';
import '../../features/notifications/domain/notification_type.dart';
import '../router/app_router.dart';

/// Where a notification (row tap, inline navigate action, push tap, in-app
/// banner) takes the agent (Notifications spec §5 "Tap target").
@immutable
class PushDestination {
  const PushDestination.route(String this.route) : external = null, billing = false;
  const PushDestination.external(Uri this.external) : route = null, billing = false;

  /// Billing target: web billing for owner/admin, info sheet for agents (§5).
  const PushDestination.billing(this.external) : route = null, billing = true;

  final String? route;
  final Uri? external;
  final bool billing;
}

abstract final class PushRouter {
  static const webBillingUrl = 'https://app.wavadesk.com/tenant-admin/billing';
  static const storeUrlAndroid = 'https://play.google.com/store/apps/details?id=com.wavadesk.agent';

  /// `wavadesk://chat/conv_1?messageId=m` → `/chat/conv_1?messageId=m`;
  /// http(s) links stay external.
  static PushDestination? fromDeeplink(String? link) {
    if (link == null || link.isEmpty) return null;
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    if (uri.scheme == 'http' || uri.scheme == 'https') return PushDestination.external(uri);
    final segments = [if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
    if (segments.isEmpty) return null;
    final path = '/${segments.join('/')}';
    return PushDestination.route(uri.hasQuery ? '$path?${uri.query}' : path);
  }

  /// Tap target for [n] (§5). [actionId] lets navigate-only inline actions
  /// (رد الآن, أضف إجابة, …) share the mapping.
  static PushDestination? forNotification(NotificationItem n, {String? actionId}) {
    final conv = n.conversationId;
    final messageId = n.target?.kind == 'message' ? n.target?.id : null;
    final q = n.params['question'] as String?;
    switch (n.type) {
      case NotificationType.assigned:
      case NotificationType.slaBreach:
      case NotificationType.transferRequest:
      case NotificationType.aiHandoff:
        if (conv != null) return PushDestination.route(Routes.chat(conv));
      case NotificationType.mention:
      case NotificationType.aiLowConfidence:
        if (conv != null) return PushDestination.route(Routes.chat(conv, messageId: messageId));
      case NotificationType.claimNeeded:
        return const PushDestination.route('${Routes.conversations}?segment=unassigned');
      case NotificationType.aiNoAnswer:
        return PushDestination.route(Routes.newKnowledgeFrom(question: q ?? n.body));
      case NotificationType.kbSuggestion:
        return const PushDestination.route(Routes.knowledge);
      case NotificationType.channelDisconnected:
      case NotificationType.channelReconnected:
      case NotificationType.channelQualityLow:
        return const PushDestination.route(Routes.whatsapp);
      case NotificationType.teamJoined:
        return const PushDestination.route(Routes.team);
      case NotificationType.teamRoleChanged:
        return const PushDestination.route(Routes.account);
      case NotificationType.trialEnding:
      case NotificationType.paymentFailed:
        return PushDestination.billing(Uri.parse(n.target?.url ?? webBillingUrl));
      case NotificationType.planLimit:
        return const PushDestination.route(Routes.aiAgent);
      case NotificationType.appUpdate:
        return PushDestination.external(Uri.parse(n.target?.url ?? storeUrlAndroid));
      case NotificationType.unknown:
        break;
    }
    if (n.target?.url != null) {
      final u = Uri.tryParse(n.target!.url!);
      if (u != null) return PushDestination.external(u);
    }
    return fromDeeplink(n.deeplink);
  }

  /// The route the user is on when [d] points at it (banner suppression, §9.2).
  static bool isOnTarget(PushDestination d, String currentLocation) {
    final route = d.route;
    if (route == null) return false;
    final target = Uri.parse(route).path;
    return Uri.parse(currentLocation).path == target;
  }
}
