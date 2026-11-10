import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';
import '../../domain/wa_status.dart';
import '../wa_links.dart';
import 'wa_status_pill.dart';
import 'wa_loading_body.dart';

/// "الأرقام" (WhatsApp spec §4.6). Admin-only except the video row.
class WaNumbersGroup extends StatelessWidget {
  const WaNumbersGroup({super.key, required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final admin = channel.permissions.isAdmin;
    final canAdd = channel.extraNumbersAllowed > channel.numbers.length;

    return SettingsGroup(
      title: l.wa_numbers,
      children: [
        if (admin && canAdd)
          SettingsTile(
            icon: AppIcons.plus,
            title: l.wa_add_number,
            onTap: () => context.push(Routes.whatsappConnect(source: 'add_number')),
          )
        else if (admin)
          SettingsTile(
            icon: AppIcons.lock,
            iconColor: c.textTertiary,
            iconBackground: c.surfaceVariant,
            title: l.wa_add_second,
            subtitle: l.wa_business_only,
            trailing: AppButton(
              label: l.wa_upgrade,
              size: AppButtonSize.small,
              variant: AppButtonVariant.tonal,
              height: 30,
              onPressed: () => channel.permissions.canDisconnect
                  ? WaLinks.billing(channel.upgradeUrl)
                  : AppSnackbar.show(context, message: l.wa_upgrade_info),
            ),
          ),
        if (admin)
          for (final n in channel.numbers)
            SettingsTile(
              title: n.displayName ?? formatWaPhone(n.phone),
              subtitle: n.displayName == null ? null : formatWaPhone(n.phone),
              trailing: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: waPillColors(context, waPillTone(n.status)).dot, shape: BoxShape.circle),
              ),
            ),
        InkWell(
          onTap: WaLinks.video,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: c.errorContainer, borderRadius: BorderRadius.circular(10)),
                  child: Icon(AppIcons.play, size: 18, color: c.textError),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.wa_watch, style: t.listTitle.copyWith(fontSize: 14.5)),
                      Text(l.wa_watch_sub(WaLinks.howToVideoLength), style: t.bodySmall.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronEnd, size: 16, color: c.borderStrong),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `/settings/whatsapp/numbers`.
class WaNumbersScreen extends ConsumerWidget {
  const WaNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final ch = ref.watch(whatsAppChannelControllerProvider).channel;
    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: context.l10n.wa_numbers, background: c.backgroundMuted),
      body: ch == null
          ? const WaLoadingBody()
          : ListView(
              padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
              children: [WaNumbersGroup(channel: ch)],
            ),
    );
  }
}
