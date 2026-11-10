import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// §8.21 unread badge: min 20×20, pill, `primary` in lists. In the tab bar
/// (§8.2) it's 18 min, `error`, with a 2dp `background` ring — use [tab].
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, this.color}) : _tab = false;

  const CountBadge.tab({super.key, required this.count}) : color = null, _tab = true;

  final int count;
  final Color? color;
  final bool _tab;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = count > 99 ? '99+' : '$count';
    final min = _tab ? 18.0 : 20.0;
    return Container(
      constraints: BoxConstraints(minWidth: min + (_tab ? 4 : 0), minHeight: min + (_tab ? 4 : 0)),
      padding: EdgeInsets.symmetric(horizontal: _tab ? 5 : 6),
      decoration: BoxDecoration(
        color: _tab ? c.error : (color ?? c.primary),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: _tab ? Border.all(color: c.background, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: context.text.badge.copyWith(color: _tab ? Colors.white : c.onPrimary),
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      ),
    );
  }
}
