import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/api/wd_api.dart';
import '../../auth/application/auth_session.dart';
import '../data/chat_api.dart';
import '../domain/conversation_detail.dart';

/// Header/meta of one conversation (Chat spec §8 `GET /conversations/{id}`).
final chatDetailProvider = Provider.family<ConversationDetail?, String>((ref, id) {
  // Real API: fetch the header, mirror it into the inbox, poll while open.
  ref.watch(chatRemoteSyncProvider(id));
  final c = ref.watch(conversationProvider(id));
  if (c == null) return null;
  final remote = ref.watch(remoteChatPermissionsProvider.select((m) => m[id]));
  if (remote != null) {
    final auth = ref.read(authRepositoryProvider);
    final ai = ref.watch(aiSettingsProvider);
    return ConversationDetail(
      conversation: c,
      meId: '${auth.session?.user['id'] ?? ''}',
      aiEnabledInWorkspace: ai.enabled,
      // The server sets ai_handling only while the AI is answering on its own,
      // so an AI-handled row is the auto mode (Claim spec §2 → ReadOnlyBar(ai)).
      aiAutoMode: true,
      permissions: remote.permissions,
    );
  }
  final me = ref.watch(currentAgentProvider);
  final ai = ref.watch(aiSettingsProvider);
  final mine = c.ownership == Ownership.mine;
  return ConversationDetail(
    conversation: c,
    meId: me.id,
    aiEnabledInWorkspace: ai.enabled,
    aiAutoMode: ai.enabled && ai.autoReply,
    permissions: ChatPermissions(
      canReply: mine,
      canAssign: true,
      canResolve: mine || me.isAdmin,
      canDeleteMessages: mine || me.isAdmin,
      isAdmin: me.isAdmin,
    ),
  );
});

enum ClaimOutcome { ok, conflict, failed }

class ClaimResult {
  const ClaimResult(this.outcome, {this.claimedBy});
  final ClaimOutcome outcome;
  final String? claimedBy;
}

final chatActionsProvider = Provider.family<ChatActions, String>((ref, id) => ChatActions(ref, id));

/// Ownership & conversation actions (Chat spec §4.9, §4.10, §6). Applied
/// optimistically to the local state; with a backend configured the same
/// action is also POSTed to `/conversations/{id}/{action}`.
class ChatActions {
  ChatActions(this._ref, this.id);

  final Ref _ref;
  final String id;

  InboxController get _inbox => _ref.read(inboxProvider.notifier);
  Conversation? get _c => _inbox.byId(id);

  ChatApi? get _api => _ref.read(chatApiProvider);

  /// Fire-and-forget server call; the answer (new detail) replaces the
  /// optimistic local state. On error the server copy is reloaded.
  void _remote(String action, [Map<String, Object?> body = const {}]) {
    final api = _api;
    if (api == null) return;
    unawaited(
      api
          .action(id, action, body, WdApi.newIdempotencyKey())
          .then(_apply)
          .catchError((Object _) => api.detail(id).then(_apply).catchError((Object _) {})),
    );
  }

  void _apply(RemoteConversation r) {
    _ref.read(inboxProvider.notifier).upsertFromApi(r.conversation);
    _ref.read(remoteChatPermissionsProvider.notifier).put(r);
  }

  String get _meId => '${_ref.read(authRepositoryProvider).session?.user['id'] ?? ''}';

  int _waitSeconds() {
    final w = _c?.waitingSince;
    return w == null ? 0 : DateTime.now().difference(w).inSeconds;
  }

  /// Claim with the 409 race check (§4.9).
  Future<ClaimResult> claim() async {
    final wait = _waitSeconds();
    final api = _api;
    if (api != null) {
      try {
        _apply(await api.action(id, 'claim', const {}, WdApi.newIdempotencyKey()));
        Analytics.log('chat_claim', {'wait_seconds': wait, 'result': 'ok'});
        return const ClaimResult(ClaimOutcome.ok);
      } on ChatApiException catch (e) {
        if (e.statusCode == 409) {
          Analytics.log('chat_claim', {'wait_seconds': wait, 'result': 'conflict'});
          return ClaimResult(ClaimOutcome.conflict, claimedBy: e.claimedBy);
        }
        return const ClaimResult(ClaimOutcome.failed);
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 500)); // visible loading state
    final by = _inbox.claimChecked(id);
    Analytics.log('chat_claim', {'wait_seconds': wait, 'result': by == null ? 'ok' : 'conflict'});
    return by == null ? const ClaimResult(ClaimOutcome.ok) : ClaimResult(ClaimOutcome.conflict, claimedBy: by);
  }

