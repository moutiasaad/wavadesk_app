import 'package:flutter/gestures.dart' show DeviceGestureSettings, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/relative_time_ticker.dart';
import '../../domain/conversation_summary.dart';
import '../../domain/preview_formatter.dart';
import '../../domain/relative_time_formatter.dart';
import '../../domain/row_tag_resolver.dart';
import 'conversation_preview_text.dart';
import 'conversation_row_tag.dart';

/// Swipe / semantic action callbacks. `fullSwipe` is true for a dismiss.
typedef TileAction = void Function({required bool fullSwipe});

/// Inbox row (Inbox spec §4.5, DS §8.3).
class ConversationTile extends ConsumerWidget {
  const ConversationTile({
    super.key,
    required this.summary,
    this.segment = InboxSegment.all,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selecting = false,
    this.enableSwipe = true,
    this.highlight,
    this.showDivider = true,
    this.onResolve,
    this.onSnooze,
    this.onAssign,
    this.onClaim,
  });

  final ConversationSummary summary;

  /// Decides the colleague tag (only in "الكل") and the claim swipe.
  final InboxSegment segment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;
  final bool enableSwipe;

  /// Search query to highlight in name and preview.
  final String? highlight;

  /// Divider above this row (not drawn above the first item).
  final bool showDivider;
  final TileAction? onResolve;
  final TileAction? onSnooze;
  final TileAction? onAssign;
  final TileAction? onClaim;

  static const _actionWidth = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final now = ref.watch(inboxClockProvider);
    final meId = ref.watch(currentAgentProvider.select((a) => a.id));
    final draft = ref.watch(draftsProvider.select((d) => d[summary.id]));
    final s = summary;
    final preview = PreviewFormatter.format(s, meId: meId, draft: draft);
    final tag = RowTagResolver.resolve(s, segment: segment, meId: meId, now: now);
    final time = RelativeTimeFormatter.format(s.lastActivityAt, now, l, context.localeName);
    final claimable = s.assignee == null && s.isActive;

    // §9: one merged node; swipe actions are reachable as semantic actions.
    final label = [
      s.contact.name,
      s.channel.label(l),
      if (s.isUnread) l.inbox_a11y_unread(s.unreadCount),
      ConversationPreviewText.describe(preview, l),
      time,
      if (tag != null) ConversationRowTag.label(tag, now, l, context.localeName),
    ].join('، ');

    Widget tile = Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      hint: l.inbox_a11y_open_hint,
      customSemanticsActions: {
        if (onResolve != null) CustomSemanticsAction(label: l.inbox_swipe_resolve): () => onResolve!(fullSwipe: false),
        if (onSnooze != null) CustomSemanticsAction(label: l.inbox_swipe_snooze): () => onSnooze!(fullSwipe: false),
        if (claimable && onClaim != null)
          CustomSemanticsAction(label: l.inbox_swipe_claim): () => onClaim!(fullSwipe: false)
        else if (onAssign != null)
          CustomSemanticsAction(label: l.inbox_swipe_assign): () => onAssign!(fullSwipe: false),
      },
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primaryContainer : Colors.transparent,
        child: Builder(
          builder: (inner) => InkWell(
          // A tap on a row whose actions are showing just closes it — it must
          // not open the chat by accident.
          onTap: onTap == null
              ? null
              : () {
                  final slide = Slidable.of(inner);
                  if (slide != null && slide.ratio != 0) {
                    slide.close();
                    return;
                  }
                  onTap!();
                },
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          highlightColor: c.surfaceVariant,
          splashColor: c.surfaceVariant,
          child: DecoratedBox(
            decoration: const BoxDecoration(),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 76 - 2 * AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          child: _Leading(summary: s, selected: selected, selecting: selecting),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _Content(
                            summary: s,
                            preview: preview,
                            tag: tag,
                            time: time,
                            now: now,
                            highlight: highlight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showDivider)
                  PositionedDirectional(
                    top: 0,
                    start: 78,
                    end: AppSpacing.lg,
                    child: Container(height: 1, color: c.divider),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );

    if (!enableSwipe || selecting) return tile;

    // No LayoutBuilder here: a layout-time rebuild of the Slidable subtree
    // inside the sliver list corrupted the render tree ("child._parent ==
    // this"). The row is always the inbox width (screen, max 720dp).
    final width = rowWidth(context);
    double ratio(int n) => (_actionWidth * n / width).clamp(0.1, 0.9);
    final onAction = c.isDark ? c.background : Colors.white;

    Widget action(IconData icon, String text, Color bg, VoidCallback onPressed) => CustomSlidableAction(
      backgroundColor: bg,
      foregroundColor: onAction,
      padding: EdgeInsets.zero,
      onPressed: (_) => onPressed(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: onAction),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: context.text.caption.copyWith(color: onAction), maxLines: 1),
        ],
      ),
    );

