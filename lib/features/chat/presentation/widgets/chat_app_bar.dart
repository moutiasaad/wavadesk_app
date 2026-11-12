import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/conversation_detail.dart';

/// Chat header (Chat spec §4.1) on the brand header: white name, light
/// presence line, white actions. Min height 56 + rounded bottom, grows with
/// text scale; placed in a Column (not a PreferredSizeWidget).
class ChatAppBar extends ConsumerWidget {
  const ChatAppBar({
    super.key,
    required this.detail,
    required this.onProfile,
    required this.onMore,
    this.onClose,
    this.showBack = true,
  });

  final ConversationDetail detail;
  final VoidCallback onProfile;
  final VoidCallback onMore;

  /// ✕ closes (resolves) the conversation; null hides it (closed already,
  /// or no permission).
  final VoidCallback? onClose;

  /// Hidden in the tablet two-pane layout.
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final conv = detail.conversation;
    final contact = detail.contact;

    // Unread count of my OTHER conversations, beside the back button.
    final otherUnread = ref.watch(
      inboxProvider.select(
        (s) => s.conversations.where((x) => x.id != detail.id && x.ownership == Ownership.mine && x.isUnread).length,
      ),
    );

    final largeText = MediaQuery.textScalerOf(context).scale(10) > 16;

    Widget? subline;
    if (!largeText) {
      if (conv.customerTyping) {
        subline = Text(
          l.chat_typing,
          style: t.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700),
          maxLines: 1,
        );
      } else {
        // Ownership subline (Claim v2 §4.1): channel dot + channel · state.
        final dark = c.isDark;
        final amber = dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        final green = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
        final base = t.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: c.textSecondary);
        final channel = detail.channel.label(l);
        InlineSpan? state;
        IconData? stateIcon;
        if (!detail.isClosed) {
          if (detail.isMine) {
            state = TextSpan(text: l.claim_sub_with_you, style: base.copyWith(color: green, fontWeight: FontWeight.w700));
          } else if (detail.assignee != null) {
            state = TextSpan(text: l.claim_sub_with(detail.assignee!.name.split(' ').first));
          } else if (detail.handledByAi && detail.aiAutoMode) {
            stateIcon = AppIcons.ai;
            state = TextSpan(text: l.claim_sub_ai);
          } else {
            state = TextSpan(text: l.claim_sub_unassigned, style: base.copyWith(color: amber, fontWeight: FontWeight.w700));
          }
        }
        final presence = conv.browsingPage != null
            ? l.chatbar_browsing(conv.browsingPage!)
            : conv.customerOnline
            ? l.chat_online
            : null;
        final dot = detail.channel == Channel.whatsapp ? const Color(0xFF25D366) : c.textTertiary;
        subline = Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: channel),
                    if (state != null) ...[
                      const TextSpan(text: ' · '),
                      if (stateIcon != null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 3),
                            child: AppIcon(stateIcon, dp: 12, color: c.primary),
                          ),
                        ),
                      state,
                    ] else if (presence != null)
                      TextSpan(text: ' · $presence'),
                  ],
                ),
                style: base,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }
    }

    return BrandStatusBarBleed(
      child: BrandHeader(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xs, AppSpacing.xxs, AppSpacing.xs, AppSpacing.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
          children: [
            if (showBack) ...[
              AppIconButton(
                icon: AppIcons.back,
                iconSize: 20,
                semanticLabel: otherUnread > 0 ? l.chatbar_back_unread(otherUnread) : l.common_back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              if (otherUnread > 0)
                ExcludeSemantics(
                  child: Transform.scale(scale: 0.8, child: CountBadge(count: otherUnread)),
                ),
            ] else
              const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                button: true,
                label: l.chatbar_open_profile(contact.name),
                excludeSemantics: true,
                child: InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: contact.name,
                          id: contact.id,
                          imageUrl: contact.avatarUrl,
                          channel: detail.channel,
                          size: AppAvatarSize.md,
                          ringColor: BrandHeader.colorsOf(context).first,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                contact.name,
                                style: t.h5.copyWith(color: c.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              ?subline,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onClose != null)
              AppIconButton(icon: AppIcons.close, iconSize: 18, semanticLabel: l.close_title, onPressed: onClose),
            AppIconButton(icon: AppIcons.more, iconSize: 18, semanticLabel: l.chatbar_more, onPressed: onMore),
          ],
        ),
        ),
      ),
    );
  }
}