  void assignTo(Agent agent, {String? note}) {
    Analytics.log('chat_assign', {'target_type': 'agent'});
    _inbox.assign(id, agent);
    if (note != null && note.trim().isNotEmpty) _inbox.addNote(id, note.trim(), mentions: [agent.name]);
    _remote('assign', {
      'assignee': {'type': 'agent', 'id': agent.id},
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  /// Team → the least-busy available colleague in it (§6.1).
  void assignToTeam(Team team, {String? note}) {
    Analytics.log('chat_assign', {'target_type': 'team'});
    final pool = [..._ref.read(colleaguesProvider)]
      ..sort((a, b) {
        final p = a.presence.index.compareTo(b.presence.index);
        return p != 0 ? p : a.openConversations.compareTo(b.openConversations);
      });
    if (pool.isEmpty) return;
    _inbox.assign(id, pool.first);
    if (note != null && note.trim().isNotEmpty) _inbox.addNote(id, note.trim(), mentions: [pool.first.name]);
    _remote('assign', {
      'assignee': {'type': 'team', 'id': team.id},
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  void unassign() {
    _inbox.unassign(id);
    _remote('unassign');
  }

  /// Returns an undo callback (§6 resolve flow).
  Future<void> Function() resolve() {
    Analytics.log('chat_resolve');
    final before = _inbox.resolve(id);
    _remote('resolve');
    return () async {
      if (before != null) _inbox.restore(before);
      _remote('reopen');
    };
  }

  void reopen() {
    Analytics.log('chat_reopen');
    _inbox.reopen(id);
    _remote('reopen');
  }

  Future<void> Function() snooze(DateTime until) {
    Analytics.log('chat_snooze');
    final before = _inbox.snooze(id, until);
    _remote('snooze', {'until': until.toUtc().toIso8601String()});
    return () async {
      if (before != null) _inbox.restore(before);
      _remote('unsnooze');
    };
  }

  void unsnooze() {
    _inbox.unsnooze(id);
    _remote('unsnooze');
  }

  void setPriority(Priority p) {
    _inbox.setPriority(id, p);
    _remote('priority', {'priority': priorityToServer(p)});
  }

  void toggleTag(String tag) {
    _inbox.toggleTag(id, tag);
    _remote('tags', {'tags': _c?.tags ?? const <String>[], 'mode': 'set'});
  }

  void setAiPaused(bool paused) {
    _inbox.setAiPaused(id, paused);
    _remote('ai-toggle', {'enabled': !paused});
  }

  /// "تولَّ المحادثة": claim + pause AI for this chat.
  void takeOver() {
    _inbox.takeOver(id);
    final api = _api;
    if (api == null) return;
    // Claim first, then pause the AI on the conversation we now hold.
    unawaited(
      api
          .action(id, 'claim', const {}, WdApi.newIdempotencyKey())
          .then(_apply)
          .then((_) => _remote('ai-toggle', {'enabled': false}))
          .catchError((Object _) => api.detail(id).then(_apply).catchError((Object _) {})),
    );
  }

  /// Admin "استلم بدلًا عنه".
  void takeOverFromColleague() {
    _inbox.claim(id);
    // No forced claim in v1: an admin re-assigns the conversation to self.
    _remote('assign', {
      'assignee': {'type': 'agent', 'id': _meId},
    });
  }

  void markUnread() {
    _inbox.markUnread(id);
    _remote('unread');
  }

  void setBlocked(bool blocked) {
    _inbox.setBlocked(id, blocked);
    if (blocked) {
      _remote('block-contact');
    } else {
      final contactId = _c?.customer.id;
      final api = _api;
      if (api != null && contactId != null && contactId.startsWith('ct_')) {
        unawaited(api.unblockContact(contactId).then((_) => api.detail(id)).then(_apply).catchError((Object _) {}));
      }
    }
  }

  void requestTransfer(String noteText) => _inbox.requestTransfer(id, noteText);

  void addCustomerNote(String text) => _inbox.addCustomerNote(id, text);

  /// Plain-text transcript for "تصدير المحادثة".
  String exportText({required String Function(Message m) describe}) {
    final c = _c;
    if (c == null) return '';
    final b = StringBuffer('${c.customer.name} — ${c.customer.phone ?? c.customer.email ?? ''}\n\n');
    for (final m in c.messages) {
      b.writeln('[${m.sentAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')}] ${describe(m)}');
    }
    return b.toString();
  }
}