    // A swipe needs a deliberate horizontal move (2× the default slop), so a
    // slightly diagonal scroll or a short touch never opens the row.
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: kTouchSlop * 2)),
      child: Slidable(
      key: ValueKey('slide-${s.id}'),
      groupTag: 'inbox',
      // Swipe toward the end edge reveals Resolve on the start side.
      startActionPane: onResolve == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: ratio(1),
              openThreshold: 0.5,
              closeThreshold: 0.5,
              dismissible: DismissiblePane(
                dismissThreshold: 0.8,
                resizeDuration: AppMotion.normal,
                onDismissed: () => onResolve!(fullSwipe: true),
              ),
              children: [action(AppIcons.claim, l.inbox_swipe_resolve, c.success, () => onResolve!(fullSwipe: false))],
            ),
      // Swipe toward the start edge reveals Snooze + Assign/Claim.
      endActionPane: onSnooze == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: ratio(2),
              openThreshold: 0.5,
              closeThreshold: 0.5,
              dismissible: DismissiblePane(
                dismissThreshold: 0.8,
                resizeDuration: AppMotion.normal,
                onDismissed: () => onSnooze!(fullSwipe: true),
              ),
              children: [
                action(AppIcons.moon, l.inbox_swipe_snooze, c.statusSnoozed, () => onSnooze!(fullSwipe: false)),
                if (claimable && onClaim != null)
                  action(AppIcons.claim, l.inbox_swipe_claim, c.primary, () => onClaim!(fullSwipe: false))
                else if (onAssign != null)
                  action(AppIcons.assign, l.inbox_swipe_assign, c.info, () => onAssign!(fullSwipe: false)),
              ],
            ),
      child: tile,
      ),
    );
  }

  /// Width of an inbox row: screen width, capped at the 720dp tablet column.
  static double rowWidth(BuildContext context) => MediaQuery.sizeOf(context).width.clamp(1.0, 720.0);
}

class _Leading extends StatelessWidget {
  const _Leading({required this.summary, required this.selected, required this.selecting});

  final ConversationSummary summary;
  final bool selected;
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (selecting && selected) {
      // 24 check circle inside the 50 avatar slot (§4.5).
      return SizedBox.square(
        dimension: 50,
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Icon(AppIcons.check, size: 16, color: c.onPrimary),
          ),
        ),
      );
    }
    return AppAvatar(
      name: summary.contact.name,
      id: summary.contact.id,
      imageUrl: summary.contact.avatarUrl,
      channel: summary.channel,
      size: AppAvatarSize.lg,
      ringColor: selected ? c.primaryContainer : c.background,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.summary,
    required this.preview,
    required this.tag,
    required this.time,
    required this.now,
    this.highlight,
  });

  final ConversationSummary summary;
  final PreviewData preview;
  final RowTag? tag;
  final String time;
  final DateTime now;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final s = summary;
    final unread = s.isUnread;

    final nameStyle = t.listTitle.copyWith(fontWeight: unread ? FontWeight.w800 : FontWeight.w700);
    final timeStyle = t.listTimestamp.copyWith(
      color: unread ? c.primary : c.textTertiary,
      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
    );
    final showPriority = s.priority != null && s.priority != Priority.low;

    final name = _Highlighted(text: s.contact.name, style: nameStyle, query: highlight);
    final timestamp = Text(time, style: timeStyle, maxLines: 1);
    final priority = showPriority
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: PriorityIndicator(priority: s.priority!),
          )
        : null;

    // Content width = row − horizontal padding − avatar(50) − gap. Computed
    // instead of a LayoutBuilder (see ConversationTile.build).
    final maxWidth = ConversationTile.rowWidth(context) - 2 * AppSpacing.lg - 50 - AppSpacing.md;
    // 200% text: move the timestamp under the name when the name would
    // get less than 40% of the row (§9).
    final scaler = MediaQuery.textScalerOf(context);
    final timeWidth = (TextPainter(
      text: TextSpan(text: time, style: timeStyle),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout()).width;
    final stacked = maxWidth - timeWidth - 32 < maxWidth * 0.4;

    final firstRow = stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: name),
                  ?priority,
                ],
              ),
              timestamp,
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(child: name),
                    ?priority,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              timestamp,
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        firstRow,
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: ConversationPreviewText(preview: preview, unread: unread, highlight: highlight),
            ),
            if (unread) ...[const SizedBox(width: AppSpacing.sm), CountBadge(count: s.unreadCount)],
          ],
        ),
        if (tag != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              children: [ConversationRowTag(tag: tag!, now: now)],
            ),
          ),
      ],
    );
  }
}

class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.style, this.query});

  final String text;
  final TextStyle style;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final q = query?.trim() ?? '';
    final i = q.isEmpty ? -1 : text.toLowerCase().indexOf(q.toLowerCase());
    if (i < 0) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    final hl = style.copyWith(background: Paint()..color = context.colors.searchHighlight);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(text: text.substring(i, i + q.length), style: hl),
          TextSpan(text: text.substring(i + q.length)),
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
