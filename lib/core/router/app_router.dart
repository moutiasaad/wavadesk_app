import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/simple_slide_transition.dart';

import '../../features/account/edit_profile_screen.dart';
import '../../features/account/security_screen.dart';
import '../../features/account/account_screen.dart';
import '../../features/account/channels_screen.dart';
import '../../features/account/help_screen.dart';
import '../../features/account/notification_settings_screen.dart';
import '../../features/account/subscription_screen.dart';
import '../../features/account/team_screen.dart';
import '../../features/ai_agent/presentation/ai_agent_screen.dart';
import '../../features/ai_agent/presentation/audit/ai_audit_screen.dart';
import '../../features/ai_agent/presentation/handoff/handoff_rules_screen.dart';
import '../../features/ai_agent/presentation/hours/working_hours_screen.dart';
import '../../features/ai_agent/presentation/sheets/custom_instructions_screen.dart';
import '../../features/ai_agent/presentation/sheets/team_styles_screen.dart';
import '../../features/ai_agent/presentation/test/ai_test_chat_screen.dart';
import '../../features/auth/application/auth_session.dart';
import '../../features/channels/whatsapp/data/quick_replies_api.dart' show QuickReplyScope;
import '../../features/channels/whatsapp/presentation/close_titles/close_titles_screen.dart';
import '../../features/channels/whatsapp/presentation/connect/wa_connect_screen.dart';
import '../../features/channels/whatsapp/presentation/editors/wa_away_editor_screen.dart';
import '../../features/channels/whatsapp/presentation/editors/wa_welcome_editor_screen.dart';
import '../../features/channels/whatsapp/presentation/quick_replies/quick_replies_screen.dart';
import '../../features/channels/whatsapp/presentation/quick_replies/quick_reply_editor_screen.dart';
import '../../features/channels/whatsapp/presentation/whatsapp_channel_screen.dart';
import '../../features/channels/whatsapp/presentation/widgets/wa_numbers_group.dart';
import '../../features/channels/whatsapp/presentation/widgets/wa_templates_section.dart';
import '../../features/auth/presentation/auth_placeholder_screens.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/customer/presentation/customer_profile_screen.dart';
import '../../features/customer/presentation/edit_contact_screen.dart';
import '../../features/conversations/presentation/conversations_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/knowledge/presentation/editor/kb_answer_editor_screen.dart';
import '../../features/knowledge/presentation/detail/kb_qa_detail_screen.dart';
import '../../features/knowledge/presentation/files/kb_document_review_screen.dart';
import '../../features/knowledge/presentation/files/kb_file_detail_screen.dart';
import '../../features/knowledge/presentation/knowledge_screen.dart';
import '../../features/knowledge/presentation/links/kb_link_detail_screen.dart';
import '../../features/knowledge/presentation/unanswered/kb_unanswered_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/search/application/search_controller.dart';
import '../../features/search/domain/search_query.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/shell/home_shell.dart';

/// Route paths. Pushed screens live on the root navigator so the tab bar
/// hides under them.
abstract final class Routes {
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const loginTwoFactor = '/login/2fa';
  static const loginWorkspace = '/login/workspace';

  /// Reachable without a session.
  static const public = {login, forgotPassword, loginTwoFactor, loginWorkspace};
  static const conversations = '/conversations';
  static const dashboard = '/dashboard';
  static const knowledge = '/knowledge';
  static const account = '/account';
  static const search = '/search';
  static const notifications = '/notifications';
  /// Add / edit answer modal (Add Answer spec §2).
  static const knowledgeNew = '/knowledge/new';
  /// Knowledge Base sub-screens (Knowledge Base spec §2).
  static const knowledgeUnanswered = '/knowledge/unanswered';
  static String knowledgeDetail(String id) => '/knowledge/${Uri.encodeComponent(id)}';
  static String knowledgeFile(String id) => '/knowledge/files/${Uri.encodeComponent(id)}';
  /// Review the answers the AI drafted from an uploaded document.
  static String knowledgeFileReview(String id) => '/knowledge/files/${Uri.encodeComponent(id)}/review';
  static String knowledgeLink(String id) => '/knowledge/links/${Uri.encodeComponent(id)}';
  /// AI agent settings (AI Agent spec §2) and its sub-screens.
  static const aiAgent = '/settings/ai-agent';
  static const aiAgentHours = '/settings/ai-agent/hours';
  static const aiAgentHandoff = '/settings/ai-agent/handoff';
  static const aiAgentTest = '/settings/ai-agent/test';
  static const aiAgentInstructions = '/settings/ai-agent/instructions';
  static const aiAgentStyles = '/settings/ai-agent/styles';
  static const aiAgentAudit = '/settings/ai-agent/audit';
  /// Your WhatsApp (WhatsApp spec §2) and its sub-screens.
  static const whatsapp = '/settings/whatsapp';
  static const whatsappWelcome = '/settings/whatsapp/welcome';
  static const whatsappAway = '/settings/whatsapp/away';
  static const whatsappQuickReplies = '/settings/whatsapp/quick-replies';
  static const whatsappCloseTitles = '/settings/whatsapp/close-titles';
  static const whatsappTemplates = '/settings/whatsapp/templates';
  static const whatsappNumbers = '/settings/whatsapp/numbers';
  static String whatsappConnect({String? source}) =>
      Uri(path: '/settings/whatsapp/connect', queryParameters: {'source': ?source}).toString().replaceFirst(RegExp(r'\?$'), '');
  /// `new` creates (in [scope]).
  static String whatsappQuickReply(String id, {QuickReplyScope? scope}) => Uri(
        path: '/settings/whatsapp/quick-replies/${Uri.encodeComponent(id)}',
        queryParameters: {'scope': ?scope?.name},
      ).toString().replaceFirst(RegExp(r'\?$'), '');
  static const channels = '/account/channels';
  static const team = '/account/team';
  static const subscription = '/account/subscription';
  static const notificationSettings = '/account/notifications';
  static const help = '/account/help';
  static const profile = '/account/profile';
  static const security = '/account/security';

