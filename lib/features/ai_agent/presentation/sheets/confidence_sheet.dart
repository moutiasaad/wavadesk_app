import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../../domain/ai_agent_config.dart';
import '../ai_save_feedback.dart';

/// §4.8 auto-send confidence threshold: low / medium / high.
Future<void> showConfidenceSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(context, title: context.l10n.ai_confidence, builder: (_) => const _ConfidenceBody());
}

class _ConfidenceBody extends ConsumerWidget {
  const _ConfidenceBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return const SizedBox.shrink();
    final rows = {
      ConfidenceLevel.low: (l.ai_conf_low, l.ai_conf_low_sub),
      ConfidenceLevel.medium: (l.ai_conf_med, l.ai_conf_med_sub),
      ConfidenceLevel.high: (l.ai_conf_high, l.ai_conf_high_sub),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: RadioGroup<ConfidenceLevel>(
        groupValue: cfg.confidence,
        onChanged: (v) {
          if (v == null || !cfg.canEdit) return;
          Analytics.log('ai_rule_change', {'rule': 'confidence_threshold', 'value': v.name});
          saveAiChange(context, ref, (c) => c.copyWith(confidence: v));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in rows.entries)
              RadioListTile<ConfidenceLevel>(
                value: e.key,
                enabled: cfg.canEdit,
                title: Text(e.value.$1, style: t.listTitle),
                subtitle: Text(e.value.$2, style: t.caption.copyWith(color: c.textSecondary)),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
          ],
        ),
      ),
    );
  }
}
