import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final topics = [
      (AppIcons.claim, l.help_topic_claim),
      (AppIcons.sparkle, l.help_topic_ai),
      (AppIcons.whatsapp, l.help_topic_whatsapp),
      (AppIcons.knowledge, l.help_topic_knowledge),
      (AppIcons.snooze, l.help_topic_snooze),
    ];
    void soon() => AppSnackbar.show(context, message: l.help_opening);

    return ScrolledUnderBuilder(
      builder: (context, under) => Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(title: l.help_title, scrolledUnder: under, background: c.backgroundMuted),
        body: ListView(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            SettingsGroup(
              title: l.help_section_guides,
              children: [for (final (icon, title) in topics) SettingsTile(icon: icon, title: title, onTap: soon)],
            ),
            SettingsGroup(
              title: l.help_section_contact,
              children: [
                SettingsTile(
                  icon: AppIcons.headphones,
                  title: l.help_contact_chat,
                  subtitle: l.help_contact_chat_sub,
                  onTap: soon,
                ),
                SettingsTile(
                  icon: AppIcons.mail,
                  title: l.help_contact_email,
                  value: 'support@wavadesk.com',
                  valueDirection: TextDirection.ltr,
                  onTap: soon,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
