import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
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
    this.showBack = true,
  });

  final ConversationDetail detail;
  final VoidCallback onProfile;
  final VoidCallback onMore;

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
    final canCall = detail.channel.supportsCall && contact.phone != null;

    Widget? subline;
    if (!largeText) {
      if (conv.customerTyping) {
        subline = Text(
          l.chat_typing,
          style: t.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700),
          maxLines: 1,
        );
      } else {
        final presence = conv.browsingPage != null
            ? l.chatbar_browsing(conv.browsingPage!)
            : conv.customerOnline
            ? l.chat_online
            : conv.lastSeen != null
            ? l.chat_last_seen(RelativeTimeFormatter.clock12(conv.lastSeen!, l))
            : null;
        subline = Row(
          children: [
            if (conv.customerOnline && conv.browsingPage == null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.presenceOnline,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 1),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                presence == null ? detail.channel.label(l) : '${detail.channel.label(l)} · $presence',
                style: t.caption.copyWith(color: c.textSecondary),
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
            if (canCall)
              AppIconButton(
                icon: AppIcons.call,
                iconSize: 18,
                semanticLabel: l.chatbar_call,
                onPressed: () => _callSheet(context, contact),
              ),
            AppIconButton(icon: AppIcons.more, iconSize: 18, semanticLabel: l.chatbar_more, onPressed: onMore),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _callSheet(BuildContext context, Customer contact) async {
    final l = context.l10n;
    final phone = contact.phone!;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = await AppBottomSheet.show<Uri>(
      context,
      title: l.chatbar_call,
      subtitle: ltr(phone),
      builder: (ctx) => Column(
        children: [
          SheetActionRow(
            icon: AppIcons.phoneCall,
            label: l.chatbar_call_phone,
            onTap: () => Navigator.pop(ctx, Uri(scheme: 'tel', path: digits)),
          ),
          SheetActionRow(
            icon: AppIcons.whatsapp,
            label: l.chatbar_call_whatsapp,
            onTap: () => Navigator.pop(ctx, Uri.parse('https://wa.me/${digits.replaceAll('+', '')}')),
          ),
        ],
      ),
    );
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) AppSnackbar.show(context, message: l.chatbar_call_failed, kind: SnackKind.error);
    }
  }
}
