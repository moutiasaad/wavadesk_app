import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../application/customer_profile_controller.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import 'profile_hero.dart';

/// "المحادثات السابقة" (§5.9): channel filter chip, rows with channel glyph,
/// title, "{date} · أغلقها {agent}" / AI / open now, page size 10.
/// Excludes the current conversation; past ones open read-only.
class ProfilePreviousConversations extends ConsumerWidget {
  const ProfilePreviousConversations({super.key, required this.contact, this.conversationId});

  final Contact contact;
  final String? conversationId;

  PastKey get _key => (contactId: contact.id, excludeId: conversationId);

  Future<void> _pickChannel(BuildContext context, WidgetRef ref, Channel? current) async {
    final l = context.l10n;
    final channels = {for (final c in contact.channels) c.channel}.toList();
    final picked = await AppBottomSheet.show<Object>(
      context,
      title: l.profile_filter_channel,
      builder: (ctx) => Column(
        children: [
          SheetActionRow(
            icon: AppIcons.inbox,
            label: l.profile_all_channels,
            selected: current == null,
            onTap: () => Navigator.pop(ctx, 'all'),
          ),
          for (final ch in channels)
            SheetActionRow(
              icon: ch.glyph,
              label: ch.label(l),
              selected: current == ch,
              onTap: () => Navigator.pop(ctx, ch),
            ),
        ],
      ),
    );
    if (picked == null) return;
    ref.read(pastConversationsProvider(_key).notifier).setChannel(picked is Channel ? picked : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(pastConversationsProvider(_key));
    final ctrl = ref.read(pastConversationsProvider(_key).notifier);

    Widget body;
    if (s.loading) {
      body = const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: AppSpinner(size: 24)));
    } else if (s.error) {
      body = Row(
        children: [
          Expanded(
            child: Text(l.profile_section_error(l.profile_previous), style: t.bodySmall.copyWith(color: c.textError)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: t.buttonSmall),
            onPressed: ctrl.retry,
            child: Text(l.profile_retry),
          ),
        ],
      );
    } else if (s.items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(l.profile_first_conv, style: t.bodySmall.copyWith(color: c.textTertiary)),
      );
    } else {
      body = Column(
        children: [
          for (var i = 0; i < s.items.length; i++) _row(context, s.items[i], i),
          if (s.hasMore)
            s.loadingMore
                ? const Padding(padding: EdgeInsets.all(AppSpacing.md), child: AppSpinner(size: 24, delayed: false))
                : TextButton(
                    style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: t.buttonSmall, minimumSize: const Size(48, 44)),
                    onPressed: ctrl.loadMore,
                    child: Text(l.profile_load_more),
                  ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: l.profile_previous,
          trailing: AppFilterChip(
            label: s.channel == null ? l.profile_all_channels : s.channel!.label(l),
            selected: s.channel != null,
            trailingIcon: AppIcons.chevronDown,
            onTap: () => _pickChannel(context, ref, s.channel),
          ),
        ),
        AnimatedSwitcher(duration: AppMotion.fast, child: KeyedSubtree(key: ValueKey('${s.loading}${s.channel}'), child: body)),
      ],
    );
  }

  Widget _row(BuildContext context, PastConversation p, int position) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final date = RelativeTimeFormatter.dayMonth(p.date, DateTime.now(), context.localeName);
    final subtitle = switch (p.state) {
      PastConversationState.closedBy => l.profile_closed_by(date, p.closedBy ?? '—'),
      PastConversationState.aiReplied => l.profile_ai_replied(date),
      PastConversationState.openNow => l.profile_open_now(date),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        Analytics.log('profile_prev_conversation_open', {'position': position});
        context.push(Routes.chat(p.id, readOnly: !p.assignedToSomeone));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(10)),
              child: Icon(p.channel.glyph, size: 16, color: c.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title.isEmpty ? p.channel.label(l) : p.title,
                    style: t.listTitle.copyWith(fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: t.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: p.state == PastConversationState.openNow ? c.textSuccess : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronEnd, size: 16, color: c.borderStrong),
          ],
        ),
      ),
    );
  }
}
