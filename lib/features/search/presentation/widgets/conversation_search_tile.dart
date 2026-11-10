import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/presentation/widgets/conversation_tile.dart';
import '../../domain/search_query.dart';

/// Order / tag / subject match: compact inbox row + reason chip
/// ("طلب #2841" / "وسم: VIP") (Search spec §6.5).
class ConversationSearchTile extends StatelessWidget {
  const ConversationSearchTile({super.key, required this.hit, required this.onTap});

  final ConversationHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = switch (hit.reason) {
      ConversationMatchReason.order => l.search_order(ltr(hit.label)),
      ConversationMatchReason.tag => l.search_tag(hit.label),
      ConversationMatchReason.subject => hit.label,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConversationTile(summary: hit.summary, onTap: onTap, enableSwipe: false, showDivider: false),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 68, bottom: AppSpacing.sm),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppFilterChip.tonal(
              label: label,
              leading: AppIcon(AppIcons.tag, size: AppIconSize.xs, color: context.colors.onPrimaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}
