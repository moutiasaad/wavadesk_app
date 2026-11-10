import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/ai_agent_config.dart';
import '../../domain/readiness.dart';

/// "قبل التفعيل الكامل" checklist (AI Agent spec §4.3). Hidden when complete.
class AiReadinessCard extends StatelessWidget {
  const AiReadinessCard({super.key, required this.config});

  final AiAgentConfig config;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final r = Readiness.of(config);
    if (r.complete) return const SizedBox.shrink();

    final rows = [
      (ReadinessItem.kb, l.ai_ready_kb('${config.readiness.kbEntries.clamp(0, config.readiness.kbMin)}'), () => context.go(Routes.knowledge)),
      (ReadinessItem.hours, l.ai_ready_hours, () => context.push(Routes.aiAgentHours)),
      (ReadinessItem.handoff, l.ai_ready_handoff, () => context.push(Routes.aiAgentHandoff)),
      (ReadinessItem.tested, l.ai_ready_tested, () => context.push(Routes.aiAgentTest)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.isDark ? const Color(0xFF6B5320) : const Color(0xFFF7E2A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.alertTriangle, size: 18, color: c.textWarning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l.ai_ready_title, style: t.h6)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (item, label, go) in rows)
            Semantics(
              button: !r.done(item),
              label: '$label، ${r.done(item) ? l.ai_ready_done : l.ai_ready_missing}',
              excludeSemantics: true,
              child: InkWell(
                onTap: r.done(item) ? null : go,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        r.done(item)
                            ? Icon(AppIcons.check, size: 18, color: c.success)
                            : Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderStrong, width: 1.5)),
                              ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            label,
                            style: t.bodySmall.copyWith(color: r.done(item) ? c.textSecondary : c.textPrimary),
                          ),
                        ),
                        if (!r.done(item)) Icon(AppIcons.chevronEnd, size: 16, color: c.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
