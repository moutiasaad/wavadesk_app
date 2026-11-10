import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/wd_api.dart' show useRealApi;
import '../../core/data/data.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  // Channels connected in the demo workspace (WhatsApp comes from its controller).
  // The API has no status for the other channels yet, so with the real API
  // they are not claimed as connected — they are managed on the web.
  static const _demoConnected = {Channel.web, Channel.instagram, Channel.messenger, Channel.email};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final wa = ref.watch(whatsappProvider);
    final whatsapp = wa.connected;

    // WhatsApp: until its status is known it stays in the first group (no jump).
    bool isOn(Channel ch) => ch == Channel.whatsapp ? (!wa.loaded || whatsapp) : (!useRealApi && _demoConnected.contains(ch));

    Widget row(Channel ch) {
      final on = isOn(ch);
      final String? subtitle;
      if (ch == Channel.whatsapp) {
        subtitle = !wa.loaded ? null : (on ? l.channels_connected : l.channels_not_connected);
      } else {
        subtitle = useRealApi ? l.channels_manage_on_web : (on ? l.channels_connected : l.channels_not_connected);
      }
      return SettingsTile(
        title: ch.label(l),
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelBadge.avatar(channel: ch, size: 28, ringColor: c.surface),
            const SizedBox(width: AppSpacing.sm),
            Icon(AppIcons.chevronEnd, size: 16, color: c.borderStrong),
          ],
        ),
        onTap: () {
          if (ch == Channel.whatsapp) {
            context.push(Routes.whatsapp);
          } else {
            AppSnackbar.show(context, message: l.channels_manage_on_web);
          }
        },
      );
    }

    final on = Channel.values.where(isOn).toList();
    final off = Channel.values.where((ch) => !isOn(ch)).toList();

    return ScrolledUnderBuilder(
      builder: (context, under) => Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(title: l.channels_title, scrolledUnder: under, background: c.backgroundMuted),
        body: ListView(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            if (on.isNotEmpty) SettingsGroup(title: l.channels_section_connected, children: [for (final ch in on) row(ch)]),
            if (off.isNotEmpty)
              SettingsGroup(
                title: l.channels_section_available,
                footer: l.channels_footer,
                children: [for (final ch in off) row(ch)],
              ),
          ],
        ),
      ),
    );
  }
}
