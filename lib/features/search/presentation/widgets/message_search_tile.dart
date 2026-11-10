import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/search_query.dart';
import '../../domain/snippet_parser.dart';
import 'highlighted_text.dart';

/// Message hit: contact avatar, name · date, highlighted snippet with the
/// sender prefix, "+n نتائج أخرى" (Search spec §6.3).
class MessageSearchTile extends StatelessWidget {
  const MessageSearchTile({super.key, required this.hit, required this.onTap, this.onMore});

  final MessageHit hit;
  final VoidCallback onTap;

  /// "+n نتائج أخرى في هذه المحادثة" → in-conversation search.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final textScaled = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final snippetStyle = t.bodyMedium.copyWith(fontSize: 13.5, color: c.textSecondary);

    final (IconData? icon, String? prefix) = switch (hit.senderType) {
      HitSender.contact => (null, null),
      HitSender.ai => (AppIcons.sparkle, null),
      HitSender.note => (AppIcons.note, l.search_note),
      HitSender.agent => (null, hit.isMe ? l.search_you : '${hit.senderName ?? ''}:'),
    };
    final time = AppFormat.listTimestamp(context, hit.createdAt);
    final plain = SnippetParser.plain(hit.snippet);

    return Semantics(
      button: true,
      label: l.search_a11y_message(hit.contactName, time, plain),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: hit.contactName,
                id: hit.contactId,
                imageUrl: hit.contactAvatarUrl,
                channel: hit.channel,
                size: AppAvatarSize.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hit.contactName,
                            style: t.listTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(time, style: t.listTimestamp.copyWith(color: c.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 3, end: 4),
                            child: Icon(
                              icon,
                              size: 13,
                              color: hit.senderType == HitSender.ai ? c.primary : c.noteForeground,
                            ),
                          ),
                        if (prefix != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 4),
                            child: Text(prefix, style: snippetStyle.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        Expanded(
                          child: HighlightedText(
                            markup: hit.snippet,
                            style: snippetStyle,
                            maxLines: textScaled ? 3 : 2,
                          ),
                        ),
                      ],
                    ),
                    if (hit.moreInConversation > 0 && onMore != null)
                      Semantics(
                        button: true,
                        child: InkWell(
                          onTap: onMore,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Text(
                              l.search_more_in_conv(hit.moreInConversation),
                              style: t.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
