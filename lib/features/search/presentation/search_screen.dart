import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../chat/application/composer_controller.dart';
import '../../conversations/application/conversation_filters_controller.dart';
import '../../conversations/domain/conversation_filters.dart';
import '../application/search_controller.dart';
import '../application/search_history_controller.dart';
import '../domain/search_query.dart';
import 'widgets/best_match_card.dart';
import 'widgets/contact_search_tile.dart';
import 'widgets/conversation_search_tile.dart';
import 'widgets/did_you_mean.dart';
import 'widgets/kb_search_tile.dart';
import 'widgets/message_search_tile.dart';
import 'widgets/search_filters_sheet.dart';
import 'widgets/search_header.dart';
import 'widgets/search_scope_chips.dart';
import 'widgets/search_section.dart';
import 'widgets/search_skeleton.dart';
import 'widgets/search_suggestions.dart';
import 'widgets/search_zero_state.dart';

/// `/search` — one field for customers, messages, conversations and KB
/// (Search spec, frame 08).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.args = const SearchArgs()});

  final SearchArgs args;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _field;
  final _focus = FocusNode(debugLabel: 'search');

  SearchController get _ctrl => ref.read(searchControllerProvider(widget.args).notifier);
  SearchState get _s => ref.read(searchControllerProvider(widget.args));

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchControllerProvider(widget.args)).text;
    _field = TextEditingController(text: initial)..selection = TextSelection.collapsed(offset: initial.length);
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setText(String q, {bool submit = true}) {
    _field.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    _ctrl.setText(q);
    if (submit) _ctrl.submit();
  }

  void _remember() => ref.read(searchHistoryProvider.notifier).add(_s.text);

  void _tap(String type, int position) {
    _remember();
    Analytics.log('search_result_tap', {'type': type, 'position': position, 'scope': _s.scope.name});
  }

  /// "6 نتائج: عميل واحد، 4 رسائل، مقال واحد" (§12).
  void _announce(SearchResults r) {
    final l = context.l10n;
    final t = r.totals;
    final parts = [
      if (t.contacts > 0) l.search_announce_contacts(t.contacts),
      if (t.messages > 0) l.search_announce_messages(t.messages),
      if (t.conversations > 0) l.search_announce_conversations(t.conversations),
      if (t.kb > 0) l.search_announce_kb(t.kb),
    ].join('، ');
    final msg = r.isEmpty ? l.search_no_results(r.query.text.trim()) : l.search_results_announce(t.all, parts);
    SemanticsService.announce(msg, Directionality.of(context));
  }

  // ---- Actions -----------------------------------------------------------------------

  void _openContact(ContactHit h, int i, {String type = 'contact'}) {
    _tap(type, i);
    context.push(Routes.contact(h.id));
  }

  Future<void> _contactMenu(ContactHit h) async {
    final l = context.l10n;
    final picked = await AppBottomSheet.show<int>(
      context,
      title: h.name,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetActionRow(icon: AppIcons.conversation, label: l.search_last_chat, onTap: () => Navigator.pop(ctx, 0)),
          SheetActionRow(icon: AppIcons.compose, label: l.search_new_chat, onTap: () => Navigator.pop(ctx, 1)),
          if ((h.phone ?? '').isNotEmpty)
            SheetActionRow(icon: AppIcons.copy, label: l.search_copy_number, onTap: () => Navigator.pop(ctx, 2)),
        ],
      ),
    );
    if (!mounted || picked == null) return;
    switch (picked) {
      case 0:
        if (h.lastConversationId == null) {
          AppSnackbar.show(context, message: l.search_no_chat_yet);
        } else {
          _tap('contact', 0);
          context.push(Routes.chat(h.lastConversationId!));
        }
      case 1:
        // No outbound "new conversation" flow in the app yet → the profile,
        // where the channel actions live.
        _openContact(h, 0);
      case 2:
        await Clipboard.setData(ClipboardData(text: h.phone!));
        if (mounted) AppSnackbar.show(context, message: l.search_copied, kind: SnackKind.success);
    }
  }

  void _openMessage(MessageHit h, int i) {
    _tap('message', i);
    context.push(Routes.chat(h.conversationId, messageId: h.id, readOnly: h.conversationClosed));
  }

  void _openInConversation(MessageHit h) {
    _remember();
    context.push(Routes.chat(h.conversationId, searchQuery: _s.text.trim()));
  }

  void _openKb(KbHit h, int i) {
    _tap('kb', i);
    context.push(Routes.editKnowledge(h.id));
  }

  void _insertKb(KbHit h) {
    final conv = widget.args.fromConversationId;
    if (conv == null) return;
    _tap('kb', 0);
    ref.read(composerControllerProvider(conv).notifier).insertKbAnswer(h.answer.isEmpty ? h.title : h.answer);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.search_inserted)));
  }

  void _openTeammate(Agent a) {
    _tap('teammate', 0);
    final me = ref.read(currentAgentProvider).id;
    final filters = ref.read(conversationFiltersProvider.notifier);
    filters.setAdvanced(
      ref
          .read(conversationFiltersProvider)
          .advanced
          .copyWith(
            assignee: a.id == me ? AssigneeFilter.me : AssigneeFilter.colleague,
            colleagueId: a.id == me ? null : a.id,
          ),
    );
    context.go(Routes.conversations);
  }

  void _suggestion(SearchSuggestion s) {
    switch (s) {
      case SearchSuggestion.unread:
        context.go('${Routes.conversations}?filter=${QuickChip.unread.name}');
      case SearchSuggestion.awaiting:
        context.go('${Routes.conversations}?filter=${QuickChip.awaiting.name}');
      case SearchSuggestion.vip:
        _setText('VIP');
      case SearchSuggestion.ordersToday:
        _ctrl.setFilters(_s.filters.copyWith(date: SearchDateRange.today));
        _ctrl.setScope(SearchScope.conversations);
        _setText('#');
    }
  }

  Future<void> _openFilters() async {
    final picked = await showSearchFiltersSheet(context, initial: _s.filters, count: _ctrl.countFor);
    if (picked != null) _ctrl.setFilters(picked);
  }

  List<Customer> _recentContacts() {
    final inbox = ref.read(inboxProvider.notifier);
    final opened = ref.watch(searchHistoryProvider.select((h) => h.openedConversations));
    final seen = <String>{};
    final out = <Customer>[];
    for (final id in opened) {
      final c = inbox.byId(id)?.customer;
      if (c != null && seen.add(c.id)) out.add(c);
    }
    if (out.length < 5) {
      // Fresh install: fall back to the most recent conversations.
      final convs = [...ref.read(inboxProvider).conversations]
        ..sort(
          (a, b) => (b.messages.lastOrNull?.sentAt ?? DateTime(2000)).compareTo(
            a.messages.lastOrNull?.sentAt ?? DateTime(2000),
          ),
        );
      for (final c in convs) {
        if (out.length >= 10) break;
        if (seen.add(c.customer.id)) out.add(c.customer);
      }
    }
    return out.take(10).toList();
  }

  // ---- Build -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(searchControllerProvider(widget.args));
    final history = ref.watch(searchHistoryProvider);
    ref.listen(searchControllerProvider(widget.args).select((x) => x.results), (prev, next) {
      if (next != null && !identical(prev, next)) _announce(next);
    });

    final results = s.results;
    final loading = s.status == SearchStatus.loading || s.refining;

    Widget body;
    if (s.status == SearchStatus.idle) {
      body = SearchZeroState(
        recents: history.recents,
        recentsLoaded: history.loaded,
        recentContacts: _recentContacts(),
        onRecentTap: (q) {
          Analytics.log('search_recent_tap');
          _setText(q);
        },
        onRecentRemove: (q) => ref.read(searchHistoryProvider.notifier).remove(q),
        onRecentsClear: () {
          final before = ref.read(searchHistoryProvider.notifier).clear();
          AppSnackbar.undo(
            context,
            message: l.search_recents_cleared,
            onUndo: () => ref.read(searchHistoryProvider.notifier).restore(before),
          );
        },
        onSuggestion: _suggestion,
        onContact: (cu) {
          Analytics.log('search_result_tap', {'type': 'recent_contact', 'position': 0, 'scope': s.scope.name});
          context.push(Routes.contact(cu.id));
        },
      );
    } else if (s.status == SearchStatus.loading && results == null) {
      body = const SearchSkeleton();
    } else if (s.status == SearchStatus.error) {
      body = Center(
        child: EmptyState(
          icon: AppIcons.offline,
          title: l.search_error,
          actionLabel: l.search_retry,
          onAction: _ctrl.retry,
        ),
      );
    } else if (s.status == SearchStatus.empty && results != null) {
      body = _empty(context, s, results);
    } else {
      body = AnimatedOpacity(
        opacity: s.refining ? 0.5 : 1,
        duration: AppMotion.fast,
        child: AnimatedSwitcher(
          duration: AppMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 120),
          child: KeyedSubtree(
            key: ValueKey('${s.scope.name}|${results?.query.cacheKey}'),
            child: _results(context, s, results!),
          ),
        ),
      );
    }

    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tablet ? 720 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchHeader(
                  controller: _field,
                  focusNode: _focus,
                  onChanged: _ctrl.setText,
                  onSubmitted: (_) {
                    _remember();
                    _ctrl.submit();
                    _focus.unfocus();
                  },
                  onCancel: () => context.pop(),
                ),
                SearchScopeChips(
                  scope: s.scope,
                  totals: results?.totals,
                  showCounts: results != null && !loading,
                  filterCount: s.filters.activeCount,
                  showConversations: (results?.totals.conversations ?? 0) > 0,
                  onScope: _ctrl.setScope,
                  onFilters: _openFilters,
                ),
                if (!s.filters.isEmpty) _activeFilters(context, s.filters),
                // Thin 2dp bar after 1.5s (§8 slow).
                SizedBox(
                  height: 2,
                  child: s.slow || s.loadingScope
                      ? LinearProgressIndicator(minHeight: 2, color: c.primary, backgroundColor: Colors.transparent)
                      : null,
                ),
                if (s.offline) _offlineBanner(context),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _offlineBanner(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 32,
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.xs, AppSpacing.screenH, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: c.warningContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: [
          AppIcon(AppIcons.offline, size: AppIconSize.sm, color: c.textWarning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.search_offline,
              style: context.text.caption.copyWith(color: c.textWarning),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Dismissible tonal chips + "مسح الكل" (Inbox spec §4.4 pattern).
  Widget _activeFilters(BuildContext context, SearchFilters f) {
    final l = context.l10n;
    final chips = <(String, SearchFilters)>[
      for (final ch in f.channels) (ch.label(l), f.copyWith(channels: {...f.channels}..remove(ch))),
      if (f.date != SearchDateRange.any)
        (
          switch (f.date) {
            SearchDateRange.today => l.search_date_today,
            SearchDateRange.days7 => l.search_date_7,
            SearchDateRange.days30 => l.search_date_30,
            _ => l.search_date_custom,
          },
          f.copyWith(date: SearchDateRange.any),
        ),
      if (f.sender != SearchSender.all)
        (
          switch (f.sender) {
            SearchSender.contact => l.search_sender_contact,
            SearchSender.me => l.search_sender_me,
            SearchSender.colleagues => l.search_sender_colleagues,
            SearchSender.ai => l.search_sender_ai,
            _ => l.search_sender_notes,
          },
          f.copyWith(sender: SearchSender.all),
        ),
      if (f.status != SearchStatusFilter.all)
        (
          f.status == SearchStatusFilter.open ? l.search_status_open : l.search_status_resolved,
          f.copyWith(status: SearchStatusFilter.all),
        ),
      if (f.assignee != SearchAssigneeFilter.all)
        (
          f.assignee == SearchAssigneeFilter.me ? l.search_assignee_me : l.search_assignee_colleague,
          f.copyWith(assignee: SearchAssigneeFilter.all, clearColleague: true),
        ),
      for (final x in f.contains)
        (
          switch (x) {
            SearchContains.attachments => l.search_filter_attachments,
            SearchContains.images => l.search_filter_images,
            SearchContains.voice => l.search_filter_voice,
          },
          f.copyWith(contains: {...f.contains}..remove(x)),
        ),
    ];
    return AppChipRow(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      children: [
        for (final (label, next) in chips)
          AppFilterChip(label: label, selected: false, onTap: null, onDeleted: () => _ctrl.setFilters(next)),
        AppButton(
          label: l.search_clear_filters,
          variant: AppButtonVariant.text,
          size: AppButtonSize.small,
          onPressed: _ctrl.clearFilters,
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, SearchState s, SearchResults r) {
    final l = context.l10n;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (r.suggestion != null) _didYouMean(r.suggestion!),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.x5l),
          child: EmptyState(
            icon: AppIcons.filterX,
            title: l.search_no_results(s.text.trim()),
            body: l.search_no_results_body,
            actionLabel: s.filters.isEmpty ? null : l.search_clear_filters,
            onAction: s.filters.isEmpty ? null : _ctrl.clearFilters,
          ),
        ),
        if (s.scope != SearchScope.all)
          Center(
            child: AppButton(
              label: l.search_in_all,
              variant: AppButtonVariant.text,
              onPressed: () => _ctrl.setScope(SearchScope.all),
            ),
          ),
      ],
    );
  }

  Widget _didYouMean(String suggestion) => DidYouMean(
    suggestion: suggestion,
    onTap: () {
      Analytics.log('search_did_you_mean_tap');
      _setText(suggestion);
    },
  );

  /// §6.6: phone/email → contacts first; order → conversations first.
  List<SearchScope> _order(SearchIntent i) => switch (i) {
    SearchIntent.phone ||
    SearchIntent.email => const [SearchScope.contacts, SearchScope.conversations, SearchScope.messages, SearchScope.kb],
    SearchIntent.order => const [SearchScope.conversations, SearchScope.messages, SearchScope.contacts, SearchScope.kb],
    _ => const [SearchScope.contacts, SearchScope.messages, SearchScope.kb, SearchScope.conversations],
  };

  Widget _results(BuildContext context, SearchState s, SearchResults r) {
    final l = context.l10n;
    final q = r.normalized;
    final local = r.local;

    List<Widget> contacts() => [
      for (final (i, h) in r.contacts.indexed)
        ContactSearchTile(hit: h, query: q, onTap: () => _openContact(h, i), onMore: () => _contactMenu(h)),
    ];
    List<Widget> messages() => [
      for (final (i, h) in r.messages.indexed)
        MessageSearchTile(hit: h, onTap: () => _openMessage(h, i), onMore: () => _openInConversation(h)),
    ];
    List<Widget> kb() => [
      for (final (i, h) in r.kb.indexed)
        KbSearchTile(
          hit: h,
          query: q,
          onTap: () => _openKb(h, i),
          onInsert: widget.args.fromConversationId == null ? null : () => _insertKb(h),
        ),
    ];
    List<Widget> conversations() => [
      for (final (i, h) in r.conversations.indexed)
        ConversationSearchTile(
          hit: h,
          onTap: () {
            _tap('conversation', i);
            context.push(Routes.chat(h.summary.id));
          },
        ),
    ];

    final children = <Widget>[];
    if (r.suggestion != null) children.add(_didYouMean(r.suggestion!));

    // "@" → teammates.
    if (r.agents.isNotEmpty) {
      children.add(
        SearchSection(
          title: l.search_section_teammates,
          children: [
            for (final h in r.agents)
              ListTile(
                leading: AppAvatar(
                  name: h.agent.name,
                  id: h.agent.id,
                  presence: h.agent.presence,
                  size: AppAvatarSize.md,
                ),
                title: Text(h.agent.name, style: context.text.listTitle),
                onTap: () => _openTeammate(h.agent),
              ),
          ],
        ),
      );
    }

    if (s.scope == SearchScope.all) {
      final best = r.bestMatch == null ? null : r.contacts.where((c) => c.id == r.bestMatch!.contactId).firstOrNull;
      if (best != null) {
        children.add(
          BestMatchCard(
            hit: best,
            onProfile: () => _openContact(best, 0, type: 'best_match'),
            onOpenChat: best.lastConversationId == null
                ? null
                : () {
                    _tap('best_match', 0);
                    context.push(Routes.chat(best.lastConversationId!));
                  },
            onCall: (best.phone ?? '').isEmpty ? null : () => launchUrl(Uri(scheme: 'tel', path: best.phone)),
          ),
        );
      }
      for (final scope in _order(r.intent)) {
        final (String title, int total, List<Widget> items) = switch (scope) {
          SearchScope.contacts => (
            l.search_section_contacts,
            r.totals.contacts,
            best == null ? contacts() : <Widget>[],
          ),
          SearchScope.messages => (l.search_section_messages, r.totals.messages, messages()),
          SearchScope.kb => (l.search_section_kb, r.totals.kb, kb()),
          SearchScope.conversations => (l.search_section_conversations, r.totals.conversations, conversations()),
          SearchScope.all => ('', 0, <Widget>[]),
        };
        if (items.isEmpty) continue;
        children.add(
          SearchSection(
            title: title,
            total: total,
            local: local,
            onSeeAll: total > items.length ? () => _ctrl.setScope(scope) : null,
            children: items,
          ),
        );
      }
    } else {
      final items = switch (s.scope) {
        SearchScope.contacts => contacts(),
        SearchScope.messages => messages(),
        SearchScope.kb => kb(),
        SearchScope.conversations => conversations(),
        SearchScope.all => <Widget>[],
      };
      children.add(
        SearchSection(
          title: switch (s.scope) {
            SearchScope.contacts => l.search_section_contacts,
            SearchScope.messages => l.search_section_messages,
            SearchScope.kb => l.search_section_kb,
            _ => l.search_section_conversations,
          },
          local: local,
          children: items,
        ),
      );
      if (s.loadingMore) {
        children.add(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: AppSpinner(size: 20)),
          ),
        );
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Next page at 80% (§6.7).
        if (n.metrics.maxScrollExtent > 0 && n.metrics.pixels >= n.metrics.maxScrollExtent * 0.8) _ctrl.loadMore();
        return false;
      },
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
        children: children,
      ),
    );
  }
}
