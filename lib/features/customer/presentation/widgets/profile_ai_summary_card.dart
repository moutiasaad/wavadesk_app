import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/contact.dart';

/// AI summary (§5.4): tonal card, sparkle header + "منذ {time}" + refresh,
/// body max 4 lines with "المزيد", disclaimer. Shimmer while regenerating.
class ProfileAiSummaryCard extends StatefulWidget {
  const ProfileAiSummaryCard({super.key, required this.summary, required this.loading, this.onRegenerate});

  final AiSummary summary;
  final bool loading;
  final VoidCallback? onRegenerate;

  @override
  State<ProfileAiSummaryCard> createState() => _ProfileAiSummaryCardState();
}

class _ProfileAiSummaryCardState extends State<ProfileAiSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final body = t.bodyMedium.copyWith(height: 1.6);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primaryContainerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.profile_ai_summary,
                    style: t.caption.copyWith(fontWeight: FontWeight.w800, color: c.onPrimaryContainer),
                  ),
                ),
              ),
              Text(AppFormat.relative(context, widget.summary.generatedAt), style: t.overline.copyWith(color: c.textTertiary)),
              if (widget.onRegenerate != null)
                AppIconButton(
                  icon: AppIcons.regenerate,
                  size: 32,
                  iconSize: 16,
                  iconColor: c.primary,
                  semanticLabel: l.profile_regenerate,
                  onPressed: widget.loading ? null : widget.onRegenerate,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: widget.loading
                ? AppSkeleton(
                    key: const ValueKey('loading'),
                    child: Column(
                      children: [
                        for (final w in [1.0, 0.92, 0.6])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: w,
                              child: const SkeletonBox(height: 11),
                            ),
                          ),
                      ],
                    ),
                  )
                : AnimatedSize(
                    key: const ValueKey('text'),
                    duration: AppMotion.normal,
                    alignment: AlignmentDirectional.topStart,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final painter = TextPainter(
                          text: TextSpan(text: widget.summary.text, style: body),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                          maxLines: 4,
                        )..layout(maxWidth: box.maxWidth);
                        final overflow = painter.didExceedMaxLines;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.summary.text,
                              style: body,
                              maxLines: _expanded ? null : 4,
                              overflow: _expanded ? null : TextOverflow.ellipsis,
                            ),
                            if (overflow && !_expanded)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: c.primary,
                                  textStyle: t.buttonSmall,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(48, 36),
                                ),
                                onPressed: () {
                                  Analytics.log('profile_ai_summary_expand');
                                  setState(() => _expanded = true);
                                },
                                child: Text(l.profile_more),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l.profile_ai_disclaimer, style: t.overline.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }
}
