import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import 'ai_performance_sheet.dart';

/// "الأداء" (AI Agent spec §4.7) — only when there is data.
class AiPerformanceGroup extends StatelessWidget {
  const AiPerformanceGroup({super.key, required this.config});

  final AiAgentConfig config;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final s = config.stats;
    if (!s.hasData && config.unansweredCount == 0) return const SizedBox.shrink();
    String pct(double v) => '${(v * 100).round()}%';

    return SettingsGroup(
      title: l.ai_perf,
      children: [
        if (s.resolutionRate != null)
          SettingsTile(title: l.ai_perf_resolution, value: pct(s.resolutionRate!), showChevron: false),
        if (s.thumbsUpRate != null) SettingsTile(title: l.ai_perf_rating, value: pct(s.thumbsUpRate!), showChevron: false),
        SettingsTile(
          title: l.ai_perf_unanswered,
          trailing: Text(
            '${config.unansweredCount}',
            style: context.text.bodySmall.copyWith(color: config.unansweredCount > 0 ? c.textWarning : c.textSecondary, fontWeight: FontWeight.w700),
          ),
          onTap: () => context.go(Routes.knowledge),
        ),
        if (s.hasData) SettingsTile(title: l.ai_perf_detail, onTap: () => showAiPerformanceSheet(context, config)),
      ],
    );
  }
}
