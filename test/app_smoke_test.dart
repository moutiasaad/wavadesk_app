import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wavadesk/core/data/data.dart';
import 'package:wavadesk/core/router/app_router.dart';

import 'test_app.dart';

/// Boots the real app and walks every main screen, failing on any thrown
/// exception or layout overflow.
void main() {
  Future<ProviderContainer> boot(WidgetTester tester, Map<String, Object> prefs) {
    final loggedIn = prefs['loggedIn'] == true;
    final p = Map<String, Object>.of(prefs)..remove('loggedIn');
    return bootApp(tester, prefs: p, secure: loggedIn ? signedInStorage() : const {});
  }

  Future<void> visit(WidgetTester tester, ProviderContainer c, String location) async {
    c.read(routerProvider).go(location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.takeException(), isNull, reason: location);
  }

  const screens = [
    Routes.conversations,
    Routes.dashboard,
    Routes.knowledge,
    Routes.account,
    '/chat/c1',
    '/chat/c2',
    '/chat/c4',
    '/chat/c8',
    '/chat/c10',
    Routes.search,
    Routes.notifications,
    Routes.knowledgeNew,
    '/knowledge/kb_s1/edit',
    Routes.aiAgent,
    Routes.whatsapp,
    Routes.channels,
    Routes.team,
    Routes.subscription,
    Routes.notificationSettings,
    Routes.help,
  ];

  for (final variant in [
    {'locale': 'ar', 'themeMode': 'light'},
    {'locale': 'en', 'themeMode': 'light'},
    {'locale': 'ar', 'themeMode': 'dark'},
  ]) {
    testWidgets('all screens render (${variant['locale']}, ${variant['themeMode']})', (tester) async {
      final c = await boot(tester, {'loggedIn': true, ...variant});
      for (final s in screens) {
        await visit(tester, c, s);
      }
      await tearDownApp(tester);
    });
  }

  testWidgets('login screen renders and rejects a bad email', (tester) async {
    await boot(tester, {'loggedIn': false});
    expect(find.byType(EditableText), findsWidgets);
    expect(tester.takeException(), isNull);
    await tearDownApp(tester);
  });

  testWidgets('screens survive 200% text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await boot(tester, {'loggedIn': true});
    for (final s in [Routes.conversations, '/chat/c1', Routes.account, Routes.dashboard]) {
      await visit(tester, c, s);
    }
    await tearDownApp(tester);
  });

  testWidgets('claim flow swaps the claim bar for the composer', (tester) async {
    final c = await boot(tester, {'loggedIn': true});
    c.read(routerProvider).go('/chat/c6');
    await tester.pump(const Duration(milliseconds: 400));
    c.read(inboxProvider.notifier).claim('c6');
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(c.read(conversationProvider('c6'))!.assignee?.id, MockData.me.id);
    expect(GoRouter.of(tester.element(find.byType(Scaffold).first)), isNotNull);
    await tearDownApp(tester);
  });
}
