import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import '../../domain/hours_validator.dart';
import '../sheets/handoff_message_sheet.dart';
import '../sheets/reply_delay_sheet.dart';
import '../sheets/reply_language_sheet.dart';

/// "9 ص – 10 م" (Latin digits; AM/PM in English).
String aiClock(AppLocalizations l, int minutes, {required bool arabic}) {
  final h = minutes ~/ 60 % 24;
  final m = minutes % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final mm = m == 0 ? '' : ':${m.toString().padLeft(2, '0')}';
  final suffix = arabic ? (h < 12 ? 'ص' : 'م') : (h < 12 ? 'AM' : 'PM');
  return '$h12$mm $suffix';
}

String aiHoursSummary(AppLocalizations l, WorkingHours h, {required bool arabic}) {
  if (h.is24h) return l.ai_hours_24;
  final span = HoursValidator.span(h);
  if (span == null) return l.ai_hours_unset;
  return '${aiClock(l, span.$1, arabic: arabic)} – ${aiClock(l, span.$2, arabic: arabic)}';
}

String aiLanguageLabel(AppLocalizations l, LanguagePolicy p) => switch (p) {
      LanguagePolicy.customer => l.ai_lang_customer,
      LanguagePolicy.ar => l.ai_lang_ar,
      LanguagePolicy.en => l.ai_lang_en,
    };

String aiDelayLabel(AppLocalizations l, int s) => switch (s) {
      0 => l.ai_delay_instant,
      30 => l.ai_delay_30s,
      60 => l.ai_delay_1m,
      120 => l.ai_delay_2m,
      _ => '$s s',
    };

/// "القواعد" (AI Agent spec §4.6).
class AiRulesGroup extends ConsumerWidget {
  const AiRulesGroup({super.key, required this.config, required this.interactive});

  final AiAgentConfig config;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final arabic = context.localeName.startsWith('ar');
    final unset = !config.hours.isSet;
    final msg = config.handoff.message.isEmpty ? l.ai_handoff_msg_default : config.handoff.message;
    final shortMsg = msg.length > 28 ? '«${msg.substring(0, 26)}…»' : '«$msg»';

    // Sub-screens still open read-only for agents (they show disabled controls).
    return SettingsGroup(
      title: l.ai_rules,
      children: [
        SettingsTile(
          icon: AppIcons.clock,
          title: l.ai_hours,
          value: unset ? null : aiHoursSummary(l, config.hours, arabic: arabic),
          trailing: unset ? Text(l.ai_hours_unset, style: context.text.bodySmall.copyWith(color: c.textWarning)) : null,
          onTap: () => context.push(Routes.aiAgentHours),
        ),
        SettingsTile(
          icon: AppIcons.team,
          title: l.ai_handoff,
          subtitle: l.ai_handoff_sub,
          onTap: () => context.push(Routes.aiAgentHandoff),
        ),
        SettingsTile(
          icon: AppIcons.globe,
          title: l.ai_language,
          value: aiLanguageLabel(l, config.language),
          onTap: interactive ? () => showReplyLanguageSheet(context, ref) : null,
        ),
        SettingsTile(
          icon: AppIcons.conversation,
          title: l.ai_handoff_msg,
          value: shortMsg,
          onTap: interactive ? () => showHandoffMessageSheet(context, ref) : null,
        ),
        SettingsTile(
          icon: AppIcons.waiting,
          title: l.ai_delay,
          value: aiDelayLabel(l, config.autoReplyDelaySeconds),
          onTap: interactive ? () => showReplyDelaySheet(context, ref) : null,
        ),
      ],
    );
  }
}
