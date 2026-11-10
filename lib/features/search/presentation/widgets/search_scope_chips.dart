import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/search_query.dart';

/// الكل · 6 | العملاء · 1 | الرسائل · 4 | المعرفة · 1 | فلاتر ▾ (§4.2).
class SearchScopeChips extends StatelessWidget {
  const SearchScopeChips({
    super.key,
    required this.scope,
    required this.totals,
    required this.showCounts,
    required this.filterCount,
    required this.onScope,
    required this.onFilters,
    this.showConversations = false,
  });

  final SearchScope scope;
  final SearchTotals? totals;

  /// Hidden while loading.
  final bool showCounts;
  final int filterCount;
  final ValueChanged<SearchScope> onScope;
  final VoidCallback onFilters;

  /// Optional scope — shown when there are conversation hits.
  final bool showConversations;

  static String _cap(int n) => n > 99 ? '99+' : '$n';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final scopes = [
      (SearchScope.all, l.search_scope_all),
      (SearchScope.contacts, l.search_scope_contacts),
      (SearchScope.messages, l.search_scope_messages),
      (SearchScope.kb, l.search_scope_kb),
      if (showConversations || scope == SearchScope.conversations)
        (SearchScope.conversations, l.search_scope_conversations),
    ];
    return AppChipRow(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.screenH,
        end: AppSpacing.screenH,
        top: AppSpacing.md - 8,
        bottom: 0,
      ),
      children: [
        for (final (s, label) in scopes)
          () {
            final n = totals?.of(s);
            final chip = AppFilterChip(
              label: showCounts && n != null ? '$label · ${_cap(n)}' : label,
              selected: s == scope,
              onTap: () => onScope(s),
            );
            // Zero-result chips stay tappable, label in textTertiary.
            return showCounts && n == 0 && s != scope
                ? DefaultTextStyle.merge(
                    style: TextStyle(color: c.textTertiary),
                    child: Opacity(opacity: 0.7, child: chip),
                  )
                : chip;
          }(),
        AppFilterChip(
          label: filterCount > 0 ? l.search_filters_n(filterCount) : l.search_filters,
          selected: filterCount > 0,
          trailingIcon: AppIcons.chevronDown,
          onTap: onFilters,
        ),
      ],
    );
  }
}