  /// `?messageId=` scrolls to + highlights a message; `compose=note` opens
  /// the composer in note mode (Chat spec §2).
  /// `claim=1` auto-claims (notification action); `source=push|handoff`
  /// drives the claim pulse and analytics (Claim spec §2).
  static String chat(
    String id, {
    bool readOnly = false,
    String? messageId,
    bool composeNote = false,
    bool autoClaim = false,
    String? source,
    String? searchQuery,
  }) => Uri(
    path: '/chat/$id',
    queryParameters: {
      if (readOnly) 'readonly': '1',
      'messageId': ?messageId,
      if (composeNote) 'compose': 'note',
      if (autoClaim) 'claim': '1',
      'source': ?source,
      'search': ?searchQuery,
    },
  ).toString().replaceFirst(RegExp(r'\?$'), '');

  static String contact(String contactId) => '/contacts/$contactId';
  static String editContact(String contactId) => '/contacts/$contactId/edit';

  /// Edit an answer, or a new one when [id] is null (Add Answer spec §2).
  static String editKnowledge(String? id) => id == null ? knowledgeNew : '/knowledge/$id/edit';

  /// New answer prefilled with a question (and answer) — AI suggestion card,
  /// `ai_no_answer` push.
  static String newKnowledgeFrom({required String question, String? answer}) =>
      Uri(path: knowledgeNew, queryParameters: {'question': question, 'answer': ?answer}).toString();

  /// New answer from an unanswered question group (prefill + AI draft).
  static String knowledgeFromQuestion(String questionId) =>
      Uri(path: knowledgeNew, queryParameters: {'fromQuestion': questionId}).toString();

  /// Chat long-press "حفظ في قاعدة المعرفة". [question]/[answer] are hints
  /// for the sample API; the real one reads `messages/{id}/kb-prefill`.
  static String knowledgeFromMessage(String messageId, {String? question, String? answer}) => Uri(
        path: knowledgeNew,
        queryParameters: {'fromMessage': messageId, 'question': ?question, 'answer': ?answer},
      ).toString();

