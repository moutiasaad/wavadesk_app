import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../../domain/ai_agent_config.dart';
import '../ai_save_feedback.dart';
import '../widgets/ai_rules_group.dart' show aiLanguageLabel;

/// Reply language — the web panel's list (Auto = the customer's language).
Future<void> showReplyLanguageSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(context, title: context.l10n.ai_language, builder: (_) => const _LanguageBody());
}

class _LanguageBody extends ConsumerWidget {
  const _LanguageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return const SizedBox.shrink();
    final enabled = cfg.canEdit;

    void save(AiAgentConfig Function(AiAgentConfig) edit, String value) {
      Analytics.log('ai_rule_change', {'rule': 'language', 'value': value});
      saveAiChange(context, ref, edit);
    }

    final policies = {
      for (final p in LanguagePolicy.values)
        // An older server only accepts Auto / Arabic / English.
        if (cfg.serverHasWebSettings || p.index <= LanguagePolicy.en.index)
          p: (aiLanguageLabel(l, p), p == LanguagePolicy.customer ? l.ai_lang_customer_sub : null),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioGroup<LanguagePolicy>(
            groupValue: cfg.language,
            onChanged: (p) {
              if (p == null || !enabled) return;
              save((c) => c.copyWith(language: p), p.name);
            },
            child: Column(
              children: [
                for (final e in policies.entries)
                  RadioListTile<LanguagePolicy>(
                    value: e.key,
                    enabled: enabled,
                    title: Text(e.value.$1, style: t.listTitle),
                    subtitle: e.value.$2 == null ? null : Text(e.value.$2!, style: t.caption.copyWith(color: c.textSecondary)),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
