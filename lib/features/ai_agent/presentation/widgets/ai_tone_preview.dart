import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/ai_agent_config.dart';

String aiToneSample(AppLocalizations l, AiTone tone) => switch (tone) {
      AiTone.friendly => l.ai_tone_sample_friendly,
      AiTone.formal => l.ai_tone_sample_formal,
      AiTone.concise => l.ai_tone_sample_concise,
    };

/// Sample reply in the selected tone, AI bubble style (AI Agent spec §4.5).
/// Live region so screen readers hear the new sample; 150 ms cross-fade.
class AiTonePreview extends StatelessWidget {
  const AiTonePreview({super.key, required this.tone});

  final AiTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final text = aiToneSample(l, tone);
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: c.bubbleAi,
            border: Border.all(color: c.bubbleAiBorder),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(AppRadius.lg),
              topEnd: Radius.circular(AppRadius.lg),
              bottomStart: Radius.circular(AppRadius.lg),
              bottomEnd: Radius.circular(AppRadius.bubbleTail),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.ai, size: AppIconSize.xs, color: c.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l.ai_test_label, style: t.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.fast,
                child: Text(text, key: ValueKey(tone), style: t.bodySmall.copyWith(color: c.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
