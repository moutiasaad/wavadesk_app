import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import 'package:flutter/semantics.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../application/notifications_controller.dart';
import '../../domain/notification.dart';
import '../../domain/notification_type.dart';
import 'notification_icon.dart';
import 'notification_inline_actions.dart';

/// `NotificationTile` (Notifications spec §4.6): icon tile 34 + title +
/// subtitle (+ up to 2 inline actions) + unread dot / time. Swipe toward end
/// deletes, toward start toggles read; long-press opens the row menu. A
/// stacked group shows "{n} رسائل جديدة من {name}" + "+{n-1}" and expands
/// inline.
class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.group,
    required this.rows,
    required this.expanded,
    required this.highlighted,
    required this.online,
    required this.onTap,
    required this.onAction,
    required this.onToggleRead,
    required this.onDelete,
    required this.onLongPress,
    required this.onToggleExpand,
  });

  final NotificationGroup group;
  final Map<String, NotificationRowUi> rows;
  final bool expanded;
  final bool highlighted;
  final bool online;
  final ValueChanged<NotificationItem> onTap;
  final void Function(NotificationItem item, String actionId) onAction;
  final ValueChanged<NotificationItem> onToggleRead;
  final void Function(NotificationItem item, {required bool fullSwipe}) onDelete;
  final ValueChanged<NotificationItem> onLongPress;
  final VoidCallback onToggleExpand;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) WidgetsBinding.instance.addPostFrameCallback((_) => _runPulse());
  }

  @override
  void didUpdateWidget(NotificationTile old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !old.highlighted) _runPulse();
  }

  /// Row bg pulses `primaryContainer` 2× 600ms (§4.6); skipped with reduce motion.
  Future<void> _runPulse() async {
    if (!mounted || AppMotion.reduced(context)) return;
    for (var i = 0; i < 2; i++) {
      if (!mounted) return;
      await _pulse.forward(from: 0);
      if (!mounted) return;
      await _pulse.reverse();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final head = g.head;
    final c = context.colors;
    final l = context.l10n;

    Widget row(NotificationItem n, {bool asHead = false, bool child = false}) => _Row(
          item: n,
          ui: widget.rows[n.id],
          online: widget.online,
          stackCount: asHead && g.stacked ? g.count : null,
          indent: child,
          onTap: () => asHead && g.stacked && !widget.expanded ? widget.onToggleExpand() : widget.onTap(n),
          onAction: (id) => widget.onAction(n, id),
          onLongPress: () => widget.onLongPress(n),
          onToggleRead: () => widget.onToggleRead(n),
          onDelete: () => widget.onDelete(n, fullSwipe: false),
        );

    final content = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => ColoredBox(
        color: Color.lerp(Colors.transparent, c.primaryContainer, _pulse.value)!,
        child: child,
      ),
      child: AnimatedSize(
        duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.normal,
        curve: AppMotion.standard,
        alignment: AlignmentDirectional.topStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(head, asHead: true),
            if (g.stacked && widget.expanded)
              for (final n in g.items.skip(1)) ...[
                Divider(height: 1, color: c.divider),
                row(n, child: true),
              ],
          ],
        ),
      ),
    );

    final readLabel = head.isRead ? l.ntf_mark_unread : l.ntf_mark_read;
    return Slidable(
      key: ValueKey('ntf-slide-${head.id}'),
      groupTag: 'notifications',
      // Swipe toward the end edge → حذف (full swipe deletes, Undo snackbar).
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.24,
        dismissible: DismissiblePane(
          dismissThreshold: 0.6,
          resizeDuration: AppMotion.normal,
          onDismissed: () => widget.onDelete(head, fullSwipe: true),
        ),
        children: [
          _SwipeAction(icon: AppIcons.delete, label: l.ntf_delete, color: c.error, onPressed: () => widget.onDelete(head, fullSwipe: false)),
        ],
      ),
      // Swipe toward the start edge → مقروء / غير مقروء.
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          _SwipeAction(
            icon: head.isRead ? AppIcons.mailOpen : AppIcons.read,
            label: readLabel,
            color: c.info,
            onPressed: () => widget.onToggleRead(head),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({required this.icon, required this.label, required this.color, required this.onPressed});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = context.colors.isDark ? context.colors.background : Colors.white;
    return CustomSlidableAction(
      backgroundColor: color,
      foregroundColor: fg,
      padding: EdgeInsets.zero,
      onPressed: (_) {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, color: fg),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: context.text.caption.copyWith(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.ui,
    required this.online,
    required this.onTap,
    required this.onAction,
    required this.onLongPress,
    required this.onToggleRead,
    required this.onDelete,
    this.stackCount,
    this.indent = false,
  });

  final NotificationItem item;
  final NotificationRowUi? ui;
  final bool online;
  final int? stackCount;
  final bool indent;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;
  final VoidCallback onLongPress;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  static String _groupName(NotificationItem n) {
    final p = n.params;
    final name = p['customer'] ?? p['name'] ?? n.actor?.name;
    if (name != null && '$name'.isNotEmpty) return '$name';
    return n.body.split(' · ').first;
  }

  String _subtitleContext(AppLocalizations l) => switch (ui?.resolution) {
        'claimed_you' => l.ntf_claimed_you,
        'claimed_by' => l.ntf_claimed_by(ui?.claimedBy ?? ''),
        'approved' => l.ntf_approved,
        'rejected' => l.ntf_rejected,
        _ => NotificationTemplates.body(l, item),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final unread = !item.isRead;
    final actions = NotificationInlineActions.visible(item, ui);
    final time = RelativeTimeFormatter.format(item.createdAt, DateTime.now(), l, context.localeName);
    final trailingTime = actions.isNotEmpty || !NotificationTemplates.timeInSubtitle(item.type);
    final title = stackCount != null ? l.ntf_grouped(stackCount!, _groupName(item)) : NotificationTemplates.title(l, item);
    final ctxText = _subtitleContext(l);
    final subtitle = trailingTime || ctxText.isEmpty ? ctxText : '$ctxText · $time';
    final resolvedMuted = ui?.resolution == 'claimed_by';
    final multiLine = actions.isNotEmpty || subtitle.length > 40;

    final semantics = [
      if (unread) l.ntf_a11y_unread,
      title,
      subtitle,
      if (trailingTime) time,
    ].where((s) => s.isNotEmpty).join('، ');

    final body = Padding(
      padding: EdgeInsetsDirectional.only(start: indent ? 14 + 46 : 14, end: 14, top: AppSpacing.md, bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (!indent) ...[NotificationIcon(item: item), const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.listTitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (stackCount != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: Text('+${stackCount! - 1}', style: t.caption.copyWith(color: c.textSecondary)),
                      ),
                    ],
                  ],
                ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ExcludeSemantics(
                    child: Text(
                    subtitle,
                    maxLines: item.type.isAi ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: resolvedMuted ? c.textTertiary : c.textSecondary,
                    ),
                  ),
                  ),
                ],
                if (actions.isNotEmpty)
                  NotificationInlineActions(item: item, ui: ui, onAction: onAction, enabled: online),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (trailingTime)
            ExcludeSemantics(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: t.caption.copyWith(fontSize: 11.5, color: c.textTertiary)),
                if (unread) ...[const SizedBox(height: 6), _Dot(visible: unread)],
              ],
            ),
            )
          else
            _Dot(visible: unread),
        ],
      ),
    );

    return Opacity(
      opacity: ui?.stale == true ? 0.5 : 1,
      child: Semantics(
        button: true,
        label: semantics,
        excludeSemantics: false,
        customSemanticsActions: {
          CustomSemanticsAction(label: item.isRead ? l.ntf_mark_unread : l.ntf_mark_read): onToggleRead,
          CustomSemanticsAction(label: l.ntf_delete): onDelete,
        },
        child: InkWell(
          onTap: onTap,
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onLongPress();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// 8dp unread dot; fades out on read (150ms, §14).
class _Dot extends StatelessWidget {
  const _Dot({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.fast,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
        ),
      );
}
