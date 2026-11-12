import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/wa_channel.dart';

/// "الرسائل التلقائية" (WhatsApp spec §4.4). The welcome and away-message
/// rows were removed at the user's request; quick replies stay.
class WaAutoMessagesGroup extends StatelessWidget {
  const WaAutoMessagesGroup({super.key, required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return SettingsGroup(
      title: l.wa_auto,
      children: [
        SettingsTile(
          icon: AppIcons.send,
          iconColor: c.textInfo,
          iconBackground: c.infoContainer,
          title: l.wa_quick,
          value: '${channel.quickRepliesCount}',
          onTap: () => context.push(Routes.whatsappQuickReplies),
        ),
      ],
    );
  }
}
