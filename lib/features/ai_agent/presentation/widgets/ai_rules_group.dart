import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import '../../domain/hours_validator.dart';
import '../ai_save_feedback.dart';
import '../sheets/reply_language_sheet.dart';
import '../sheets/web_reply_sheets.dart';

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
      LanguagePolicy.fr => l.ai_lang_fr,
      LanguagePolicy.es => l.ai_lang_es,
      LanguagePolicy.pt => l.ai_lang_pt,
      LanguagePolicy.de => l.ai_lang_de,
      LanguagePolicy.it => l.ai_lang_it,
    };

String aiDelayLabel(AppLocalizations l, int s) => switch (s) {
      0 => l.ai_delay_instant,
      30 => l.ai_delay_30s,
      60 => l.ai_delay_1m,
      120 => l.ai_delay_2m,
      _ => '$s s',
    };

/// "Replies" — the web panel's reply settings: language, suggestions per
/// message, answering when an agent has the chat, escalation keywords.
class AiRulesGroup extends ConsumerWidget {
  const AiRulesGroup({super.key, required this.config, required this.interactive});

  final AiAgentConfig config;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final words = config.handoff.keywords;
    final editable = interactive && config.canEdit;

    void toggleClaimed(bool v) {
      Analytics.log('ai_rule_change', {'rule': 'reply_when_claimed', 'value': v});
      saveAiChange(context, ref, (c) => c.copyWith(replyWhenClaimed: v));
    }

    return SettingsGroup(
      title: l.ai_replies,
      children: [
        SettingsTile(
          icon: AppIcons.globe,
          title: l.ai_language,
          value: aiLanguageLabel(l, config.language),
          onTap: interactive ? () => showReplyLanguageSheet(context, ref) : null,
        ),
        SettingsTile(
          icon: AppIcons.ai,
          title: l.ai_suggestions,
          value: '${config.suggestionCount}',
          onTap: interactive ? () => showSuggestionCountSheet(context, ref) : null,
        ),
        SettingsTile(
          icon: AppIcons.claim,
          title: l.ai_reply_claimed,
          subtitle: l.ai_reply_claimed_sub,
          showChevron: false,
          onTap: editable ? () => toggleClaimed(!config.replyWhenClaimed) : null,
          trailing: AppSwitch(
            value: config.replyWhenClaimed,
            semanticLabel: l.ai_reply_claimed,
            onChanged: editable ? toggleClaimed : null,
          ),
        ),
        SettingsTile(
          icon: AppIcons.team,
          title: l.ai_keywords,
          value: words.isEmpty ? l.ai_keywords_none : (words.length <= 2 ? words.join('، ') : l.ai_keywords_count(words.length)),
          onTap: () => showEscalationKeywordsSheet(context, ref),
        ),
      ],
    );
  }
}
