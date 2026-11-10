import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/conversations_controller.dart';
import '../inbox_actions.dart';

/// Replaces the tab bar while selecting (Inbox spec §4.9): same height +
/// safe area, `background`, top border. 4 equal actions (icon 22 +
/// `overline`) + overflow ⋮ (وسم، أولوية، أرشفة).
class MultiSelectBar extends ConsumerWidget {
  const MultiSelectBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final ids = ref.watch(inboxProvider.select((s) => s.selected));
    final items = ref.watch(conversationsControllerProvider.select((s) => s.items));
    final anyUnread = items.any((i) => ids.contains(i.id) && i.isUnread);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    Future<void> bulk(String action, Future<void> Function(Set<String>) run) async {
      Analytics.log('inbox_bulk_action', {'action': action, 'count': ids.length});
      await run({...ids});
      ref.read(conversationsControllerProvider.notifier).clearSelection();
    }

    Widget item(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: ids.isEmpty ? null : onTap,
          radius: 32,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: c.textPrimary),
                const SizedBox(height: 3),
                Text(label, style: context.text.overline.copyWith(color: c.textPrimary), maxLines: 1),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm + bottom),
      child: Row(
        children: [
          item(
            AppIcons.resolve,
            l.inbox_swipe_resolve,
            () => bulk('resolve', (s) => InboxActions.resolve(context, ref, s)),
          ),
          item(
            AppIcons.assign,
            l.inbox_swipe_assign,
            () => bulk('assign', (s) => InboxActions.assign(context, ref, s)),
          ),
          item(
            AppIcons.moon,
            l.inbox_swipe_snooze,
            () => bulk('snooze', (s) => InboxActions.pickSnooze(context, ref, s)),
          ),
          item(
            anyUnread ? AppIcons.mailOpen : AppIcons.mail,
            anyUnread ? l.inbox_mark_read : l.inbox_mark_unread,
            () => bulk('read', (s) => InboxActions.setRead(context, ref, s, read: anyUnread)),
          ),
          SizedBox(
            width: 56,
            child: AppIconButton(
              icon: AppIcons.more,
              semanticLabel: l.common_more,
              onPressed: ids.isEmpty
                  ? null
                  : () => AppBottomSheet.show<void>(
                      context,
                      builder: (ctx) => Column(
                        children: [
                          SheetActionRow(
                            icon: AppIcons.tag,
                            label: l.inbox_tag,
                            onTap: () {
                              Navigator.pop(ctx);
                              bulk('tag', (s) => InboxActions.pickTag(context, ref, s));
                            },
                          ),
                          SheetActionRow(
                            icon: AppIcons.flag,
                            label: l.inbox_priority,
                            onTap: () {
                              Navigator.pop(ctx);
                              bulk('priority', (s) => InboxActions.pickPriority(context, ref, s));
                            },
                          ),
                          SheetActionRow(
                            icon: AppIcons.archive,
                            label: l.inbox_archive,
                            onTap: () {
                              Navigator.pop(ctx);
                              bulk('archive', (s) => InboxActions.archive(context, ref, s));
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
