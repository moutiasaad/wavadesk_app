import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import '../ai_save_feedback.dart';
import '../sheets/channels_sheet.dart';

String aiConfidenceLabel(AppLocalizations l, ConfidenceLevel c) => switch (c) {
      ConfidenceLevel.low => l.ai_conf_low,
      ConfidenceLevel.medium => l.ai_conf_med,
      ConfidenceLevel.high => l.ai_conf_high,
    };

/// "متقدم" — the web panel's: channels, custom instructions, answer source
/// (when the bot organisation is available), plus the change log.
class AiAdvancedGroup extends ConsumerWidget {
  const AiAdvancedGroup({super.key, required this.config, required this.interactive});

  final AiAgentConfig config;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final on = [
      for (final e in config.channels.entries)
        if (e.value && aiWebChannels.contains(e.key)) aiChannelLabel(l, e.key),
    ];
    final instr = config.customInstructions.trim();
    final flowAvailable = config.answerSources.contains('flow');

    return SettingsGroup(
      title: l.ai_advanced,
      children: [
        SettingsTile(
          title: l.ai_channels,
          value: on.isEmpty ? l.ai_channels_none : on.join('، '),
          onTap: interactive ? () => showChannelsSheet(context, ref) : null,
        ),
        SettingsTile(
          title: l.ai_instructions,
          value: instr.isEmpty ? l.ai_instructions_empty : (instr.length > 20 ? '${instr.substring(0, 18)}…' : instr),
          onTap: () => context.push(Routes.aiAgentInstructions),
        ),
        if (flowAvailable)
          SettingsTile(
            title: l.ai_answer_source,
            value: config.answerSource == 'flow' ? l.ai_answer_source_flow : l.ai_answer_source_kb,
            onTap: interactive && config.canEdit ? () => _pickSource(context, ref) : null,
          ),
        SettingsTile(title: l.ai_audit, onTap: () => context.push(Routes.aiAgentAudit)),
      ],
    );
  }

  Future<void> _pickSource(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final picked = await AppBottomSheet.show<String>(
      context,
      title: l.ai_answer_source,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, label, sub) in [
              ('knowledge', l.ai_answer_source_kb, l.ai_answer_source_kb_sub),
              ('flow', l.ai_answer_source_flow, l.ai_answer_source_flow_sub),
            ])
              AppRadioRow(
                label: label,
                subtitle: sub,
                selected: config.answerSource == key,
                onTap: () => Navigator.of(ctx).pop(key),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == config.answerSource || !context.mounted) return;
    Analytics.log('ai_rule_change', {'rule': 'answer_source', 'value': picked});
    await saveAiChange(context, ref, (c) => c.copyWith(answerSource: picked));
  }
}
