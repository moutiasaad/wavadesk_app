import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../conversations/application/relative_time_ticker.dart';
import '../application/ai_suggestion_controller.dart';
import '../application/chat_controller.dart';
import '../application/claim_controller.dart';
import '../application/presence_controller.dart';
import '../application/composer_controller.dart';
import '../application/messages_controller.dart';
import '../data/chat_api.dart' show chatDetailLoadProvider, ChatDetailLoad, chatRemoteSyncProvider;
import '../data/chat_socket.dart';
import '../domain/conversation_detail.dart';
import '../domain/ownership.dart';
import '../domain/assignee.dart';
import 'sheets/ai_rewrite/ai_rewrite_sheet.dart';
import 'sheets/assign/assign_sheet.dart';
import 'widgets/ai_suggestion_card.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/chat_banner.dart';
import 'widgets/claim_bar.dart';
import 'widgets/taken_bar.dart';
import 'widgets/composer/message_composer.dart';
import 'widgets/context_strip.dart';
import 'widgets/jump_to_latest_button.dart';
import 'widgets/message_list.dart';
import 'widgets/read_only_bar.dart';
import 'widgets/sheets/conversation_actions_sheet.dart';
import '../../customer/presentation/customer_profile_panel.dart';
import '../../customer/presentation/customer_profile_sheet.dart';
import '../../search/application/in_conversation_search_controller.dart';
import '../../search/application/search_history_controller.dart';
import '../../search/presentation/in_conversation_search_bar.dart';
import 'widgets/sheets/templates_sheet.dart';

