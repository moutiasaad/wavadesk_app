import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../../auth/application/auth_session.dart';
import '../domain/conversation_filters.dart';

/// Segment, quick chip and advanced filters (Inbox spec §2, §4.2–4.4, §7),
/// persisted per user in SharedPreferences.
final conversationFiltersProvider = NotifierProvider<ConversationFiltersController, InboxQuery>(
  ConversationFiltersController.new,
);

class ConversationFiltersController extends Notifier<InboxQuery> {
  String get _key {
    final user = ref.read(authRepositoryProvider).session?.user['id'] ?? 'me';
    return 'inbox_filters_$user';
  }

  @override
  InboxQuery build() {
    // Other screens (login, dashboard) move the segment through the inbox
    // controller; follow them.
    ref.listen(inboxProvider.select((s) => s.segment), (_, next) {
      if (next != state.segment) state = state.copyWith(segment: next, chip: QuickChip.all);
    });

    final fallback = InboxQuery(segment: ref.read(settingsProvider).lastSegment);
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return fallback;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return InboxQuery(
        // The login flow sets "لي" explicitly; the inbox controller is the
        // source of truth for the segment.
        segment: ref.read(inboxProvider).segment,
        chip: QuickChip.values.firstWhere((c) => c.name == j['chip'], orElse: () => QuickChip.all),
        advanced: AdvancedFilters.fromJson(Map<String, dynamic>.from(j['advanced'] as Map? ?? const {})),
      );
    } catch (_) {
      return fallback;
    }
  }

  void _persist() {
    ref
        .read(sharedPrefsProvider)
        .setString(
          _key,
          jsonEncode({'segment': state.segment.name, 'chip': state.chip.name, 'advanced': state.advanced.toJson()}),
        );
  }

  void setSegment(InboxSegment segment) {
    if (segment == state.segment) return;
    Analytics.log('inbox_segment_change', {'from': state.segment.name, 'to': segment.name});
    state = state.copyWith(segment: segment);
    ref.read(inboxProvider.notifier).setSegment(segment); // persists lastSegment
    _persist();
  }

  void setChip(QuickChip chip) {
    if (chip == state.chip) return;
    state = state.copyWith(chip: chip);
    Analytics.log('inbox_filter_change', {'chip': chip.name, 'advanced': state.advanced.activeCount});
    _persist();
  }

  void setAdvanced(AdvancedFilters advanced) {
    state = state.copyWith(advanced: advanced);
    Analytics.log('inbox_filter_change', {
      'chip': state.chip.name,
      'advanced': {
        'channels': advanced.channels.length,
        'priorities': advanced.priorities.length,
        'teams': advanced.teamIds.length,
        'tags': advanced.tags.length,
        'date': advanced.date.name,
        'sort': advanced.sort.name,
      },
    });
    _persist();
  }

  /// "مسح الكل" / "مسح الفلاتر": advanced filters back to defaults and the
  /// chip to "الكل".
  void clearAll() {
    state = state.copyWith(chip: QuickChip.all, advanced: AdvancedFilters.empty);
    _persist();
  }

  /// Deep links: `/conversations?segment=…&filter=…` (§2).
  void applyDeepLink({String? segment, String? filter}) {
    final s = InboxSegment.values.where((v) => v.name == segment).firstOrNull;
    final c = QuickChip.values.where((v) => v.name == filter).firstOrNull;
    if (s != null) setSegment(s);
    if (c != null) setChip(c);
  }
}
