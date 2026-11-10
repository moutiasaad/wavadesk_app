import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/customer_profile_controller.dart';
import '../domain/contact.dart';
import 'dialogs/block_contact_dialog.dart';
import 'dialogs/erase_contact_dialog.dart';
import 'sheets/add_note_sheet.dart';
import 'sheets/call_action_sheet.dart';
import 'sheets/merge_contact_sheet.dart';
import 'sheets/tag_editor_sheet.dart';
import 'widgets/profile_ai_summary_card.dart';
import 'widgets/profile_channels_section.dart';
import 'widgets/profile_danger_zone.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/profile_notes_section.dart';
import 'widgets/profile_orders_section.dart';
import 'widgets/profile_previous_conversations.dart';
import 'widgets/profile_quick_actions.dart';
import 'widgets/profile_skeleton.dart';
import 'widgets/profile_stats_strip.dart';

/// Customer profile content (Profile spec §4–§6), shared by the sheet, the
/// full screen and the tablet side panel.
class CustomerProfileView extends ConsumerStatefulWidget {
  const CustomerProfileView({
    super.key,
    required this.contactId,
    this.conversationId,
    this.controller,
    this.container = 'sheet',
    this.onHeroVisibilityChanged,
  });

  final String contactId;

  /// Conversation the profile was opened from (excluded from history; tags
  /// added here log a system event in it).
  final String? conversationId;
  final ScrollController? controller;

  /// sheet | screen | panel (analytics + behaviour on erase/merge).
  final String container;

  /// False once the hero scrolled out (> 120dp) — drives pinned headers.
  final ValueChanged<bool>? onHeroVisibilityChanged;

  @override
  ConsumerState<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends ConsumerState<CustomerProfileView> {
  late final ScrollController _scroll = widget.controller ?? ScrollController();
  final _previousKey = GlobalKey();
  final _ordersKey = GlobalKey();
  bool _heroVisible = true;
  bool _logged = false;

  String get _id => widget.contactId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    if (widget.controller == null) _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final visible = _scroll.offset <= 120;
    if (visible != _heroVisible) {
      _heroVisible = visible;
      widget.onHeroVisibilityChanged?.call(visible);
    }
  }

