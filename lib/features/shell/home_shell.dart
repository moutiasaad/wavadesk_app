import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/data.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import '../conversations/application/conversations_controller.dart';
import '../conversations/presentation/widgets/multi_select_bar.dart';

/// Root scaffold with the 4-tab [AppTabBar] (§8.2).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mineUnread = ref.watch(inboxTabBadgeProvider);
    // Multi-select on the inbox replaces the tab bar (Inbox spec §4.9).
    final selecting = shell.currentIndex == 0 && ref.watch(inboxProvider.select((s) => s.selecting));

    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    void openSearch() => context.push('${Routes.search}?source=shortcut');
    final scaffold = Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: selecting
          ? const MultiSelectBar()
          : AppTabBar(
              currentIndex: shell.currentIndex,
              onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              items: [
                AppTabItem(icon: AppIcons.conversations, label: l.tab_conversations, badge: mineUnread),
                AppTabItem(icon: AppIcons.dashboard, label: l.tab_dashboard),
                AppTabItem(icon: AppIcons.knowledge, label: l.tab_knowledge),
                AppTabItem(icon: AppIcons.account, label: l.tab_account),
              ],
            ),
    );
    if (!tablet) return scaffold;
    // Ctrl/⌘+K → search on tablets with a keyboard (Search spec §2).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): openSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): openSearch,
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}

/// Bottom padding for content under the floating tab bar.
double tabBarInset(BuildContext context) =>
    math.max(MediaQuery.paddingOf(context).bottom, AppTabBar.height + MediaQuery.viewPaddingOf(context).bottom) + AppSpacing.lg;
