import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/conversation_filters.dart';
import 'inbox_palette.dart';

/// Inbox v2 §4.2: `#FAFBFC` bar with a horizontal pill scroller (fades out
/// toward the filter button) and the fixed 42dp round filter button.
class InboxFilterBar extends StatefulWidget {
  const InboxFilterBar({
    super.key,
    required this.pill,
    required this.counts,
    required this.advancedCount,
    required this.onPill,
    required this.onFilters,
  });

  final InboxPill pill;
  final Map<String, int> counts;
  final int advancedCount;
  final ValueChanged<InboxPill> onPill;
  final VoidCallback onFilters;

  static String label(AppLocalizations l, InboxPill p) => switch (p) {
    InboxPill.all => l.inbox_chip_all,
    InboxPill.mine => l.inbox_seg_mine,
    InboxPill.unread => l.inbox_chip_unread,
    InboxPill.unassigned => l.inbox_seg_unassigned,
    InboxPill.waiting => l.inbox_chip_awaiting,
    InboxPill.ai => l.inbox_chip_ai,
    InboxPill.closed => l.inbox_chip_closed,
  };

  @override
  State<InboxFilterBar> createState() => _InboxFilterBarState();
}

class _InboxFilterBarState extends State<InboxFilterBar> {
  final _keys = {for (final p in InboxPill.values) p: GlobalKey()};

  @override
  void didUpdateWidget(InboxFilterBar old) {
    super.didUpdateWidget(old);
    if (old.pill != widget.pill) _reveal();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(jump: true));
  }

  /// The selected pill scrolls fully into view (250ms).
  void _reveal({bool jump = false}) {
    final ctx = _keys[widget.pill]?.currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: jump || AppMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  int? _count(InboxPill p) => switch (p) {
    InboxPill.mine => widget.counts['mine'],
    InboxPill.unread => widget.counts['unread'],
    InboxPill.unassigned => widget.counts['unassigned'],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = InboxPalette.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: p.filterBar,
        border: Border(bottom: BorderSide(color: p.filterBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ShaderMask(
              // Full opacity until 85% of the width, then fades out at the
              // end edge (toward the filter button).
              shaderCallback: (rect) => LinearGradient(
                begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
                end: rtl ? Alignment.centerLeft : Alignment.centerRight,
                stops: const [0, 0.85, 1],
                colors: const [Colors.black, Colors.black, Colors.transparent],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Semantics(
                label: l.inbox_pills_a11y,
                container: true,
                explicitChildNodes: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  // 4 / 16 / 6: extra top/bottom room keeps the shadows visible.
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 6),
                  child: Row(
                    children: [
                      for (final pill in InboxPill.values) ...[
                        if (pill != InboxPill.values.first) const SizedBox(width: 8),
                        _FilterPill(
                          key: _keys[pill],
                          label: InboxFilterBar.label(l, pill),
                          count: _count(pill),
                          selected: pill == widget.pill,
                          onTap: () => widget.onPill(pill),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: _FilterButton(active: widget.advancedCount, onTap: widget.onFilters),
          ),
        ],
      ),
    );
  }
}

String _cap(int n) => n > 99 ? '99+' : '$n';

class _FilterPill extends StatefulWidget {
  const _FilterPill({super.key, required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = InboxPalette.of(context);
    final t = context.text;
    final sel = widget.selected;
    final n = widget.count ?? 0;
    final reduced = AppMotion.reduced(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: sel,
      label: n > 0 ? context.l10n.inbox_pill_a11y(widget.label, _cap(n)) : widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down && !reduced ? 0.97 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: sel ? p.pillSel : p.pill,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: sel ? p.pillSelBorder : p.pillBorder),
              boxShadow: sel ? const [] : p.pillShadow(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: t.bodySmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: sel ? p.pillSelText : p.pillText),
                ),
                if (n > 0) ...[
                  const SizedBox(width: 7),
                  Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.count, borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Text(
                      _cap(n),
                      textDirection: TextDirection.ltr,
                      style: t.caption.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1, color: p.countText),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 42dp round filter button (48 hit); green with a count once advanced
/// filters are applied (§4.2.2).
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final int active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = InboxPalette.of(context);
    final on = active > 0;
    return Semantics(
      button: true,
      label: context.l10n.inbox_flt_title,
      value: on ? '$active' : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: on ? p.pillSel : p.pill,
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? p.pillSelBorder : p.pillBorder),
                    boxShadow: p.pillShadow(strong: true),
                  ),
                  child: Center(child: AppIcon(AppIcons.filter, dp: 20, color: on ? p.pillSelText : p.filterIcon)),
                ),
                if (on)
                  PositionedDirectional(
                    top: -3,
                    end: -3,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.pillSelText, borderRadius: BorderRadius.circular(AppRadius.full)),
                      child: Text(
                        _cap(active),
                        style: context.text.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, height: 1, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
