import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/ai_agent_config.dart';
import 'ai_mode_group.dart';
import 'ai_performance_sheet.dart';

/// Teal status card (AI Agent spec §4.2): answered this week, hours saved,
/// mode pill, usage bar at ≥ 80% / exhausted.
class AiStatusHero extends StatelessWidget {
  const AiStatusHero({super.key, required this.config, this.countUp = false});

  final AiAgentConfig config;
  final bool countUp;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final reduced = AppMotion.reduced(context);
    final on = config.enabled && config.planAllowsAi;
    final s = config.stats;
    final usage = config.usage;
    final share = usage.share;

    final bg = on ? (c.isDark ? const Color(0xFF0F7E7A) : c.primary) : (c.isDark ? const Color(0xFF1C272C) : c.surfaceVariant);
    final fg = on ? Colors.white : c.textSecondary;

    final Widget title;
    final String caption;
    if (!on) {
      title = Text(l.ai_hero_off, style: _value(t, fg));
      caption = l.ai_hero_off_body;
    } else if (!s.hasData) {
      title = Text(l.ai_hero_ready, style: _value(t, fg));
      caption = l.ai_hero_ready_body;
    } else {
      title = countUp && !reduced
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.answered.toDouble()),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Text(l.ai_hero_answered('${v.round()}'), style: _value(t, fg)),
            )
          : Text(l.ai_hero_answered('${s.answered}'), style: _value(t, fg));
      caption = l.ai_hero_caption('${s.hoursSaved}');
    }

    final showUsage = on && share != null && share >= 0.8;
    final resets = usage.resetsAt == null ? '' : intl.DateFormat('d/M').format(usage.resetsAt!);

    return Semantics(
      button: true,
      label: on && s.hasData ? l.ai_hero_a11y('${s.answered}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showAiPerformanceSheet(context, config),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? Colors.white.withValues(alpha: 0.16) : c.surface,
                        ),
                        child: Icon(AppIcons.sparkle, size: 24, color: on ? Colors.white : c.textTertiary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 2),
                            Text(caption, style: t.bodySmall.copyWith(fontSize: 13, color: on ? Colors.white.withValues(alpha: 0.85) : c.textSecondary)),
                          ],
                        ),
                      ),
                      if (on) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            aiModeTitle(l, config.mode),
                            style: t.caption.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showUsage) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: share.clamp(0, 1),
                        minHeight: 4,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      usage.exhausted ? l.ai_quota_out(resets) : l.ai_usage('${(share * 100).round()}'),
                      style: t.caption.copyWith(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _value(AppTextStyles t, Color fg) => t.h2.copyWith(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3, color: fg);
}
