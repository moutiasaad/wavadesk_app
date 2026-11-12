import 'package:flutter/gestures.dart' show DeviceGestureSettings, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/data/data.dart';
import '../../../../core/icons/wd_svg_icons.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../application/relative_time_ticker.dart';
import '../../domain/conversation_summary.dart';
import '../../domain/preview_formatter.dart';
import '../../domain/relative_time_formatter.dart';
import '../../domain/row_tag_resolver.dart';
import 'conversation_preview_text.dart';
import 'conversation_row_tag.dart';
import 'inbox_palette.dart';

/// Swipe / semantic action callbacks. `fullSwipe` is true for a dismiss.
typedef TileAction = void Function({required bool fullSwipe});

/// Inbox row (Inbox v2 §4.3–4.5).
class ConversationTile extends ConsumerWidget {
  const ConversationTile({
    super.key,
    required this.summary,
    this.allPill = false,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selecting = false,
    this.enableSwipe = true,
    this.highlight,
    this.showDivider = true,
    this.onClaim,
    this.onAssign,
    this.onClose,
    this.onReopen,
    this.onToggleRead,
  });

  final ConversationSummary summary;

  /// Row is in the "الكل" pill (unassigned / colleague tags).
  final bool allPill;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;
  final bool enableSwipe;

  /// Search query to highlight in name and preview.
  final String? highlight;

  /// Divider above this row (not drawn above the first item).
  final bool showDivider;
  final TileAction? onClaim;
  final TileAction? onAssign;
  final TileAction? onClose;
  final TileAction? onReopen;
  final TileAction? onToggleRead;

  static const _actionWidth = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final p = InboxPalette.of(context);
    final now = ref.watch(inboxClockProvider);
    final me = ref.watch(currentAgentProvider);
    final draft = ref.watch(draftsProvider.select((d) => d[summary.id]));
    final s = summary;
    final preview = PreviewFormatter.format(s, meId: me.id, draft: draft);
    final tag = RowTagResolver.resolve(s, meId: me.id, now: now, allPill: allPill, lead: me.canManage);
    final time = RelativeTimeFormatter.format(s.lastActivityAt, now, l, context.localeName);
    final claimable = s.assignee == null && s.isActive;
    // Unknown customer → the phone number, isolated LTR.
    final displayName = s.contact.name.trim().isEmpty ? ltr(s.contact.phone ?? '') : s.contact.name;

    final primary = claimable ? onClaim : onAssign;
    final primaryLabel = claimable ? l.inbox_act_claim : l.inbox_act_assign;
    final closeAction = s.isClosed ? onReopen : onClose;
    final closeLabel = s.isClosed ? l.inbox_act_reopen : l.inbox_act_close;
    final readLabel = s.isUnread ? l.inbox_act_read : l.inbox_act_unread;

    // §10: one merged node; swipe actions are reachable as semantic actions.
    final label = [
      displayName,
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
        if (primary != null) CustomSemanticsAction(label: primaryLabel): () => primary(fullSwipe: false),
        if (closeAction != null) CustomSemanticsAction(label: closeLabel): () => closeAction(fullSwipe: false),
        if (onToggleRead != null) CustomSemanticsAction(label: readLabel): () => onToggleRead!(fullSwipe: false),
      },
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primaryContainer : Colors.transparent,
        child: Builder(
          builder: (inner) => InkWell(
            // A tap on a row whose actions are showing just closes it — it
            // must not open the chat by accident.
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
            highlightColor: p.pressed,
            splashColor: p.pressed,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: (tag == null ? 72 : 78) - 22),
                    child: Row(
                      children: [
                        RepaintBoundary(
                          child: InboxAvatar(summary: s, name: displayName, checked: selecting && selected),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Content(
                            summary: s,
                            name: displayName,
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
                  // Starts after the avatar (80) and ends 18 from the far edge.
                  PositionedDirectional(top: 0, start: 80, end: 18, child: Container(height: 1, color: p.divider)),
              ],
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

    Widget action(IconData icon, String text, Color bg, VoidCallback onPressed) => CustomSlidableAction(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          onPressed: (_) => onPressed(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, dp: 20, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                text,
                maxLines: 1,
                style: context.text.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        );

    final endActions = [
      if (primary != null)
        action(
          claimable ? AppIcons.claim : AppIcons.team,
          primaryLabel,
          claimable ? InboxPalette.swipeClaim : InboxPalette.swipeAssign,
          () => primary(fullSwipe: false),
        ),
      if (closeAction != null)
        action(
          s.isClosed ? AppIcons.redo : AppIcons.check,
          closeLabel,
          s.isClosed ? InboxPalette.swipeReopen : InboxPalette.swipeClose,
          () => closeAction(fullSwipe: false),
        ),
    ];
    // Full swipe runs the first action.
    final TileAction? fullSwipe = primary ?? closeAction;

    // A swipe needs a deliberate horizontal move (2× the default slop), so a
    // slightly diagonal scroll or a short touch never opens the row.
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: kTouchSlop * 2)),
      child: Slidable(
        key: ValueKey('slide-${s.id}'),
        groupTag: 'inbox',
        // Swipe from the start → end: read / unread.
        startActionPane: onToggleRead == null
            ? null
            : ActionPane(
                motion: const DrawerMotion(),
                extentRatio: ratio(1),
                openThreshold: ratio(1) * 0.6,
                closeThreshold: ratio(1) * 0.4,
                dismissible: DismissiblePane(
                  dismissThreshold: 0.8,
                  confirmDismiss: () async {
                    HapticFeedback.lightImpact();
                    onToggleRead!(fullSwipe: true);
                    return false; // the row stays; only its read state flips
                  },
                  onDismissed: () {},
                ),
                children: [action(AppIcons.read, readLabel, InboxPalette.swipeRead, () => onToggleRead!(fullSwipe: false))],
              ),
        // Swipe from the end → start: claim / assign + close / reopen.
        endActionPane: endActions.isEmpty
            ? null
            : ActionPane(
                motion: const DrawerMotion(),
                extentRatio: ratio(endActions.length),
                openThreshold: ratio(endActions.length) * 0.6,
                closeThreshold: ratio(endActions.length) * 0.4,
                dismissible: fullSwipe == null
                    ? null
                    : DismissiblePane(
                        dismissThreshold: 0.8,
                        resizeDuration: AppMotion.normal,
                        confirmDismiss: () async {
                          HapticFeedback.lightImpact();
                          // Only closing removes the row; claim / assign
                          // keep it and refresh in place.
                          final removes = fullSwipe == onClose;
                          if (!removes) fullSwipe(fullSwipe: false);
                          return removes;
                        },
                        onDismissed: () => fullSwipe(fullSwipe: true),
                      ),
                children: endActions,
              ),
        child: tile,
      ),
    );
  }

  /// Width of an inbox row: screen width, capped at the 720dp tablet column.
  static double rowWidth(BuildContext context) => MediaQuery.sizeOf(context).width.clamp(1.0, 720.0);
}

/// 50dp customer avatar (§4.3): photo or first letter on a soft color from
/// a stable hash of the customer id, channel badge (19) at the bottom-left
/// in both directions. While selecting, a teal check circle.
class InboxAvatar extends StatelessWidget {
  const InboxAvatar({super.key, required this.summary, required this.name, this.checked = false});

