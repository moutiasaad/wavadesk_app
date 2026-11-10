import '../../../l10n/app_localizations.dart';
import 'notification.dart';

/// Day groups of the list (Notifications spec §3): اليوم · أمس · هذا الأسبوع
/// · أقدم, by `created_at` in the workspace time zone.
enum DayGroup {
  today,
  yesterday,
  thisWeek,
  older;

  String label(AppLocalizations l) => switch (this) {
        today => l.ntf_today,
        yesterday => l.ntf_yesterday,
        thisWeek => l.ntf_this_week,
        older => l.ntf_older,
      };
}

/// [utcOffset] is the workspace offset when known; null → device local time.
DayGroup dayGroupOf(DateTime createdAt, DateTime now, {Duration? utcOffset}) {
  DateTime local(DateTime t) => utcOffset == null ? t.toLocal() : t.toUtc().add(utcOffset);
  final t = local(createdAt);
  final n = local(now);
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return DayGroup.today;
  if (diff == 1) return DayGroup.yesterday;
  if (diff < 7) return DayGroup.thisWeek;
  return DayGroup.older;
}

/// Groups (already stacked) rows by day, keeping server order inside a group.
List<(DayGroup, List<NotificationGroup>)> groupByDay(
  List<NotificationGroup> groups,
  DateTime now, {
  Duration? utcOffset,
}) {
  final map = <DayGroup, List<NotificationGroup>>{};
  for (final g in groups) {
    map.putIfAbsent(dayGroupOf(g.head.createdAt, now, utcOffset: utcOffset), () => []).add(g);
  }
  return [
    for (final d in DayGroup.values)
      if (map[d] != null) (d, map[d]!),
  ];
}
