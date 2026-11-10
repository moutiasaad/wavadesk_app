import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_agent/application/ai_agent_controller.dart';
import '../../features/ai_agent/domain/ai_agent_config.dart' show AiMode;
import '../../features/auth/application/auth_session.dart';
import '../api/wd_api_provider.dart';
import '../../features/channels/whatsapp/application/quick_replies_controller.dart';
import '../../features/channels/whatsapp/application/whatsapp_channel_controller.dart';
import '../../features/knowledge/application/knowledge_controller.dart';
import '../../features/notifications/application/unread_badge_controller.dart';
import '../models/models.dart';
import 'settings_controller.dart';
import 'team_directory.dart';

/// Signed-in agent, with the presence chosen on the Account tab.
/// Signed-in agent: the user returned by /mobile/v1/auth/login (id is the
/// opaque usr_…), with the presence chosen on the Account tab. Empty fields
/// while signed out.
final currentAgentProvider = Provider<Agent>((ref) {
  final presence = ref.watch(settingsProvider.select((s) => s.presence));
  ref.watch(authProvider);
  final u = ref.read(authRepositoryProvider).session?.user ?? const <String, dynamic>{};
  return Agent(
    id: '${u['id'] ?? ''}',
    name: '${u['name'] ?? ''}',
    email: '${u['email'] ?? ''}',
    role: AgentRole.values.asNameMap()[u['role']] ?? AgentRole.agent,
    presence: presence,
    avatarUrl: u['avatar_url'] as String?,
  );
});

/// The workspace members from `GET team` (empty until loaded).
final colleaguesProvider = Provider<List<Agent>>((ref) => ref.watch(teamDirectoryProvider).colleagues);
final teamsProvider = Provider<List<Team>>((ref) => ref.watch(teamDirectoryProvider).teams);
/// Saved replies for the composer's `/` panel, from the Quick replies
/// screen's controller (WhatsApp spec §5.4) so edits show up at once.
final quickRepliesProvider = Provider<List<QuickReply>>(
  (ref) => [for (final r in ref.watch(quickRepliesControllerProvider).items) r.toComposer()],
);
/// Approved WhatsApp templates (`GET whatsapp/templates`; empty until loaded
/// or when the number has none).
final templatesProvider = Provider<List<MessageTemplate>>(
  (ref) => ref.watch(_remoteTemplatesProvider).valueOrNull ?? const [],
);

final _remoteTemplatesProvider = FutureProvider<List<MessageTemplate>>((ref) async {
  ref.watch(authProvider);
  final api = ref.watch(wdApiProvider);
  if (api == null) return const [];
  final r = await api.get('whatsapp/templates');
  return [
    for (final m in r.list)
      MessageTemplate(
        id: '${m['id']}',
        name: '${m['display_name'] ?? m['name'] ?? ''}',
        body: '${m['body'] ?? ''}',
        category: '${m['category'] ?? ''}',
      ),
  ];
});

// ---- Knowledge base -----------------------------------------------------------

/// Legacy flat view of the knowledge base for older callers (chat AI card,
/// search): mirrors the Knowledge tab's loaded rows (`GET kb`).
final knowledgeProvider = NotifierProvider<KnowledgeController, List<KnowledgeEntry>>(KnowledgeController.new);

class KnowledgeController extends Notifier<List<KnowledgeEntry>> {
  @override
  List<KnowledgeEntry> build() => [
        for (final e in ref.watch(knowledgeControllerProvider.select((s) => s.items)))
          KnowledgeEntry(
            id: e.id,
            type: KnowledgeType.faq,
            title: e.title,
            body: '',
            updatedAt: e.updatedAt,
            enabled: e.enabled,
            usageCount: e.usage30d,
          ),
      ];

  KnowledgeEntry? byId(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  void save(KnowledgeEntry entry) {
    final i = state.indexWhere((e) => e.id == entry.id);
    state = i < 0 ? [entry, ...state] : [for (final e in state) e.id == entry.id ? entry : e];
  }

  void toggle(String id) => state = [for (final e in state) e.id == id ? e.copyWith(enabled: !e.enabled) : e];

  /// Returns the removed entry and its index so the caller can offer Undo.
  (KnowledgeEntry, int)? delete(String id) {
    final i = state.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final removed = state[i];
    state = [...state]..removeAt(i);
    return (removed, i);
  }

  void restore(KnowledgeEntry entry, int index) {
    final list = [...state];
    list.insert(index.clamp(0, list.length), entry);
    state = list;
  }
}

// ---- Notifications ------------------------------------------------------------

/// Bell dot (Inbox app bar, Dashboard): unread notifications excluding muted
/// types, kept fresh by the app-wide poller (Notifications spec §8).
final unreadNotificationsProvider = Provider<int>((ref) => ref.watch(notificationsUnreadCountProvider));

// ---- AI agent -------------------------------------------------------------------

final aiSettingsProvider = NotifierProvider<AiSettingsController, AiAgentSettings>(AiSettingsController.new);

class AiSettingsController extends Notifier<AiAgentSettings> {
  @override
  AiAgentSettings build() {
    // The workspace AI settings from the AI agent screen's controller
    // (`GET ai-agent`).
    final cfg = ref.watch(aiAgentControllerProvider.select((s) => s.config));
    if (cfg == null) return const AiAgentSettings(repliesQuota: 0);
    return AiAgentSettings(
      enabled: cfg.enabled && cfg.planAllowsAi,
      autoReply: cfg.mode != AiMode.suggest,
      tone: cfg.tone.name,
      repliesUsed: cfg.usage.used,
      repliesQuota: cfg.usage.limit ?? 0,
    );
  }

  void update(AiAgentSettings Function(AiAgentSettings s) fn) => state = fn(state);
}

// ---- WhatsApp connection -------------------------------------------------------

final whatsappProvider = NotifierProvider<WhatsAppController, WhatsAppConnection>(WhatsAppController.new);

class WhatsAppController extends Notifier<WhatsAppConnection> {
  @override
  WhatsAppConnection build() {
    // Unknown until the channel controller answers (it mirrors its status
    // here through [sync]).
    ref.watch(authProvider);
    scheduleMicrotask(() {
      final ch = ref.read(whatsAppChannelControllerProvider);
      if (ch.channel != null) ref.read(whatsAppChannelControllerProvider.notifier).load(silent: true);
    });
    return const WhatsAppConnection(connected: false, loaded: false);
  }

  void disconnect() => state = const WhatsAppConnection(connected: false);

  /// Mirror of the WhatsApp channel screen's status (WhatsApp spec §8).
  void sync(WhatsAppConnection c) => state = c;
}

// ---- Drafts ----------------------------------------------------------------------

/// Unsent composer text per conversation; the inbox previews it as
/// "مسودة: …" (Inbox spec §4.5.2).
final draftsProvider = NotifierProvider<DraftsController, Map<String, String>>(DraftsController.new);

class DraftsController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void set(String conversationId, String text) {
    final trimmed = text.trim();
    if ((state[conversationId] ?? '') == trimmed) return;
    final next = Map<String, String>.of(state);
    trimmed.isEmpty ? next.remove(conversationId) : next[conversationId] = trimmed;
    state = next;
  }
}
