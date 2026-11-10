import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/contact.dart';

/// Stats strip (§5.3): conversations · orders (or rating) · first contact.
/// `backgroundMuted`, radius 16, 1dp dividers. Switches to a vertical list
/// at large text so labels never clip.
class ProfileStatsStrip extends StatelessWidget {
  const ProfileStatsStrip({super.key, required this.contact, this.onConversationsTap, this.onOrdersTap});

  final Contact contact;
  final VoidCallback? onConversationsTap;
  final VoidCallback? onOrdersTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ct = contact;

    final (String secondValue, String secondLabel) = ct.ordersCount != null
        ? ('${ct.ordersCount}', l.profile_stat_orders)
        : ct.csat != null
            ? (ct.csat!.toStringAsFixed(1), l.profile_stat_rating)
            : ('—', l.profile_stat_orders);
    final first = ct.firstContactAt == null
        ? '—'
        : '${intl.DateFormat.MMMM(context.localeName).format(ct.firstContactAt!)} ${ct.firstContactAt!.year}';

    final cells = [
      (value: '${ct.conversationsCount}', label: l.profile_stat_conversations, size: 20.0, onTap: onConversationsTap),
      (value: secondValue, label: secondLabel, size: 20.0, onTap: ct.ordersCount != null ? onOrdersTap : null),
      (value: first, label: l.profile_stat_first, size: 15.0, onTap: null),
    ];

    Widget cell(({String value, String label, double size, VoidCallback? onTap}) x, {bool row = false}) {
      final value = Text(
        x.value,
        style: t.h3.copyWith(fontSize: x.size, fontFeatures: const [FontFeature.tabularFigures()]),
        textAlign: TextAlign.center,
      );
      final label = Text(x.label, style: t.caption.copyWith(color: c.textSecondary), textAlign: TextAlign.center);
      return InkWell(
        onTap: x.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: row ? AppSpacing.sm : 0, horizontal: AppSpacing.md),
          child: row
              ? Row(children: [Expanded(child: label), value])
              : Column(mainAxisSize: MainAxisSize.min, children: [value, const SizedBox(height: 2), label]),
        ),
      );
    }

    final large = MediaQuery.textScalerOf(context).scale(10) > 15;
    return Semantics(
      container: true,
      label: l.profile_stats_a11y(ct.conversationsCount, secondValue, secondLabel, first),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: large ? AppSpacing.xs : AppSpacing.md),
        decoration: BoxDecoration(
          color: c.isDark ? c.surface : c.backgroundMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: large
            ? Column(
                children: [
                  for (var i = 0; i < cells.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.divider),
                    cell(cells[i], row: true),
                  ],
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.divider),
                      Expanded(child: cell(cells[i])),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
