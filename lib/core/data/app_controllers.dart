import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_agent/application/ai_agent_controller.dart';
import '../../features/ai_agent/domain/ai_agent_config.dart' show AiMode;
import '../../features/auth/application/auth_session.dart';
import '../api/wd_api.dart' show useRealApi;
import '../api/wd_api_provider.dart';
import '../../features/channels/whatsapp/application/quick_replies_controller.dart';
import '../../features/channels/whatsapp/application/whatsapp_channel_controller.dart';
import '../../features/notifications/application/unread_badge_controller.dart';
import '../models/models.dart';
import 'mock_data.dart';
import 'settings_controller.dart';
import 'team_directory.dart';

/// Signed-in agent, with the presence chosen on the Account tab.
final currentAgentProvider = Provider<Agent>((ref) {
  final presence = ref.watch(settingsProvider.select((s) => s.presence));
  if (useRealApi) {
    // The user returned by /mobile/v1/auth/login (id is the opaque usr_…).
    ref.watch(authProvider);
    final u = ref.read(authRepositoryProvider).session?.user ?? const <String, dynamic>{};
    if (u.isNotEmpty) {
      return Agent(
        id: '${u['id'] ?? ''}',
        name: '${u['name'] ?? ''}',
        email: '${u['email'] ?? ''}',
        role: AgentRole.values.asNameMap()[u['role']] ?? AgentRole.agent,
        presence: presence,
        avatarUrl: u['avatar_url'] as String?,
      );
    }
  }
  return MockData.me.copyWith(presence: presence);
});

/// Real API: the workspace members from `GET team` (empty until loaded,
/// never sample people). Sample mode: the fake JSON.
final colleaguesProvider = Provider<List<Agent>>(
  (ref) => useRealApi ? ref.watch(teamDirectoryProvider).colleagues : MockData.colleagues,
);
final teamsProvider = Provider<List<Team>>(
  (ref) => useRealApi ? ref.watch(teamDirectoryProvider).teams : MockData.teams,
);
/// Saved replies for the composer's `/` panel, from the Quick replies
/// screen's controller (WhatsApp spec §5.4) so edits show up at once.
final quickRepliesProvider = Provider<List<QuickReply>>(
  (ref) => [for (final r in ref.watch(quickRepliesControllerProvider).items) r.toComposer()],
);
/// Real API: approved WhatsApp templates (`GET whatsapp/templates`; empty
/// until loaded or when the number has none). Sample mode: the fake JSON.
final templatesProvider = Provider<List<MessageTemplate>>(
  (ref) => useRealApi ? (ref.watch(_remoteTemplatesProvider).valueOrNull ?? const []) : MockData.templates,
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
final dashboardProvider = Provider<DashboardStats>((ref) => MockData.dashboard);

// ---- Knowledge base -----------------------------------------------------------

final knowledgeProvider = NotifierProvider<KnowledgeController, List<KnowledgeEntry>>(KnowledgeController.new);

class KnowledgeController extends Notifier<List<KnowledgeEntry>> {
  @override
  List<KnowledgeEntry> build() => MockData.knowledge();

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
    if (!useRealApi) return const AiAgentSettings(repliesUsed: 618, repliesQuota: 1000);
    // Real API: the workspace AI settings from the AI agent screen's
    // controller (`GET ai-agent`), never the sample numbers.
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
    if (!useRealApi) return MockData.whatsapp;
    // Real API: unknown until the channel controller answers (it mirrors its
    // status here through [sync]); never the sample "connected" number.
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

  /// Simulates scanning the QR code on the phone.
  Future<void> connect() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    state = WhatsAppConnection(
      connected: true,
      phoneNumber: '+966 55 000 1122',
      displayName: 'متجر وافا',
      connectedSince: DateTime.now(),
    );
  }
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
