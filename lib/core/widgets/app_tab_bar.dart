import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'count_badge.dart';

class AppTabItem {
  const AppTabItem({required this.icon, required this.label, this.badge = 0});

  final IconData icon;
  final String label;
  final int badge;
}

/// §8.2. 4 tabs, height 56 + safe area, `background` @ 96% + blur 20, top
/// 1dp `divider`. Icon Library §4: inactive = outline `textTertiary` 24;
/// active = same outline icon in `primary` on a `primaryContainer` pill,
/// label `primary` weight 700 (Lucide has no filled variants). Labels always
/// visible, no shifting — except above 160% text scale where they hide and
/// icons keep tooltips (§11).
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hideLabels = MediaQuery.textScalerOf(context).scale(10) > 16;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: c.divider)),
          ),
          padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm + bottom),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _TabButton(
                    item: items[i],
                    selected: i == currentIndex,
                    hideLabel: hideLabels,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.selected, required this.hideLabel, required this.onTap});

  final AppTabItem item;
  final bool selected;
  final bool hideLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.textTertiary;
    final label = item.badge > 0 ? '${item.label}, ${item.badge}' : item.label;

    final reduced = AppMotion.reduced(context);
    Widget icon = AnimatedContainer(
      duration: reduced ? Duration.zero : AppMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? c.primaryContainer : c.primaryContainer.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: AppIcon(item.icon, dp: 20, color: color),
    );
    if (item.badge > 0) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          PositionedDirectional(top: -4, end: 2, child: CountBadge.tab(count: item.badge)),
        ],
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        triggerMode: hideLabel ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          highlightShape: BoxShape.rectangle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                if (!hideLabel) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: context.text.overline.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
