import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../domain/contact.dart';
import 'profile_hero.dart';

/// Orders (§5.8) — only with an e-commerce integration. Last 3 orders,
/// status badges, total spent. v1 opens the store page externally.
class ProfileOrdersSection extends StatelessWidget {
  const ProfileOrdersSection({super.key, required this.contact});

  final Contact contact;

  static String money(BuildContext context, num v) =>
      intl.NumberFormat.decimalPattern('en').format(v); // Latin digits, like phone numbers

  Future<void> _open(BuildContext context, ContactOrder o) async {
    if (o.url == null) {
      AppSnackbar.show(context, message: context.l10n.profile_no_order_link);
      return;
    }
    await launchUrl(Uri.parse(o.url!), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final orders = contact.orders;
    if (orders == null) return const SizedBox.shrink();
    final shown = orders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: l.profile_orders,
          actionLabel: orders.isEmpty ? null : l.profile_view_all,
          onAction: orders.isEmpty ? null : () => _open(context, orders.first),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 60, color: c.divider),
                  InkWell(
                    onTap: () => _open(context, shown[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                            child: Icon(AppIcons.bag, size: 17, color: c.textSecondary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ltr(shown[i].number), style: t.listTitle),
                                Text(
                                  l.profile_order_items(
                                    RelativeTimeFormatter.dayMonth(shown[i].date, DateTime.now(), context.localeName),
                                    shown[i].itemsCount,
                                  ),
                                  style: t.caption.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l.profile_amount(money(context, shown[i].total)),
                                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              _status(context, shown[i].status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (contact.ordersTotalSpent != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l.profile_total_spent(money(context, contact.ordersTotalSpent!)),
              style: t.caption.copyWith(color: c.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _status(BuildContext context, OrderStatus s) {
    final c = context.colors;
    final l = context.l10n;
    final (String label, Color fg, Color bg) = switch (s) {
      OrderStatus.processing => (l.profile_order_processing, c.statusPending, c.statusPendingContainer),
      OrderStatus.shipped => (l.profile_order_shipped, c.textInfo, c.infoContainer),
      OrderStatus.delivered => (l.profile_order_delivered, c.statusResolved, c.statusResolvedContainer),
      OrderStatus.cancelled => (l.profile_order_cancelled, c.statusClosed, c.statusClosedContainer),
    };
    return StatusBadge(label: label, foreground: fg, background: bg, compact: true);
  }
}