/// المحادثة — implements `03 Chat Screen.md` on the Design System.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.readOnly = false,
    this.messageId,
    this.composeNote = false,
    this.autoClaim = false,
    this.source,
    this.searchQuery,
  });

  final String conversationId;

  /// `?claim=1` — auto-claim after 400ms if still unassigned (Claim spec §2).
  final bool autoClaim;

  /// `?source=push|handoff|deeplink` — pulse + analytics.
  final String? source;

  /// Past conversation opened from the customer profile.
  final bool readOnly;

  /// `?messageId=` — scroll to and highlight.
  final String? messageId;

  /// `&compose=note` — open the composer in note mode.
  final bool composeNote;

  /// `?search=` — open in in-conversation search mode (Search spec §11).
  final String? searchQuery;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  static const _tabletBreakpoint = 840.0;

  /// True while *my* claim request is in flight, so the ownership change it
  /// causes isn't mistaken for a colleague's real-time action.
  bool _myClaim = false;

  /// Delays the AI card 150ms after the composer appears (Claim spec §6).
  bool _aiHold = false;

  /// Conflict: shake the read-only bar once (Claim spec §10).
  int _shake = 0;
  bool _claimViewLogged = false;

  final _scroll = ScrollController();
  final _composerFocus = FocusNode();
  StreamSubscription<ChatSocketEvent>? _socketSub;

  bool _showJump = false;
  int _newCount = 0;
  double _cardHeight = 0;

  /// Note composer opened from a read-only bar (colleague / AI cases).
  bool _noteComposer = false;

  /// Tablet: profile side panel visible.
  bool _panel = true;

  String get _id => widget.conversationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.readOnly) ref.read(presenceControllerProvider(_id).notifier).join();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inbox = ref.read(inboxProvider.notifier);
      final c = inbox.byId(_id);
      Analytics.log('chat_open', {
        'source': widget.readOnly ? 'profile' : (widget.messageId != null ? 'search' : 'inbox'),
        'ownership': c?.ownership.name,
        'unread': c?.unreadCount ?? 0,
        'channel': c?.channel.name,
        'has_ai_suggestion': c?.aiSuggestion != null,
      });
      if (!widget.readOnly) inbox.startViewing(_id);
      // Feeds "آخر من تواصلت معهم" on the search zero state (Search spec §5).
      ref.read(searchHistoryProvider.notifier).recordOpened(_id);
      if (widget.messageId != null) ref.read(messagesControllerProvider(_id).notifier).highlight(widget.messageId!);
      if (widget.composeNote) _openNoteComposer();
      if (widget.searchQuery != null) _openSearch(widget.searchQuery!);
      _socketSub = ref.read(chatSocketProvider).events(_id).listen(_onSocket);
    });
  }

  /// Presence: leave on background, re-join on resume (Claim spec §9).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.readOnly) return;
    final p = ref.read(presenceControllerProvider(_id).notifier);
    if (state == AppLifecycleState.resumed) {
      p.join();
    } else if (state == AppLifecycleState.paused) {
      p.leave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketSub?.cancel();
    _scroll.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  // ---- Real-time ------------------------------------------------------------------

  void _onSocket(ChatSocketEvent e) {
    if (!mounted) return;
    final l = context.l10n;
    switch (e) {
      case ChatTakenFromMe(:final byName):
        // Unclaimed → colleague is handled by _onDetailChanged (Claim §6).
        final mineBefore = _lastSlot == BottomSlot.composer;
        // Draft is kept by the composer controller.
        if (mineBefore) AppSnackbar.show(context, message: l.chatscreen_taken_from_me(byName));
      case ChatInboundMessage() || ChatRefreshNeeded():
        break;
    }
  }

  BottomSlot? _lastSlot;

  String _lastActor(ConversationDetail d) {
    for (var i = d.conversation.messages.length - 1; i >= 0; i--) {
      final e = d.conversation.messages[i].systemEvent;
      if (e != null) return e.actorName ?? '';
    }
    return d.assignee?.name ?? '';
  }

  void _announce(String message) => SemanticsService.announce(message, Directionality.of(context));

  /// Ownership changed while viewing the claim state, caused by someone else
  /// (Claim spec §6: claimed by colleague / assigned to me / resolved).
  void _onDetailChanged(ConversationDetail? prev, ConversationDetail? next) {
    if (prev == null || next == null || widget.readOnly) return;
    if (_myClaim || ref.read(claimControllerProvider(_id)).claiming) return;
    final before = BottomSlotResolver.resolve(prev, readOnlyRoute: false);
    final after = BottomSlotResolver.resolve(next, readOnlyRoute: false);
    if (before != BottomSlot.claim || after == before) return;
    final l = context.l10n;
    final actor = _lastActor(next);
    switch (after) {
      case BottomSlot.composer:
        // No auto-focus: avoid a surprise keyboard.
        final m = l.claim_assigned_to_you(actor);
        AppSnackbar.show(context, message: m, kind: SnackKind.success);
        _announce(m);
        _holdAi();
      case BottomSlot.readOnlyColleague:
        final m = l.claim_taken_live(next.assignee?.name ?? actor);
        AppSnackbar.show(context, message: m);
        _announce(m);
      case BottomSlot.readOnlyResolved:
        final m = l.claim_resolved_live(actor);
        AppSnackbar.show(context, message: m);
        _announce(m);
      default:
        break;
    }
  }

  void _holdAi() {
    setState(() => _aiHold = true);
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _aiHold = false);
    });
  }

  // ---- Actions ---------------------------------------------------------------------

  ChatActions get _actions => ref.read(chatActionsProvider(_id));

  void _openNoteComposer() {
    ref.read(composerControllerProvider(_id).notifier).enterNoteMode();
    setState(() => _noteComposer = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _composerFocus.requestFocus());
  }

  /// Result of a ClaimBar attempt (Claim spec §6, §7.1).
  void _onClaimResult(ClaimState r) {
    if (!mounted) return;
    final l = context.l10n;
    switch (r.phase) {
      case ClaimPhase.success:
        // Bar cross-fades into the composer; the keyboard is NOT opened
        // (Claim v2 §4.4). The AI card follows 150ms later.
        _holdAi();
      case ClaimPhase.conflict:
        final m = l.claim_conflict(r.claimedBy ?? '');
        setState(() => _shake++);
        AppSnackbar.show(context, message: m, kind: SnackKind.error);
        _announce(m);
      case ClaimPhase.forbidden:
        AppSnackbar.show(
          context,
          message: r.max != null ? l.claim_capacity_reached : l.claim_forbidden,
          kind: SnackKind.error,
        );
      case ClaimPhase.network:
        AppSnackbar.show(
          context,
          message: l.claim_network_error,
          kind: SnackKind.error,
          actionLabel: l.claim_retry,
          onAction: () => _retryClaim(),
        );
      case ClaimPhase.locked:
        AppSnackbar.show(context, message: l.chatscreen_action_failed, kind: SnackKind.error);
      case ClaimPhase.idle || ClaimPhase.claiming:
        break;
    }
    _myClaim = false;
  }

  Future<void> _retryClaim() async {
    _myClaim = true;
    final r = await ref.read(claimControllerProvider(_id).notifier).claim(source: 'chat');
    _onClaimResult(r);
  }

  void _openProfile() {
    final d = ref.read(chatDetailProvider(_id));
    if (d == null || !d.hasProfile) return;
    if (_wide(context)) {
      setState(() => _panel = !_panel);
      return;
    }
    showCustomerProfileSheet(context, contactId: d.contact.id, conversationId: _id, onNote: _openNoteComposer);
  }

  /// "بحث في المحادثة": the app bar becomes a search bar, composer hidden.
  void _openSearch([String query = '']) {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(inConversationSearchProvider(_id).notifier).open(query);
  }

  void _openActions() => showConversationActionsSheet(
    context,
    ref,
    conversationId: _id,
    onSearch: _openSearch,
    // Unclaimed / colleague / AI: notes via ⋮ (Claim spec §5.3).
    onAddNote: () {
      final d = ref.read(chatDetailProvider(_id));
      final slot = d == null ? null : BottomSlotResolver.resolve(d, readOnlyRoute: widget.readOnly);
      return slot != null && slot.allowsNotes ? _openNoteComposer : null;
    }(),
    onResolved: _onResolved,
  );

  /// Header ✕: same close card + resolve as the ⋮ sheet.
  void _closeConversation() =>
      closeConversationFlow(context, ref, conversationId: _id, onResolved: _onResolved);

  void _onResolved(Future<void> Function() undo) {
    // Pop to the inbox, then "تم حلّ المحادثة" + تراجع (5s).
    final l = context.l10n;
    AppSnackbar.show(
      context,
      message: l.chat_resolved_toast,
      kind: SnackKind.success,
      actionLabel: l.chat_undo,
      onAction: () {
        Analytics.log('inbox_undo', {'action': 'resolve'});
        undo();
      },
    );
    if (context.canPop()) context.pop();
  }

  void _requestTransfer(ConversationDetail d) {
    final l = context.l10n;
    _actions.requestTransfer(l.chatscreen_transfer_note(d.assignee?.name ?? ''));
    AppSnackbar.show(context, message: l.taken_request_sent(d.assignee?.name ?? ''), kind: SnackKind.success);
  }

  Future<void> _adminTakeOver(ConversationDetail d) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.chatscreen_takeover_title,
      body: l.chatscreen_takeover_body(d.assignee?.name ?? ''),
      confirmLabel: l.chatscreen_takeover_confirm,
      icon: AppIcons.mine,
      severity: DialogSeverity.warning,
    );
    if (ok) _actions.takeOverFromColleague();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: AppMotion.slow, curve: AppMotion.standard);
  }

  bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

  // ---- Bottom slot -------------------------------------------------------------------

  Widget _bottomSlot(ConversationDetail d, BottomSlot slot, DateTime now) {
    if (_noteComposer && slot.allowsNotes || slot == BottomSlot.composer) {
      return MessageComposer(
        key: const ValueKey('composer'),
        detail: d,
        focusNode: _composerFocus,
        onOpenTemplates: () => showTemplatesSheet(context, ref, conversationId: _id),
        onOpenRewrite: (source, {required entry, required note}) =>
            showAiRewriteSheet(context, ref, detail: d, source: source, entry: entry, note: note),
        // Note composer opened from a non-composer state closes after sending.
        onSent: slot == BottomSlot.composer
            ? null
            : () {
                ref.read(composerControllerProvider(_id).notifier).hideModeToggle();
                setState(() => _noteComposer = false);
              },
      );
    }
    return switch (slot) {
      BottomSlot.claim || BottomSlot.readOnlyTeam => ClaimBar(
        key: ValueKey('claim-${slot.name}'),
        detail: d,
        canClaim: slot == BottomSlot.claim,
        onResult: _onClaimResult,
        pulse: widget.source == 'push',
        autoClaim: widget.autoClaim,
        source: widget.source == 'push' ? 'push' : 'chat',
        onAssign: () => showAssignSheet(context, ref, conversationIds: [_id], source: AssignSource.claimBar),
        onNote: _openNoteComposer,
      ),
      BottomSlot.readOnlyColleague => TakenBar(
        key: const ValueKey('taken'),
        detail: d,
        onRequest: () => _requestTransfer(d),
        onReassign: d.permissions.canAssign && (d.permissions.isAdmin || ref.read(currentAgentProvider).canManage)
            ? () => showAssignSheet(context, ref, conversationIds: [_id], source: AssignSource.claimBar)
            : null,
        onNote: _openNoteComposer,
      ),
      _ => ReadOnlyBar(
        key: ValueKey('ro-${slot.name}'),
        slot: slot,
        detail: d,
        onNote: slot.allowsNotes ? _openNoteComposer : null,
        onAdminTakeOver: slot == BottomSlot.readOnlyColleague && d.permissions.isAdmin ? () => _adminTakeOver(d) : null,
        onAction: switch (slot) {
          BottomSlot.readOnlyColleague => () => _requestTransfer(d),
          BottomSlot.readOnlyResolved => _actions.reopen,
          BottomSlot.readOnlyAi => _actions.takeOver,
          BottomSlot.readOnlyBlocked => () => _actions.setBlocked(false),
          _ => null,
        },
      ),
    };
  }

  // ---- Build --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final d = ref.watch(chatDetailProvider(_id));

    // Leave note mode once the note composer switches back to "رد".
    ref.listen<ConversationDetail?>(chatDetailProvider(_id), (prev, next) => _onDetailChanged(prev, next));
    ref.listen(composerControllerProvider(_id).select((s) => s.mode), (_, mode) {
      if (mode == ComposerMode.reply && _noteComposer) setState(() => _noteComposer = false);
    });

    if (d == null) {
      // API mode: the conversation may simply not be loaded yet (deep link,
      // notification, search) — skeleton until the server has answered.
      final load = ref.watch(chatDetailLoadProvider.select((m) => m[_id]));
      final Widget body;
      if (load == ChatDetailLoad.error) {
        body = EmptyState(
          icon: AppIcons.offline,
          title: l.chatscreen_load_failed,
          actionLabel: l.common_retry,
          onAction: () {
            ref.read(chatDetailLoadProvider.notifier).put(_id, ChatDetailLoad.loading);
            ref.invalidate(chatRemoteSyncProvider(_id));
          },
        );
      } else if (load != ChatDetailLoad.notFound) {
        body = Align(alignment: Alignment.bottomCenter, child: AppSkeleton.chat());
      } else {
        body = EmptyState(icon: AppIcons.inbox, title: l.chatscreen_not_found);
      }
      return Scaffold(appBar: AppBarStandard(title: l.tab_conversations), body: body);
    }

    final now = ref.watch(inboxClockProvider);
    final network = ref.watch(inboxProvider.select((s) => s.network));
    final slot = BottomSlotResolver.resolve(d, readOnlyRoute: widget.readOnly);
    final composerActive = slot == BottomSlot.composer && !d.windowClosed(now);
    final aiView = ref.watch(aiSuggestionControllerProvider(_id).select((s) => s.view));
    final showAiCard = composerActive && aiView != AiCardView.hidden && !_aiHold;
    _lastSlot = slot;
    if (slot == BottomSlot.claim && !_claimViewLogged) {
      _claimViewLogged = true;
      final handoff = d.conversation.messages.where((m) => m.systemEvent?.kind == SystemEventKind.aiHandoff).lastOrNull;
      Analytics.log('claim_view', {
        'source': widget.autoClaim ? 'deeplink' : (widget.source ?? (handoff != null ? 'handoff' : 'inbox')),
        'viewers_count': d.conversation.viewers.length,
        'wait_seconds': d.waitingSince == null ? 0 : DateTime.now().difference(d.waitingSince!).inSeconds,
        'handoff_reason': ?handoff?.systemEvent?.value,
      });
      // Claim v2 §8: say why there is no composer.
      final msg = l.claim_a11y_unassigned;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _announce(msg);
      });
    }
    final wide = _wide(context);
    final searching = ref.watch(inConversationSearchProvider(_id).select((s) => s.active));

    final chat = Column(
      children: [
        if (searching)
          InConversationSearchBar(conversationId: _id)
        else
          ChatAppBar(
            detail: d,
            onProfile: _openProfile,
            onMore: _openActions,
            onClose: d.isOpen && d.permissions.canResolve && !widget.readOnly ? _closeConversation : null,
          ),
        ContextStrip(detail: d),
        if (!widget.readOnly)
          ChatBanner(
            detail: d,
            network: network,
            now: now,
            onChooseTemplate: () => showTemplatesSheet(context, ref, conversationId: _id),
            onReconnect: () => context.push(Routes.whatsapp),
            onUnsnooze: _actions.unsnooze,
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: MessageList(
                  conversationId: _id,
                  controller: _scroll,
                  readOnly: widget.readOnly,
                  // Before claiming: read, copy, info, transcribe only (Claim §5.3).
                  preClaim: slot == BottomSlot.claim || slot == BottomSlot.readOnlyTeam,
                  // The AI card overlaps the list; keep the last bubble clear.
                  bottomPadding: (showAiCard && !searching ? _cardHeight : 0) + AppSpacing.sm,
                  onReply: (m) {
                    ref.read(composerControllerProvider(_id).notifier).setReply(m);
                    _composerFocus.requestFocus();
                  },
                  onJumpStateChanged: (show, count) {
                    if (show != _showJump || count != _newCount) {
                      setState(() {
                        _showJump = show;
                        _newCount = count;
                      });
                    }
                  },
                ),
              ),
              if (showAiCard && !searching)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: _MeasureSize(
                    onChange: (s) {
                      if (s.height != _cardHeight) setState(() => _cardHeight = s.height);
                    },
                    child: AiSuggestionCard(
                      conversationId: _id,
                      onEdit: (text) {
                        ref.read(composerControllerProvider(_id).notifier).fillFromAi(text);
                        _composerFocus.requestFocus();
                      },
                      onAddAnswer: (question) => context.push(Routes.newKnowledgeFrom(question: question)),
                    ),
                  ),
                ),
              PositionedDirectional(
                end: 14,
                bottom: (showAiCard ? _cardHeight : 0) + AppSpacing.md,
                child: AnimatedScale(
                  scale: _showJump ? 1 : 0,
                  duration: AppMotion.normal,
                  curve: AppMotion.standard,
                  child: JumpToLatestButton(
                    newCount: _newCount,
                    onTap: () {
                      _scrollToBottom();
                      setState(() => _newCount = 0);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Exactly one of composer / claim bar / read-only bar (§3).
        AnimatedSize(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: AppMotion.normal,
            // Composer hidden while searching (§11).
            child: searching
                ? const SizedBox(key: ValueKey('search'), width: double.infinity)
                : _ShakeOnce(trigger: _shake, child: _bottomSlot(d, slot, now)),
          ),
        ),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor: c.chatBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: wide && _panel && d.hasProfile
            ? Row(
                children: [
                  Expanded(child: chat),
                  VerticalDivider(width: 1, color: c.divider),
                  // Tablet ≥ 840dp: 360dp profile side panel (Profile spec §2).
                  CustomerProfilePanel(
                    contactId: d.contact.id,
                    conversationId: _id,
                    onNote: _openNoteComposer,
                    onClose: () => setState(() => _panel = false),
                  ),
                ],
              )
            : chat,
      ),
    );
    // Back closes search mode first.
    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && searching) ref.read(inConversationSearchProvider(_id).notifier).close();
      },
      child: scaffold,
    );
  }
}

/// Reports its child's size after layout (AI card height → list padding).
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureSize renderObject) => renderObject.onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      final s = size;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange(s));
    }
  }
}

/// Horizontal shake, 2× ±4dp over 250ms, replayed when [trigger] changes
/// (claim conflict, Claim spec §10). Skipped under reduce-motion.
class _ShakeOnce extends StatefulWidget {
  const _ShakeOnce({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_ShakeOnce> createState() => _ShakeOnceState();
}

class _ShakeOnceState extends State<_ShakeOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  @override
  void didUpdateWidget(_ShakeOnce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !AppMotion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final v = _c.value;
      final dx = v == 0 || v == 1 ? 0.0 : math.sin(v * 2 * 2 * math.pi) * 4 * (1 - v);
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
  );
}
