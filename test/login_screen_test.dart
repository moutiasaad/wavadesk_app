import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wavadesk/core/data/data.dart';
import 'package:wavadesk/core/models/models.dart';
import 'package:wavadesk/core/router/app_router.dart';
import 'package:wavadesk/core/widgets/widgets.dart';
import 'package:wavadesk/features/auth/application/auth_session.dart';
import 'package:wavadesk/features/auth/presentation/login_screen.dart';
import 'package:wavadesk/features/auth/presentation/widgets/or_divider.dart';

import 'test_app.dart';

/// Acceptance checklist of `01 Login Screen.md` §15 that can run headless.
/// Several short frames so AnimatedSwitcher/AnimatedSize can finish and
/// drop outgoing children.
Future<void> settleFrames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  Finder field(int i) => find.byType(EditableText).at(i);

  AppButton signInButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, 'تسجيل الدخول'));

  Future<void> fill(WidgetTester tester, String id, String pw) async {
    await tester.enterText(field(0), id);
    await tester.enterText(field(1), pw);
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'تسجيل الدخول'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300)); // simulated API
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('signed-out start shows login; no WhatsApp login; no lone divider', (tester) async {
    await bootApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('واتساب'), findsNothing);
    // Biometrics unavailable in tests → divider hidden together with button.
    expect(find.byType(OrDivider), findsNothing);
    expect(tester.takeException(), isNull);
    await tearDownApp(tester);
  });

  testWidgets('button disabled until both fields are filled', (tester) async {
    await bootApp(tester);
    expect(signInButton(tester).onPressed, isNull);
    await tester.enterText(field(0), 'ahmed@lamsa.sa');
    await tester.pump();
    expect(signInButton(tester).onPressed, isNull);
    await tester.enterText(field(1), 'secret123');
    await tester.pump();
    expect(signInButton(tester).onPressed, isNotNull);
    await tearDownApp(tester);
  });

  testWidgets('validation runs on submit only and shows spec messages', (tester) async {
    await bootApp(tester);
    await fill(tester, 'ahmed@lamsa', 'short');
    expect(find.text('صيغة البريد غير صحيحة'), findsNothing); // not while typing
    await tester.tap(find.widgetWithText(AppButton, 'تسجيل الدخول'));
    await tester.pump();
    expect(find.text('صيغة البريد غير صحيحة'), findsOneWidget);
    expect(find.text('كلمة المرور 8 أحرف على الأقل'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('invalid credentials → banner, password cleared', (tester) async {
    await bootApp(tester);
    await fill(tester, 'ahmed@lamsa.sa', 'wrongpassword');
    await submit(tester);
    expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsOneWidget);
    expect(tester.widget<EditableText>(field(1)).controller.text, isEmpty);
    // Editing hides the banner.
    await tester.enterText(field(1), 'x');
    await settleFrames(tester);
    expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsNothing);
    await tearDownApp(tester);
  });

  testWidgets('locked account counts down and disables the button', (tester) async {
    await bootApp(tester);
    await fill(tester, 'locked@lamsa.sa', 'secret123');
    await submit(tester);
    expect(find.textContaining('محاولات كثيرة. حاول بعد 00:'), findsOneWidget);
    expect(signInButton(tester).onPressed, isNull);
    await tester.pump(const Duration(seconds: 31));
    await settleFrames(tester);
    expect(find.textContaining('محاولات كثيرة'), findsNothing);
    expect(signInButton(tester).onPressed, isNotNull);
    await tearDownApp(tester);
  });

  testWidgets('server and disabled errors map to the right banners', (tester) async {
    await bootApp(tester);
    await fill(tester, 'server@lamsa.sa', 'secret123');
    await submit(tester);
    expect(find.text('حدث خطأ من جهتنا. حاول مجددًا بعد قليل.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // client-side 1s rate limit
    await fill(tester, 'disabled@lamsa.sa', 'secret123');
    await submit(tester);
    expect(find.text('تم إيقاف هذا الحساب. تواصل مع مدير مساحة العمل.'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('success replaces the stack and opens Conversations → لي', (tester) async {
    final c = await bootApp(tester, prefs: {'lastSegment': 'all'});
    await fill(tester, '0501234567', 'secret123');
    await submit(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.read(authProvider), isTrue);
    expect(c.read(inboxProvider).segment, InboxSegment.mine);
    final router = c.read(routerProvider);
    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.conversations);
    expect(router.canPop(), isFalse);
    // Last identifier is the normalized phone.
    expect(c.read(authRepositoryProvider).lastIdentifier, '+966501234567');
    await tearDownApp(tester);
  });

  testWidgets('last identifier prefills the form', (tester) async {
    await bootApp(tester, secure: {'last_identifier': 'ahmed@lamsa.sa'});
    expect(tester.widget<EditableText>(field(0)).controller.text, 'ahmed@lamsa.sa');
    await tearDownApp(tester);
  });

  testWidgets('forgot password forwards the identifier', (tester) async {
    final c = await bootApp(tester);
    await tester.enterText(field(0), 'ahmed@lamsa.sa');
    await tester.tap(find.widgetWithText(AppButton, 'نسيت كلمة المرور؟'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.read(routerProvider).routerDelegate.currentConfiguration.last.matchedLocation, Routes.forgotPassword);
    expect(find.textContaining('ahmed@lamsa.sa'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('logout deletes the session and returns to login', (tester) async {
    final c = await bootApp(tester, secure: {...signedInStorage(), 'biometric_enabled': 'true'});
    expect(c.read(authProvider), isTrue);
    await c.read(authProvider.notifier).signOut();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(LoginScreen), findsOneWidget);
    final repo = c.read(authRepositoryProvider);
    expect(repo.refreshToken, isNull);
    expect(repo.biometricEnabled, isFalse);
    await tearDownApp(tester);
  });

  for (final v in [
    (name: 'iPhone SE 200% text', size: const Size(375, 667), scale: 2.0, prefs: <String, Object>{}),
    (name: 'dark mode', size: const Size(390, 844), scale: 1.0, prefs: <String, Object>{'themeMode': 'dark'}),
    (name: 'English LTR', size: const Size(390, 844), scale: 1.0, prefs: <String, Object>{'locale': 'en'}),
    (name: 'tablet landscape', size: const Size(1180, 820), scale: 1.0, prefs: <String, Object>{}),
  ]) {
    testWidgets('renders without overflow: ${v.name}', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = v.scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await bootApp(tester, size: v.size, prefs: v.prefs);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      // Max content width 420 on wide screens.
      final width = tester.getSize(find.byType(AppTextField).first).width;
      expect(width, lessThanOrEqualTo(420));
      await tearDownApp(tester);
    });
  }

  testWidgets('identifier and password text are LTR', (tester) async {
    await bootApp(tester);
    for (final i in [0, 1]) {
      expect(tester.widget<EditableText>(field(i)).textDirection, TextDirection.ltr);
    }
    expect(GoRouter.of(tester.element(find.byType(LoginScreen))), isNotNull);
    expect(ProviderScope.containerOf(tester.element(find.byType(LoginScreen))), isNotNull);
    await tearDownApp(tester);
  });
}
