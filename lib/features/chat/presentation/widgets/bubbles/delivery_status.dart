import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// Delivery icon 14 inside the status row (Chat spec §4.4): sending clock ·
/// sent check · delivered double-check 65% · read double-check
/// (`readTickOnPrimary` on primary, `accent` elsewhere) · failed alert.
class DeliveryStatus extends StatelessWidget {
  const DeliveryStatus({super.key, required this.state, required this.foreground, required this.onPrimary});

  final DeliveryState state;

  /// Bubble foreground (white on primary, text on light bubbles).
  final Color foreground;
  final bool onPrimary;

  static String label(AppLocalizations l, DeliveryState s) => switch (s) {
    DeliveryState.sending => l.bubble_delivery_sending,
    DeliveryState.sent => l.bubble_delivery_sent,
    DeliveryState.delivered => l.bubble_delivery_delivered,
    DeliveryState.read => l.bubble_delivery_read,
    DeliveryState.failed => l.chat_failed,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (IconData icon, Color color) = switch (state) {
      DeliveryState.sending => (AppIcons.pending, foreground.withValues(alpha: 0.65)),
      DeliveryState.sent => (AppIcons.check, foreground.withValues(alpha: 0.65)),
      DeliveryState.delivered => (AppIcons.read, foreground.withValues(alpha: 0.65)),
      DeliveryState.read => (AppIcons.read, onPrimary ? c.readTickOnPrimary : c.accent),
      DeliveryState.failed => (AppIcons.error, c.error),
    };
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: AppIcon(icon, size: AppIconSize.sm, color: color, key: ValueKey(state)),
    );
  }
}
