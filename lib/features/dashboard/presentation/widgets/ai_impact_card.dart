import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/metric_formatters.dart';

/// AI impact (Dashboard spec §4.7) — owner / admin with the AI on.
class AiImpactCard extends StatelessWidget {
  const AiImpactCard({super.key, required this.ai, this.handling});

  final AiResolution ai;

  /// Conversations the AI is answering right now (`ai_now.handling`).
  final int? handling;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final fg = c.onPrimaryContainer;
    final small = t.caption.copyWith(color: fg);

    return Material(
      color: c.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: c.primaryContainerBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.aiAgent),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: AppIcon(AppIcons.ai, color: c.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.dash_ai_impact(MetricFormat.grouped(ai.answered)), style: t.h5.copyWith(color: fg)),
                        const SizedBox(height: 2),
                        Text(l.dash_ai_saved(MetricFormat.grouped(ai.hoursSaved)), style: t.bodySmall.copyWith(color: fg)),
                      ],
                    ),
                  ),
                  AppIcon(AppIcons.chevronForward, dp: 18, color: fg),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.dash_ai_handoffs(MetricFormat.grouped(ai.handoffs)), style: small),
                  if (ai.thumbsUpRate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(AppIcons.thumbsUp, size: AppIconSize.xs, color: fg),
                        const SizedBox(width: AppSpacing.xs),
                        Text(l.dash_ai_rating('${(ai.thumbsUpRate! * 100).round()}'), style: small),
                      ],
                    ),
                  if (handling != null) Text(l.dash_ai_handling(MetricFormat.grouped(handling!)), style: small),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
