import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../ai_save_feedback.dart';

/// §4.6 auto-reply delay: instant / 30 s / 1 min / 2 min.
Future<void> showReplyDelaySheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(context, title: context.l10n.ai_delay, builder: (_) => const _DelayBody());
}

class _DelayBody extends ConsumerWidget {
  const _DelayBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return const SizedBox.shrink();
    final options = {0: l.ai_delay_instant, 30: l.ai_delay_30s, 60: l.ai_delay_1m, 120: l.ai_delay_2m};
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioGroup<int>(
            groupValue: options.containsKey(cfg.autoReplyDelaySeconds) ? cfg.autoReplyDelaySeconds : 0,
            onChanged: (v) {
              if (v == null || !cfg.canEdit) return;
              Analytics.log('ai_rule_change', {'rule': 'auto_reply_delay_seconds', 'value': v});
              saveAiChange(context, ref, (c) => c.copyWith(autoReplyDelaySeconds: v));
            },
            child: Column(
              children: [
                for (final e in options.entries)
                  RadioListTile<int>(
                    value: e.key,
                    enabled: cfg.canEdit,
                    title: Text(e.value, style: t.listTitle),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
            child: Text(l.ai_delay_note, style: t.caption.copyWith(color: c.textTertiary)),
          ),
        ],
      ),
    );
  }
}
