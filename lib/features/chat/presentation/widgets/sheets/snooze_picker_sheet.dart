import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Snooze picker (Chat spec §6): بعد ساعة · بعد 3 ساعات · غدًا 9 ص ·
/// الأسبوع القادم · مخصص (date + time). Returns the chosen moment.
Future<DateTime?> showSnoozePicker(BuildContext context) async {
  final l = context.l10n;
  final now = DateTime.now();
  final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9);
  final nextWeek = DateTime(now.year, now.month, now.day + 7, 9);
  final locale = context.localeName;
  String fmt(DateTime t) => '${intl.DateFormat.E(locale).format(t)} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  final options = <(IconData, String, DateTime?)>[
    (AppIcons.clock, l.snooze_one_hour, now.add(const Duration(hours: 1))),
    (AppIcons.clock, l.snooze_three_hours, now.add(const Duration(hours: 3))),
    (AppIcons.away, l.snooze_tomorrow, tomorrow9),
    (AppIcons.history, l.snooze_next_week, nextWeek),
    (AppIcons.edit, l.snooze_custom, null),
  ];

  // The custom row returns a sentinel; null means dismissed.
  final sentinel = DateTime.fromMillisecondsSinceEpoch(0);
  final picked = await AppBottomSheet.show<DateTime>(
    context,
    title: l.snooze_title,
    subtitle: l.snoozepick_subtitle,
    builder: (ctx) => Column(
      children: [
        for (final (icon, label, time) in options)
          SheetActionRow(
            icon: icon,
            label: label,
            trailing: time == null
                ? AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: ctx.colors.borderStrong)
                : Text(
                    fmt(time),
                    textDirection: TextDirection.ltr,
                    style: ctx.text.bodySmall.copyWith(color: ctx.colors.textSecondary),
                  ),
            onTap: () => Navigator.pop(ctx, time ?? sentinel),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return null;
  if (picked != sentinel) return picked;

  final date = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
  if (time == null) return null;
  final until = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  return until.isAfter(now) ? until : now.add(const Duration(hours: 1));
}