  final ConversationSummary summary;
  final String name;
  final bool checked;

  static double _hue(String seed) {
    var h = 0;
    for (final u in seed.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return (h % 360).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = InboxPalette.of(context);
    if (checked) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
        child: AppIcon(AppIcons.check, dp: 22, color: c.onPrimary),
      );
    }
    final s = summary;
    final h = _hue(s.contact.id.isEmpty ? s.id : s.contact.id);
    final dark = c.isDark;
    final bg = HSLColor.fromAHSL(1, h, dark ? 0.30 : 0.55, dark ? 0.22 : 0.92).toColor();
    final fg = HSLColor.fromAHSL(1, h, dark ? 0.60 : 0.45, dark ? 0.80 : 0.30).toColor();
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '#' : String.fromCharCode(trimmed.runes.first);
    final letter = Center(
      child: Text(
        initial.toUpperCase(),
        textScaler: TextScaler.noScaling,
        style: context.text.h4.copyWith(fontSize: 18, fontWeight: FontWeight.w800, height: 1, color: fg),
      ),
    );
    final url = s.contact.avatarUrl;
    final ch = s.channel;
    final (Color badgeBg, IconData glyph) = switch (ch) {
      Channel.whatsapp => (const Color(0xFF25D366), WdSvgIcons.whatsapp),
      Channel.web => (const Color(0xFF2563EB), AppIcons.webChat),
      _ => (ChannelIcon.brandOf(ch, c), ChannelIcon.glyphOf(ch)),
    };
    return SizedBox.square(
      dimension: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: url == null || url.isEmpty
                ? letter
                : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => letter),
          ),
          // Bottom −1, left −2: fixed in both directions, as in the mockup.
          Positioned(
            bottom: -1,
            left: -2,
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: p.list, width: 2),
              ),
              child: AppIcon(glyph, dp: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.summary,
    required this.name,
    required this.preview,
    required this.tag,
    required this.time,
    required this.now,
    this.highlight,
  });

  final ConversationSummary summary;
  final String name;
  final PreviewData preview;
  final RowTag? tag;
  final String time;
  final DateTime now;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = InboxPalette.of(context);
    final s = summary;
    final unread = s.isUnread;

    final nameStyle = t.listTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: p.name);
    final timeStyle = t.listTimestamp.copyWith(
      fontSize: 12,
      color: unread ? p.unread : p.time,
      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _Highlighted(text: name, style: nameStyle, query: highlight),
            ),
            const SizedBox(width: 6),
            Text(time, style: timeStyle, maxLines: 1),
          ],
        ),
        const SizedBox(height: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ConversationPreviewText(preview: preview, unread: unread, highlight: highlight)),
            if (unread) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.unread, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(
                  s.unreadCount > 99 ? '99+' : '${s.unreadCount}',
                  textDirection: TextDirection.ltr,
                  style: t.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w800, height: 1, color: p.unreadText),
                ),
              ),
            ],
          ],
        ),
        if (tag != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(children: [ConversationRowTag(tag: tag!, now: now)]),
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
    if (i < 0) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
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
