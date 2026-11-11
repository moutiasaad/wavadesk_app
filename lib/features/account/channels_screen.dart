import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/wd_api.dart' show apiBaseUrl;
import '../../core/data/data.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';

/// The web panel page that manages [ch] for this role (the browser asks to
/// sign in first when needed, then lands there).
Uri channelWebPage(Channel ch, AgentRole role) {
  final panel = switch (role) {
    AgentRole.admin => 'tenant-admin',
    AgentRole.supervisor => 'supervisor',
    AgentRole.agent => 'agent',
  };
  final path = switch (ch) {
    Channel.messenger => 'messenger/settings',
    // Widget settings are admin-only on the web; others get the inbox.
    Channel.web => role == AgentRole.admin ? 'webchat/settings' : 'webchat/conversations',
    _ => '',
  };
  return Uri.parse('$apiBaseUrl/$panel/$path');
}

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final wa = ref.watch(whatsappProvider);
    final role = ref.watch(currentAgentProvider).role;

    Future<void> openOnWeb(Channel ch) async {
      final ok = await launchUrl(channelWebPage(ch, role), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) AppSnackbar.show(context, message: l.channels_open_web_failed, kind: SnackKind.error);
    }
    final whatsapp = wa.connected;

    // WhatsApp: until its status is known it stays in the first group (no jump).
    bool isOn(Channel ch) => ch == Channel.whatsapp ? (!wa.loaded || whatsapp) : false;
    // The API has no status for the other channels yet: they are managed on the web.

    Widget row(Channel ch) {
      final on = isOn(ch);
      final String? subtitle;
      if (ch == Channel.whatsapp) {
        subtitle = !wa.loaded ? null : (on ? l.channels_connected : l.channels_not_connected);
      } else {
        subtitle = l.channels_open_on_web;
      }
      return SettingsTile(
        title: ch == Channel.messenger ? l.channels_meta : ch.label(l),
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelBadge.avatar(channel: ch, size: 28, ringColor: c.surface),
            const SizedBox(width: AppSpacing.sm),
            AppIcon(
              ch == Channel.whatsapp ? AppIcons.chevronForward : AppIcons.externalLink,
              size: AppIconSize.sm,
              color: c.borderStrong,
            ),
          ],
        ),
        onTap: () {
          if (ch == Channel.whatsapp) {
            context.push(Routes.whatsapp);
          } else {
            openOnWeb(ch);
          }
        },
      );
    }

    // The channels the product offers: WhatsApp (managed here), website
    // chat and Meta Messenger (opened on the web panel).
    const shown = [Channel.whatsapp, Channel.web, Channel.messenger];
    final on = shown.where(isOn).toList();
    final off = shown.where((ch) => !isOn(ch)).toList();

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
