import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../chat/domain/assignee.dart';
import '../../chat/presentation/sheets/assign/assign_sheet.dart';
import '../application/conversations_controller.dart';

/// Inbox actions with their snackbars (Inbox spec §4.5.4, §4.9). Shared by
/// swipe actions, semantic actions and the multi-select bar.
abstract final class InboxActions {
  static ConversationsController _ctrl(WidgetRef ref) => ref.read(conversationsControllerProvider.notifier);

  static void _result(BuildContext context, InboxActionResult r, {required String message, required String action}) {
    final l = context.l10n;
    if (r.failed) {
      AppSnackbar.show(context, message: l.inbox_action_failed, kind: SnackKind.error);
      return;
    }
    final undo = r.undo;
    AppSnackbar.show(
      context,
      message: message,
      kind: SnackKind.success,
      actionLabel: undo == null ? null : l.inbox_undo,
      onAction: undo == null
          ? null
          : () {
              Analytics.log('inbox_undo', {'action': action});
              undo();
            },
    );
  }

  static Future<void> resolve(BuildContext context, WidgetRef ref, Set<String> ids, {bool fullSwipe = false}) async {
    HapticFeedback.lightImpact();
    final l = context.l10n;
    if (ids.length == 1) Analytics.log('inbox_swipe_action', {'action': 'resolve', 'full_swipe': fullSwipe});
    final r = await _ctrl(ref).resolve(ids);
    if (!context.mounted) return;
    _result(
      context,
      r,
      message: ids.length == 1 ? l.inbox_resolved : l.inbox_resolved_n(ids.length),
      action: 'resolve',
    );
  }

  static Future<void> snooze(
    BuildContext context,
    WidgetRef ref,
    Set<String> ids, {
    Duration duration = const Duration(hours: 1),
    bool fullSwipe = false,
  }) async {
    final l = context.l10n;
    if (ids.length == 1) Analytics.log('inbox_swipe_action', {'action': 'snooze', 'full_swipe': fullSwipe});
    final r = await _ctrl(ref).snooze(ids, duration: duration);
    if (!context.mounted) return;
    final message = duration == const Duration(hours: 1)
        ? (ids.length == 1 ? l.inbox_snoozed_1h : l.inbox_snoozed_n(ids.length))
        : l.inbox_snoozed_n(ids.length);
    _result(context, r, message: message, action: 'snooze');
  }

  static Future<void> claim(BuildContext context, WidgetRef ref, String id) async {
    HapticFeedback.lightImpact();
    Analytics.log('inbox_swipe_action', {'action': 'claim', 'full_swipe': false});
    final r = await _ctrl(ref).claim(id);
    if (!context.mounted) return;
    final l = context.l10n;
    Analytics.log('claim_result', {
      'result': r.claimedBy != null ? 'conflict' : (r.forbidden ? 'forbidden' : (r.failed ? 'network' : 'ok')),
      'latency_ms': 0,
      'source': 'swipe',
    });
    if (r.claimedBy != null) {
      // Row already removed from Unassigned (Claim spec §7.3).
      AppSnackbar.show(context, message: l.claim_conflict(r.claimedBy!), kind: SnackKind.error);
    } else if (r.forbidden) {
      AppSnackbar.show(context, message: l.claim_forbidden, kind: SnackKind.error);
    } else if (r.failed) {
      AppSnackbar.show(context, message: l.claim_network_error, kind: SnackKind.error);
    } else {
      AppSnackbar.show(
        context,
        message: l.claim_success_event,
        kind: SnackKind.success,
        actionLabel: l.inbox_open,
        onAction: () => context.push(Routes.chat(id)),
      );
    }
  }

  static Future<void> assign(BuildContext context, WidgetRef ref, Set<String> ids) {
    if (ids.length == 1) Analytics.log('inbox_swipe_action', {'action': 'assign', 'full_swipe': false});
    return showAssignSheet(
      context,
      ref,
      conversationIds: ids,
      source: ids.length > 1 ? AssignSource.bulk : AssignSource.swipe,
    );
  }

  static Future<void> setRead(BuildContext context, WidgetRef ref, Set<String> ids, {required bool read}) async {
    final r = await _ctrl(ref).setRead(ids, read: read);
    if (!context.mounted) return;
    final l = context.l10n;
    _result(
      context,
      r,
      message: read ? l.inbox_marked_read_n(ids.length) : l.inbox_marked_unread_n(ids.length),
      action: 'read',
    );
  }

  static Future<void> archive(BuildContext context, WidgetRef ref, Set<String> ids) async {
    final r = await _ctrl(ref).archive(ids);
    if (!context.mounted) return;
    _result(context, r, message: context.l10n.inbox_archived_n(ids.length), action: 'archive');
  }

  /// Bulk snooze picker (1h / 3h / tomorrow 9:00 / next week).
  static Future<void> pickSnooze(BuildContext context, WidgetRef ref, Set<String> ids) async {
    final l = context.l10n;
    final now = DateTime.now();
    final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9);
    final nextWeek = DateTime(now.year, now.month, now.day + 7, 9);
    final picked = await AppBottomSheet.show<Duration>(
      context,
      title: l.snooze_title,
      builder: (ctx) => Column(
        children: [
          for (final (icon, label, d) in [
            (AppIcons.clock, l.snooze_one_hour, const Duration(hours: 1)),
            (AppIcons.clock, l.snooze_three_hours, const Duration(hours: 3)),
            (AppIcons.away, l.snooze_tomorrow, tomorrow9.difference(now)),
            (AppIcons.history, l.snooze_next_week, nextWeek.difference(now)),
          ])
            SheetActionRow(icon: icon, label: label, onTap: () => Navigator.pop(ctx, d)),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    await snooze(context, ref, ids, duration: picked);
  }

  static Future<void> pickPriority(BuildContext context, WidgetRef ref, Set<String> ids) async {
    final l = context.l10n;
    final p = await AppBottomSheet.show<Priority>(
      context,
      title: l.inbox_priority,
      builder: (ctx) => Column(
        children: [
          for (final p in Priority.values)
            SheetActionRow(
              icon: AppIcons.priority,
              label: p.label(ctx.l10n),
              trailing: PriorityIndicator(priority: p),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ],
      ),
    );
    if (p == null || !context.mounted) return;
    final r = await _ctrl(ref).setPriority(ids, p);
    if (!context.mounted) return;
    _result(context, r, message: l.inbox_priority_set(p.label(l)), action: 'priority');
  }

  static Future<void> pickTag(BuildContext context, WidgetRef ref, Set<String> ids) async {
    final l = context.l10n;
    final tags = ref.read(allTagsProvider);
    final tag = await AppBottomSheet.show<String>(
      context,
      title: l.inbox_tag,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in tags) AppFilterChip(label: t, selected: false, onTap: () => Navigator.pop(ctx, t)),
          ],
        ),
      ),
    );
    if (tag == null || !context.mounted) return;
    final r = await _ctrl(ref).addTag(ids, tag);
    if (!context.mounted) return;
    _result(context, r, message: l.inbox_tag_added(tag), action: 'tag');
  }
}
