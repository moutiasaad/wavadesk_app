import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/l10n.dart';

/// §8.8. Standard: height 24, pill, 6dp leading dot. Compact (list rows):
/// height 20, radius 6, 13dp icon instead of the dot.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.compact = false,
    this.leading,
  });

  /// Badge for a [ConversationStatus], colors from §3.6.
  factory StatusBadge.status(BuildContext context, ConversationStatus status, {bool compact = false, String? label}) {
    final c = context.colors;
    return StatusBadge(
      label: label ?? status.label(context.l10n),
      foreground: status.foreground(c),
      background: status.container(c),
      icon: compact || status == ConversationStatus.ai ? status.icon : null,
      compact: compact,
    );
  }

  /// Chip form of the priority indicator (§8.9).
  factory StatusBadge.priority(BuildContext context, Priority p) {
    final c = context.colors;
    final color = p.color(c);
    return StatusBadge(
      label: p.label(context.l10n),
      foreground: color,
      background: color.withValues(alpha: c.isDark ? 0.18 : 0.10),
      icon: p == Priority.urgent ? AppIcons.priority : null,
    );
  }

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;
  final bool compact;

  /// Replaces the dot/icon (e.g. a mini avatar for "assigned to colleague").
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final lead =
        leading ??
        (icon != null
            ? AppIcon(icon, size: AppIconSize.xs, color: foreground)
            : Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
              ));

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 20 : 24),
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? AppRadius.xs : AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lead,
          SizedBox(width: compact ? AppSpacing.xs : 6),
          Flexible(
            child: Text(
              label,
              style: context.text.tagLabel.copyWith(color: foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
