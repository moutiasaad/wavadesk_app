import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);

    Widget row(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) => SettingsTile(
          icon: icon,
          title: title,
          subtitle: sub,
          trailing: AppSwitch(value: value, semanticLabel: title, onChanged: onChanged),
        );

    return ScrolledUnderBuilder(
      builder: (context, under) => Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(title: l.notif_settings_title, scrolledUnder: under, background: c.backgroundMuted),
        body: ListView(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            SettingsGroup(
              title: l.notif_settings_section_push,
              children: [
                row(AppIcons.mine, l.notif_settings_assigned, l.notif_settings_assigned_sub, s.notifyNewAssigned,
                    (v) => ctl.setNotification(newAssigned: v)),
                row(AppIcons.note, l.notif_settings_mentions, l.notif_settings_mentions_sub, s.notifyMentions,
                    (v) => ctl.setNotification(mentions: v)),
                row(AppIcons.clock, l.notif_settings_waiting, l.notif_settings_waiting_sub, s.notifyWaiting,
                    (v) => ctl.setNotification(waiting: v)),
              ],
            ),
            SettingsGroup(
              title: l.notif_settings_section_sound,
              footer: l.notif_settings_footer,
              children: [
                row(AppIcons.bell, l.notif_settings_sound, l.notif_settings_sound_sub, s.notifySound,
                    (v) => ctl.setNotification(sound: v)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
