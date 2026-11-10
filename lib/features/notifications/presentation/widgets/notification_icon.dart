import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/notification.dart';
import '../../domain/notification_type.dart';

/// Type → icon + tile colors (Notifications spec §5), 34dp rounded tile.
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key, required this.item});

  static const size = 34.0;

  final NotificationItem item;

  static (IconData, Color fg, Color bg) style(BuildContext context, NotificationItem n) {
    final c = context.colors;
    final primary = (c.primary, c.primaryContainer);
    final warning = (c.textWarning, c.warningContainer);
    final error = (c.textError, c.errorContainer);
    final info = (c.textInfo, c.infoContainer);
    final gray = (c.textSecondary, c.surfaceVariant);
    final (IconData icon, (Color, Color) colors) = switch (n.type) {
      NotificationType.assigned => (AppIcons.conversation, primary),
      NotificationType.claimNeeded => (AppIcons.inbox, warning),
      NotificationType.slaBreach => (AppIcons.slaBreach, error),
      NotificationType.transferRequest => (AppIcons.team, info),
      NotificationType.mention => (AppIcons.note, warning),
      NotificationType.aiNoAnswer || NotificationType.aiHandoff => (AppIcons.ai, primary),
      NotificationType.aiLowConfidence => (AppIcons.error, warning),
      NotificationType.kbSuggestion => (AppIcons.kb, primary),
      NotificationType.channelDisconnected => (AppIcons.error, error),
      NotificationType.channelReconnected => (AppIcons.error, (c.textSuccess, c.successContainer)),
      NotificationType.channelQualityLow => (AppIcons.whatsapp, warning),
      NotificationType.teamJoined || NotificationType.teamRoleChanged => (AppIcons.team, gray),
      NotificationType.trialEnding => (AppIcons.slaBreach, warning),
      NotificationType.paymentFailed => (AppIcons.billing, error),
      NotificationType.planLimit => (AppIcons.ai, warning),
      NotificationType.appUpdate => (AppIcons.download, info),
      NotificationType.unknown => (AppIcons.bell, gray),
    };
    return (icon, colors.$1, colors.$2);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = style(context, item);
    // The design shows the type tile for every row (no actor avatars).
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: AppIcon(icon, dp: 18, color: fg),
      ),
    );
  }
}