  void _logOpen(Contact c) {
    if (_logged) return;
    _logged = true;
    Analytics.log('profile_open', {
      'container': widget.container,
      'source': widget.conversationId != null ? 'chat' : 'direct',
      'has_notes': c.notes.isNotEmpty,
      'prev_conversations': (c.conversationsCount - (widget.conversationId == null ? 0 : 1)).clamp(0, 9999),
    });
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: AppMotion.slow, curve: AppMotion.standard, alignment: 0.05);
  }

  // ---- Actions -----------------------------------------------------------------------

  /// WhatsApp (§5.2): in a WhatsApp chat just close the sheet (composer is
  /// underneath); otherwise open the contact's WhatsApp conversation or
  /// start one from the first approved template.
  void _whatsapp(Contact c) {
    final inbox = ref.read(inboxProvider.notifier);
    final current = widget.conversationId == null ? null : inbox.byId(widget.conversationId!);
    if (current?.channel == Channel.whatsapp) {
      Navigator.of(context).maybePop();
      return;
    }
    final existing = ref
        .read(inboxProvider)
        .conversations
        .where((x) => x.customer.id == c.id && x.channel == Channel.whatsapp && !x.isClosed)
        .firstOrNull;
    if (existing != null) {
      context.push(Routes.chat(existing.id));
      return;
    }
    final templates = ref.read(templatesProvider);
    final phone = c.phone;
    if (phone == null || templates.isEmpty) return;
    final id = inbox.startConversation(name: c.name ?? '', phone: phone, template: templates.first);
    context.push(Routes.chat(id));
  }

  Future<void> _toggleBlock(Contact c) async {
    if (c.isBlocked) {
      await ref.read(customerProfileControllerProvider(_id).notifier).unblock();
    } else {
      await showBlockContactDialog(context, ref, contactId: _id);
    }
  }

  // ---- Build -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(customerProfileControllerProvider(_id));
    final ctrl = ref.read(customerProfileControllerProvider(_id).notifier);

    // Erased or merged away → close (the panel stays; its owner decides).
    ref.listen(customerProfileControllerProvider(_id).select((x) => x.gone), (_, gone) {
      if (gone && widget.container != 'panel' && mounted) Navigator.of(context).maybePop();
    });

    final contact = s.contact;
    if (contact != null) _logOpen(contact);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    Widget content;
    if (contact == null && s.error) {
      content = Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.only(top: AppSpacing.x4l),
        child: EmptyState(
          icon: AppIcons.wifiOff,
          title: l.profile_load_error,
          actionLabel: l.profile_retry,
          actionVariant: AppButtonVariant.primary,
          onAction: ctrl.retry,
        ),
      );
    } else if (contact == null) {
      content = const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.only(top: AppSpacing.sm),
        child: ProfileSkeleton(),
      );
    } else {
      content = KeyedSubtree(key: const ValueKey('data'), child: _sections(context, contact, s));
    }

    return ListView(
      controller: _scroll,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, 0, 18, AppSpacing.xxl + bottom),
      children: [
        if (s.offline)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(color: c.warningContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Row(
              children: [
                Icon(AppIcons.wifiOff, size: 14, color: c.textWarning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l.profile_offline, style: t.caption.copyWith(color: c.textWarning)),
                ),
              ],
            ),
          ),
        AnimatedSwitcher(duration: AppMotion.fast, child: content),
      ],
    );
  }

  Widget _sections(BuildContext context, Contact ct, ProfileState s) {
    final p = ct.permissions;
    final offline = s.offline;
    final ctrl = ref.read(customerProfileControllerProvider(_id).notifier);
    final canEdit = p.canEdit && !offline;
    VoidCallback? edit() => canEdit ? () => context.push(Routes.editContact(_id)) : null;
    // Over the chat the sheet stays compact like the design: no pencil, no
    // empty placeholders, no single-channel list, no danger zone (all on the
    // full page).
    final sheet = widget.container == 'sheet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero
        ProfileHero(
          contact: ct,
          onEdit: sheet ? null : edit(),
          onAddDetails: edit(),
          onAddTag: canEdit
              ? () => showTagEditorSheet(context, ref, contactId: _id, conversationId: widget.conversationId)
              : null,
        ),
        // 2. Quick actions
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 14),
          child: ProfileQuickActions(
            contact: ct,
            offline: offline,
            onCall: () => showCallActionSheet(context, ref, contactId: _id, conversationId: widget.conversationId),
            onWhatsapp: () => _whatsapp(ct),
            onNote: () => showAddNoteSheet(context, ref, contactId: _id),
            onBlockToggle: () => _toggleBlock(ct),
          ),
        ),
        // 3. Stats
        ProfileStatsStrip(
          contact: ct,
          onConversationsTap: () => _scrollTo(_previousKey),
          onOrdersTap: () => _scrollTo(_ordersKey),
        ),
        // 4. AI summary (only when available)
        if (ct.aiSummary != null)
          ProfileAiSummaryCard(
            summary: ct.aiSummary!,
            loading: s.summaryLoading,
            onRegenerate: offline ? null : ctrl.regenerateSummary,
          ),
        // 5. Team notes
        ProfileNotesSection(contact: ct, offline: offline, hideWhenEmpty: sheet),
        // 6. Contact info
        ProfileInfoSection(
          contact: ct,
          filledOnly: sheet,
          onEdit: edit(),
          onCall: () => showCallActionSheet(context, ref, contactId: _id, conversationId: widget.conversationId),
        ),
        // 7. Linked channels
        if (!sheet || ct.channels.length > 1)
          ProfileChannelsSection(
            contact: ct,
            onChannelTap: (ch) {
              ref
                  .read(pastConversationsProvider((contactId: _id, excludeId: widget.conversationId)).notifier)
                  .setChannel(ch);
              _scrollTo(_previousKey);
            },
            onUnlink: p.canMerge && !offline
                ? (_) => AppSnackbar.show(context, message: context.l10n.profile_unlinked, kind: SnackKind.success)
                : null,
            onMerge: p.canMerge && !offline ? () => showMergeContactSheet(context, ref, contactId: _id) : null,
          ),
        // 8. Orders (only with an integration)
        if (ct.orders != null)
          KeyedSubtree(
            key: _ordersKey,
            child: ProfileOrdersSection(contact: ct),
          ),
        // 9. Previous conversations
        KeyedSubtree(
          key: _previousKey,
          child: ProfilePreviousConversations(contact: ct, conversationId: widget.conversationId),
        ),
        // 10. Danger zone
        if (!sheet)
          ProfileDangerZone(
            contact: ct,
            onBlock: offline ? null : () => showBlockContactDialog(context, ref, contactId: _id),
            onUnblock: offline ? null : ctrl.unblock,
            onErase: p.canDelete && !offline ? () => showEraseContactDialog(context, ref, contactId: _id) : null,
          ),
      ],
    );
  }
}
