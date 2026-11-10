import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import '../ai_save_feedback.dart';
import '../test/ai_why_sheet.dart';
import 'ai_tone_preview.dart';

/// "نبرة الرد": 3 equal chips (selected = ink), preview bubble, use-name
/// switch (AI Agent spec §4.5).
class AiToneSelector extends ConsumerWidget {
  const AiToneSelector({super.key, required this.config, required this.interactive});

  final AiAgentConfig config;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final big = MediaQuery.textScalerOf(context).scale(10) >= 18;

    Widget chip(AiTone tone) {
      final sel = config.tone == tone;
      // "Ink" chip: textPrimary fill, background-coloured label (inverts in dark).
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: sel,
        button: true,
        child: Material(
          color: sel ? c.textPrimary : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: sel ? c.textPrimary : c.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: !interactive || sel
                ? null
                : () {
                    Analytics.log('ai_tone_change', {'tone': tone.name});
                    saveAiChange(context, ref, (cfg) => cfg.copyWith(tone: tone));
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Text(aiToneLabel(l, tone), style: t.chipLabel.copyWith(color: sel ? c.background : c.textPrimary)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SettingsGroup(
      title: l.ai_tone,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 200% text: chips wrap to 2 rows (§10).
              if (big)
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final tone in AiTone.values) chip(tone)])
              else
                Row(
                  children: [
                    for (var i = 0; i < AiTone.values.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(child: chip(AiTone.values[i])),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              AiTonePreview(tone: config.tone),
            ],
          ),
        ),
        InkWell(
          onTap: interactive ? () => saveAiChange(context, ref, (cfg) => cfg.copyWith(useCustomerName: !config.useCustomerName)) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(l.ai_use_name, style: t.listTitle)),
                AppSwitch(
                  value: config.useCustomerName,
                  semanticLabel: l.ai_use_name,
                  onChanged: interactive ? (v) => saveAiChange(context, ref, (cfg) => cfg.copyWith(useCustomerName: v)) : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
