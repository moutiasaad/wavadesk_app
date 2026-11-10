import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../domain/conversation_detail.dart';
import '../../domain/assignee.dart';
import '../sheets/assign/assign_sheet.dart';
import 'sheets/conversation_actions_sheet.dart';

/// Tags row under the chat header (Chat spec §4.2): ownership, status,
/// priority, linked order, contact tags (max 3 + "+n") and "+ وسم".
class ContextStrip extends ConsumerWidget {
  const ContextStrip({super.key, required this.detail});

  final ConversationDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final conv = detail.conversation;

    final ownership = switch (conv.ownership) {
      Ownership.mine => _StripChip(
        label: l.chat_assigned_you,
        fg: c.onPrimaryContainer,
        bg: c.primaryContainer,
        border: c.primaryContainerBorder,
        leading: AppIcon(AppIcons.check, size: AppIconSize.sm, color: c.onPrimaryContainer),
      ),
      Ownership.colleague => _StripChip(
        label: l.chat_assigned_to(conv.assignee?.name ?? ''),
        fg: c.statusClosed,
        bg: c.statusClosedContainer,
        leading: conv.assignee == null
            ? null
            : AppAvatar(name: conv.assignee!.name, id: conv.assignee!.id, size: AppAvatarSize.xxs),
      ),
      Ownership.unassigned => _StripChip(label: l.chat_unassigned, fg: c.statusPending, bg: c.statusPendingContainer),
      Ownership.ai => _StripChip(
        label: l.chat_ai_handling,
        fg: c.statusAi,
        bg: c.statusAiContainer,
        leading: AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.statusAi),
      ),
    };

    final statusChip = switch (conv.status) {
      ConversationStatus.snoozed => _StripChip(
        label: conv.snoozedUntil == null
            ? conv.status.label(l)
            : l.strip_snoozed_until(
                RelativeTimeFormatter.until(conv.snoozedUntil!, DateTime.now(), l, context.localeName),
              ),
        fg: c.statusSnoozed,
        bg: c.statusSnoozedContainer,
        leading: AppIcon(AppIcons.snooze, size: AppIconSize.xs, color: c.statusSnoozed),
      ),
      ConversationStatus.resolved || ConversationStatus.closed => _StripChip(
        label: conv.status.label(l),
        fg: conv.status.foreground(c),
        bg: conv.status.container(c),
        leading: AppIcon(conv.status.icon, size: AppIconSize.xs, color: conv.status.foreground(c)),
      ),
      _ => null,
    };

    final showPriority =
        conv.priority == Priority.urgent || conv.priority == Priority.high || conv.priority == Priority.medium;
    final contactTags = {...conv.customer.tags, ...conv.tags}.toList();
    final shownTags = contactTags.take(3).toList();
    final more = contactTags.length - shownTags.length;

    final chips = <Widget>[
      if (detail.permissions.canAssign && !detail.isClosed)
        _Tappable(
          label: l.as_title,
          onTap: () => showAssignSheet(context, ref, conversationIds: [detail.id], source: AssignSource.chip),
          child: ownership,
        )
      else
        ownership,
      ?statusChip,
      if (showPriority)
        _Tappable(
          label: l.a11y_priority(conv.priority.label(l)),
          onTap: () => showPriorityPicker(context, ref, conversationId: detail.id),
          child: _StripChip(
            label: conv.priority.label(l),
            fg: conv.priority.color(c),
            bg: conv.priority.color(c).withValues(alpha: c.isDark ? 0.18 : 0.10),
            leading: conv.priority == Priority.urgent
                ? AppIcon(AppIcons.priority, size: AppIconSize.xs, color: conv.priority.color(c))
                : Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: conv.priority.color(c), shape: BoxShape.circle),
                  ),
          ),
        ),
      if (conv.orderRef != null)
        _Tappable(
          label: l.strip_order(conv.orderRef!),
          onTap: () => AppSnackbar.show(context, message: l.strip_no_store_integration),
          child: _StripChip.neutral(context, l.strip_order(conv.orderRef!)),
        ),
      for (final tag in shownTags) _StripChip.neutral(context, tag),
      if (more > 0) _StripChip.neutral(context, '+$more'),
      _Tappable(
        label: l.strip_add_tag,
        onTap: () => showTagSheet(context, ref, conversationId: detail.id),
        child: DashedChip(label: l.strip_add_tag),
      ),
    ];

    // Full width: the chat Column centres its children, so without this the
    // strip shrank to its chips and floated mid-screen with no side margins.
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: 6), chips[i]],
            ],
          ),
        ),
      ),
    );
  }
}

class _StripChip extends StatelessWidget {
  const _StripChip({required this.label, required this.fg, required this.bg, this.border, this.leading});

  /// Order ref / contact tags: white pill, 1dp border, secondary text (mockup).
  factory _StripChip.neutral(BuildContext context, String label) {
    final c = context.colors;
    return _StripChip(label: label, fg: c.textSecondary, bg: c.surface, border: c.border);
  }

  final String label;
  final Color fg;
  final Color bg;
  final Color? border;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border ?? bg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(label, style: context.text.chipLabel.copyWith(color: fg), maxLines: 1),
        ],
      ),
    );
  }
}

/// Widens the hit area of a 30dp chip without changing the strip height.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: child),
    ),
  );
}

/// "+ وسم" chip with a dashed outline.
class DashedChip extends StatelessWidget {
  const DashedChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: DashedRRectPainter(color: c.borderStrong, radius: AppRadius.full),
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.add, size: AppIconSize.xs, color: c.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: context.text.chipLabel.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// 1dp dashed rounded-rect outline (dash 4, gap 3).
class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({required this.color, required this.radius, this.strokeWidth = 1});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = radius.clamp(0, size.shortestSide / 2).toDouble();
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(strokeWidth / 2), Radius.circular(r));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) => old.color != color || old.radius != radius;
}
