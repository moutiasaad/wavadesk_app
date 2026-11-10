import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

enum SearchSuggestion { unread, awaiting, vip, ordersToday }

/// "اقتراحات" quick filters (§5): غير مقروءة · بانتظار الرد · وسم: VIP ·
/// طلبات اليوم.
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({super.key, required this.onTap});

  final ValueChanged<SearchSuggestion> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 22, AppSpacing.screenH, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.search_suggestions,
              style: context.text.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: -8,
            children: [
              for (final (s, label) in [
                (SearchSuggestion.unread, l.search_sugg_unread),
                (SearchSuggestion.awaiting, l.search_sugg_awaiting),
                (SearchSuggestion.vip, l.search_sugg_vip),
                (SearchSuggestion.ordersToday, l.search_sugg_orders_today),
              ])
                AppFilterChip(label: label, selected: false, onTap: () => onTap(s)),
            ],
          ),
        ],
      ),
    );
  }
}
