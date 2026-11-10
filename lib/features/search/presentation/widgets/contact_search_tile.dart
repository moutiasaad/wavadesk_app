import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/search_query.dart';
import 'highlighted_text.dart';

/// Customer hit: avatar 40 + channel badge, highlighted name, matched field
/// (phone LTR), "مفتوحة" badge (Search spec §6.2).
class ContactSearchTile extends StatelessWidget {
  const ContactSearchTile({
    super.key,
    required this.hit,
    required this.query,
    required this.onTap,
    required this.onMore,
  });

  final ContactHit hit;
  final String query;
  final VoidCallback onTap;

  /// Long-press / ⋮ sheet.
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final value = hit.matchedField == MatchedField.phone || hit.matchedField == MatchedField.email
        ? ltr(hit.matchedValue)
        : hit.matchedValue;
    final subStyle = t.bodySmall.copyWith(color: c.textSecondary);
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.screenH,
              end: AppSpacing.xs,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: hit.name,
                  id: hit.id,
                  imageUrl: hit.avatarUrl,
                  channel: hit.channel,
                  size: AppAvatarSize.md,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      hit.highlight != null
                          ? HighlightedText(markup: hit.highlight, style: t.listTitle.copyWith(fontSize: 15))
                          : HighlightedText(text: hit.name, query: query, style: t.listTitle.copyWith(fontSize: 15)),
                      if (value.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        hit.matchedField == MatchedField.name
                            ? Text(value, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis)
                            : HighlightedText(text: value, query: query, style: subStyle),
                      ],
                    ],
                  ),
                ),
                if (hit.hasOpenConversation)
                  StatusBadge(
                    label: l.search_open_badge,
                    foreground: c.statusOpen,
                    background: c.statusOpenContainer,
                    compact: true,
                  ),
                AppIconButton(
                  icon: AppIcons.more,
                  iconSize: 18,
                  iconColor: c.textTertiary,
                  semanticLabel: l.common_more,
                  onPressed: onMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
