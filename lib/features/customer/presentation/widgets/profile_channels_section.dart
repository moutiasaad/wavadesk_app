import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/contact.dart';
import 'profile_hero.dart';

/// Linked channels (§5.7): channel chip + identifier (LTR) + "{n} محادثات".
/// Tap filters previous conversations; admins get ⋮ unlink / merge.
class ProfileChannelsSection extends StatelessWidget {
  const ProfileChannelsSection({
    super.key,
    required this.contact,
    required this.onChannelTap,
    this.onUnlink,
    this.onMerge,
  });

  final Contact contact;
  final ValueChanged<Channel> onChannelTap;

  /// Admin-only (can_merge); null hides the ⋮.
  final ValueChanged<ContactChannel>? onUnlink;
  final VoidCallback? onMerge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    if (contact.channels.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(title: l.profile_channels),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (var i = 0; i < contact.channels.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.divider),
                  InkWell(
                    onTap: () => onChannelTap(contact.channels[i].channel),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 14, end: AppSpacing.xs, top: 10, bottom: 10),
                      child: Row(
                        children: [
                          ChannelBadge.chip(channel: contact.channels[i].channel),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              ltr(contact.channels[i].identifier),
                              style: t.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            l.profile_channel_count(contact.channels[i].conversations),
                            style: t.caption.copyWith(color: c.textSecondary),
                          ),
                          if (onUnlink != null || onMerge != null)
                            AppIconButton(
                              icon: AppIcons.more,
                              iconSize: 18,
                              semanticLabel: l.profile_more_actions,
                              onPressed: () => _menu(context, contact.channels[i]),
                            )
                          else
                            const SizedBox(width: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _menu(BuildContext context, ContactChannel ch) {
    final l = context.l10n;
    AppBottomSheet.show<void>(
      context,
      showClose: false,
      builder: (ctx) => Column(
        children: [
          if (onUnlink != null)
            SheetActionRow(
              icon: AppIcons.link,
              label: l.profile_unlink,
              onTap: () {
                Navigator.pop(ctx);
                onUnlink!(ch);
              },
            ),
          if (onMerge != null)
            SheetActionRow(
              icon: AppIcons.transfer,
              label: l.profile_merge,
              onTap: () {
                Navigator.pop(ctx);
                onMerge!();
              },
            ),
        ],
      ),
    );
  }
}
