import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/ai_agent_controller.dart';

/// AI agent sub-screens read the shared config. Until it has loaded once they
/// show a skeleton (or the load error + retry) instead of defaults / "empty"
/// — so nothing is edited from placeholder values (load_state.dart rule 2).
class AiConfigGate extends ConsumerWidget {
  const AiConfigGate({super.key, required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(aiAgentControllerProvider);
    if (s.config != null) return builder(context);
    final c = context.colors;
    final l = context.l10n;
    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: title, background: c.backgroundMuted),
      body: s.error != null && !s.loading
          ? EmptyState(
              icon: s.offline ? AppIcons.offline : AppIcons.error,
              title: l.ai_load_error,
              actionLabel: l.ai_retry,
              onAction: ref.read(aiAgentControllerProvider.notifier).load,
            )
          : AppSkeleton.list(rows: 5),
    );
  }
}
