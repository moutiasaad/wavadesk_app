import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import 'recent_contacts_row.dart';
import 'recent_searches.dart';
import 'search_suggestions.dart';

/// Empty query (§5): recents · suggestions · recent contacts; first time →
/// suggestions + tip only.
class SearchZeroState extends StatelessWidget {
  const SearchZeroState({
    super.key,
    required this.recents,
    this.recentsLoaded = true,
    required this.recentContacts,
    required this.onRecentTap,
    required this.onRecentRemove,
    required this.onRecentsClear,
    required this.onSuggestion,
    required this.onContact,
  });

  final List<String> recents;
  /// Recents are read from secure storage; until then show neither the
  /// first-time tip nor an empty recents block (no flash).
  final bool recentsLoaded;
  final List<Customer> recentContacts;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRecentRemove;
  final VoidCallback onRecentsClear;
  final ValueChanged<SearchSuggestion> onSuggestion;
  final ValueChanged<Customer> onContact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = recents.isEmpty;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (!first)
          RecentSearches(items: recents, onTap: onRecentTap, onRemove: onRecentRemove, onClear: onRecentsClear),
        SearchSuggestions(onTap: onSuggestion),
        if (!recentsLoaded)
          const SizedBox.shrink()
        else if (first)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, 0),
            child: Text(context.l10n.search_tip, style: context.text.bodySmall.copyWith(color: c.textTertiary)),
          )
        else
          RecentContactsRow(customers: recentContacts, onTap: onContact),
      ],
    );
  }
}