  /// Admin review of a proposed answer (اعتماد / رفض).
  static String knowledgeReviewDraft(String draftId) =>
      Uri(path: knowledgeNew, queryParameters: {'draft': draftId}).toString();
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<bool>(ref.read(authProvider));
  ref.listen<bool>(authProvider, (_, next) => auth.value = next);
  ref.onDispose(auth.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.conversations,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.value;
      final public = Routes.public.contains(state.matchedLocation);
      if (!loggedIn && !public) return Routes.login;
      if (loggedIn && public) return Routes.conversations;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, s) => ForgotPasswordScreen(identifier: s.extra as String?),
      ),
      GoRoute(path: Routes.loginTwoFactor, builder: (_, _) => const TwoFactorScreen()),
      GoRoute(path: Routes.loginWorkspace, builder: (_, _) => const WorkspacePickerScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.conversations,
                // Deep links from push / notifications: ?segment=…&filter=…
                builder: (_, s) => ConversationsScreen(
                  segment: s.uri.queryParameters['segment'],
                  filter: s.uri.queryParameters['filter'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.dashboard, builder: (_, _) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.knowledge, builder: (_, _) => const KnowledgeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen())],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/chat/:id',
        pageBuilder: (_, s) => sharedAxisPage(
          s,
          ChatScreen(
            conversationId: s.pathParameters['id']!,
            readOnly: s.uri.queryParameters['readonly'] == '1',
            messageId: s.uri.queryParameters['messageId'],
            composeNote: s.uri.queryParameters['compose'] == 'note',
            autoClaim: s.uri.queryParameters['claim'] == '1',
            source: s.uri.queryParameters['source'],
            searchQuery: s.uri.queryParameters['search'],
          ),
        ),
      ),
      // Customer profile as a full screen (Profile spec §2) + edit (§7.1).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/contacts/:contactId',
        pageBuilder: (_, s) => sharedAxisPage(s, CustomerProfileScreen(contactId: s.pathParameters['contactId']!)),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/contacts/:contactId/edit',
        builder: (_, s) => EditContactScreen(contactId: s.pathParameters['contactId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.search,
        // ?conversationId= → in-conversation search on the chat (§11).
        redirect: (_, s) {
          final conv = s.uri.queryParameters['conversationId'];
          return conv == null ? null : Routes.chat(conv, searchQuery: s.uri.queryParameters['q']);
        },
        // Fade-through 200ms (Search spec §2).
        pageBuilder: (_, s) {
          final p = s.uri.queryParameters;
          return CustomTransitionPage<void>(
            key: s.pageKey,
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: simpleSlide,
            child: SearchScreen(
              args: SearchArgs(
                initialQuery: p['q'],
                scope: SearchScope.values.where((v) => v.name == p['scope']).firstOrNull,
                fromConversationId: p['fromConversation'],
                source: SearchSource.values.where((v) => v.name == p['source']).firstOrNull ?? SearchSource.inbox,
              ),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.notifications,
        // ?filter=all|unread|mentions|assignments|ai|system&highlight={id} (Notifications spec §2).
        pageBuilder: (_, s) => sharedAxisPage(
          s,
          NotificationsScreen(
            filter: s.uri.queryParameters['filter'],
            highlightId: s.uri.queryParameters['highlight'],
          ),
        ),
      ),
      // Add / edit answer modals (Add Answer spec §2). Declared before
      // '/knowledge/:id' so 'new' is never read as an id.
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.knowledgeNew, pageBuilder: (_, s) => KbAnswerEditorScreen.page(s)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/knowledge/:id/edit', pageBuilder: (_, s) => KbAnswerEditorScreen.page(s)),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgent, builder: (_, _) => const AiAgentScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgentHours, builder: (_, _) => const WorkingHoursScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgentHandoff, builder: (_, _) => const HandoffRulesScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgentTest, builder: (_, _) => const AiTestChatScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgentInstructions, builder: (_, _) => const CustomInstructionsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgentStyles, builder: (_, _) => const TeamStylesScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.aiAgentAudit, builder: (_, _) => const AiAuditScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsapp, builder: (_, _) => const WhatsAppChannelScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/settings/whatsapp/connect',
        builder: (_, s) => WaConnectScreen(source: s.uri.queryParameters['source'] ?? 'channel'),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsappWelcome, builder: (_, _) => const WaWelcomeEditorScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsappAway, builder: (_, _) => const WaAwayEditorScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsappQuickReplies, builder: (_, _) => const QuickRepliesScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsappCloseTitles, builder: (_, _) => const CloseTitlesScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/settings/whatsapp/quick-replies/:id',
        builder: (_, s) => QuickReplyEditorScreen(
          id: s.pathParameters['id'] ?? 'new',
          scope: QuickReplyScope.values.asNameMap()[s.uri.queryParameters['scope']],
        ),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsappTemplates, builder: (_, _) => const WaTemplatesScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.whatsappNumbers, builder: (_, _) => const WaNumbersScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.channels, builder: (_, _) => const ChannelsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.team, builder: (_, _) => const TeamScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.subscription, builder: (_, _) => const SubscriptionScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.notificationSettings,
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.help, builder: (_, _) => const HelpScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.profile, builder: (_, _) => const EditProfileScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.security, builder: (_, _) => const SecurityScreen()),
      // Knowledge Base sub-screens. Kept last so '/knowledge/new' and the
      // fixed segments win over '/knowledge/:id'.
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.knowledgeUnanswered, builder: (_, _) => const KbUnansweredScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/knowledge/files/:id/review',
        builder: (_, s) => KbDocumentReviewScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/knowledge/files/:id',
        builder: (_, s) => KbFileDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/knowledge/links/:id',
        builder: (_, s) => KbLinkDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/knowledge/:id',
        builder: (_, s) => KbQaDetailScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
});

/// Every pushed screen: the app's one plain slide ([simpleSlide]).
CustomTransitionPage<void> sharedAxisPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 280),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  transitionsBuilder: simpleSlide,
);
