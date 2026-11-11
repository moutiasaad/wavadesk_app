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

/// A page of the web panel for this role (the browser asks to sign in first
/// when needed, then lands there).
Uri webPanelPage(AgentRole role, String path) {
  final panel = switch (role) {
    AgentRole.admin => 'tenant-admin',
    AgentRole.supervisor => 'supervisor',
    AgentRole.agent => 'agent',
  };
  return Uri.parse('$apiBaseUrl/$panel/$path');
}

/// The channels the product offers.
enum _Entry {
  /// WhatsApp by QR code: managed in the app.
  whatsapp,

  /// Official WhatsApp Business API (Meta): connected on the web panel.
  metaWhatsApp,

  /// Website chat widget: web panel.
  web,
}

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final wa = ref.watch(whatsappProvider);
    final role = ref.watch(currentAgentProvider).role;

    Future<void> openOnWeb(String path) async {
      final ok = await launchUrl(webPanelPage(role, path), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) AppSnackbar.show(context, message: l.channels_open_web_failed, kind: SnackKind.error);
    }

    // WhatsApp: until its status is known it stays in the first group (no jump).
    // The API has no status for the others yet: they are managed on the web.
    bool isOn(_Entry e) => e == _Entry.whatsapp && (!wa.loaded || wa.connected);

    Widget row(_Entry e) {
      final on = isOn(e);
      final (String title, String? subtitle, Channel badge) = switch (e) {
        _Entry.whatsapp => (
            Channel.whatsapp.label(l),
            !wa.loaded ? null : (on ? l.channels_connected : l.channels_not_connected),
            Channel.whatsapp,
          ),
        _Entry.metaWhatsApp => (l.channels_meta, l.channels_meta_sub, Channel.whatsapp),
        _Entry.web => (Channel.web.label(l), l.channels_open_on_web, Channel.web),
      };
      return SettingsTile(
        title: title,
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelBadge.avatar(channel: badge, size: 28, ringColor: c.surface),
            const SizedBox(width: AppSpacing.sm),
            AppIcon(
              e == _Entry.whatsapp ? AppIcons.chevronForward : AppIcons.externalLink,
              size: AppIconSize.sm,
              color: c.borderStrong,
            ),
          ],
        ),
        onTap: () => switch (e) {
          _Entry.whatsapp => context.push(Routes.whatsapp),
          _Entry.metaWhatsApp => openOnWeb('whatsapp-official'),
          // Widget settings are admin-only on the web; others get the inbox.
          _Entry.web => openOnWeb(role == AgentRole.admin ? 'webchat/settings' : 'webchat/conversations'),
        },
      );
    }

    final on = _Entry.values.where(isOn).toList();
    final off = _Entry.values.where((e) => !isOn(e)).toList();

    return ScrolledUnderBuilder(
      builder: (context, under) => Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(title: l.channels_title, scrolledUnder: under, background: c.backgroundMuted),
        body: ListView(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            if (on.isNotEmpty) SettingsGroup(title: l.channels_section_connected, children: [for (final e in on) row(e)]),
            if (off.isNotEmpty)
              SettingsGroup(
                title: l.channels_section_available,
                footer: l.channels_footer,
                children: [for (final e in off) row(e)],
              ),
          ],
        ),
      ),
    );
  }
}
