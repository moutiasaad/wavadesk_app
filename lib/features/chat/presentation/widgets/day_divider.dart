import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// Day pill (Chat spec §4.3): اليوم · أمس · weekday (< 7 days) ·
/// `d MMMM yyyy`. `surface` bg, `dayDivider` text.
class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.day});

  final DateTime day;

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String label(BuildContext context, DateTime day) {
    final l = context.l10n;
    final now = DateTime.now();
    final locale = context.localeName;
    if (_same(day, now)) return l.time_today;
    if (_same(day, now.subtract(const Duration(days: 1)))) return l.time_yesterday;
    final today = DateTime(now.year, now.month, now.day);
    if (today.difference(DateTime(day.year, day.month, day.day)).inDays < 7) {
      return intl.DateFormat.EEEE(locale).format(day);
    }
    return '${day.day} ${intl.DateFormat.MMMM(locale).format(day)} ${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Semantics(
          header: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: context.shadows.low,
              border: c.isDark ? Border.all(color: c.divider) : null,
            ),
            child: Text(label(context, day), style: context.text.dayDivider),
          ),
        ),
      ),
    );
  }
}
