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
import '../sheets/ai_confirm_sheets.dart';
import '../sheets/channels_sheet.dart';
import '../sheets/confidence_sheet.dart';

String aiConfidenceLabel(AppLocalizations l, ConfidenceLevel c) => switch (c) {
      ConfidenceLevel.low => l.ai_conf_low,
      ConfidenceLevel.medium => l.ai_conf_med,
      ConfidenceLevel.high => l.ai_conf_high,
    };

/// "متقدم" (AI Agent spec §4.8).
class AiAdvancedGroup extends ConsumerWidget {
  const AiAdvancedGroup({super.key, required this.config, required this.interactive});

  final AiAgentConfig config;
  final bool interactive;

  Future<void> _outsideKb(BuildContext context, WidgetRef ref, bool v) async {
    // Turning it ON is risky: destructive confirm first (§6.4).
    if (v && !await showOutsideKbConfirm(context)) return;
    if (!context.mounted) return;
    Analytics.log('ai_outside_kb_toggle', {'enabled': v});
    await saveAiChange(context, ref, (c) => c.copyWith(allowOutsideKb: v));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final on = [for (final e in config.channels.entries) if (e.value) aiChannelLabel(l, e.key)];
    final instr = config.customInstructions.trim();

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
        InkWell(
          onTap: interactive ? () => _outsideKb(context, ref, !config.allowOutsideKb) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.ai_outside_kb, style: context.text.listTitle),
                      Text(l.ai_outside_kb_sub, style: context.text.bodySmall.copyWith(color: context.colors.textWarning)),
                    ],
                  ),
                ),
                AppSwitch(
                  value: config.allowOutsideKb,
                  semanticLabel: l.ai_outside_kb,
                  onChanged: interactive ? (v) => _outsideKb(context, ref, v) : null,
                ),
              ],
            ),
          ),
        ),
        SettingsTile(
          title: l.ai_confidence,
          value: aiConfidenceLabel(l, config.confidence),
          onTap: interactive ? () => showConfidenceSheet(context, ref) : null,
        ),
        SettingsTile(
          title: l.ai_team_styles,
          value: '${config.rewriteStyles.length}',
          onTap: () => context.push(Routes.aiAgentStyles),
        ),
        SettingsTile(title: l.ai_audit, onTap: () => context.push(Routes.aiAgentAudit)),
      ],
    );
  }
}
