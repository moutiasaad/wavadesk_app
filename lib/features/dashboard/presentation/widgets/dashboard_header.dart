import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/data/data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../conversations/application/relative_time_ticker.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/greeting.dart';
import 'presence_pill.dart';

/// Date + greeting + presence pill (spec §4.1); renders from local user
/// data before the first answer. Under it: "آخر تحديث" for cached /
/// offline snapshots (§6).
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);
    final now = ref.watch(inboxClockProvider);
    final loc = context.localeName;

    // Latin digits for the day, localized names (§7).
    final date = '${intl.DateFormat('EEEE', loc).format(now)}، ${now.day} ${intl.DateFormat('MMMM', loc).format(now)}';
    final name = Greeting.firstName(me.name);
    final greeting = Greeting.partOf(now) == GreetingPart.morning ? l.dash_morning(name) : l.dash_evening(name);

    final showUpdated = (state.fromCache || state.offline) && state.lastUpdated != null;
    final updated = state.lastUpdated == null ? '' : intl.DateFormat('HH:mm').format(state.lastUpdated!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: t.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary)),
                const SizedBox(height: 2),
                Semantics(
                  header: true,
                  child: Text(
                    greeting,
                    style: t.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w800, color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showUpdated)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l.dash_last_updated(updated),
                      style: t.caption.copyWith(color: state.offline ? c.textWarning : c.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(padding: const EdgeInsets.only(top: 6), child: PresencePill(gender: me.gender)),
        ],
      ),
    );
  }
}
