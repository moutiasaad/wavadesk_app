import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/close_titles_controller.dart';
import '../../domain/wa_channel.dart';

/// "الرسائل التلقائية" (WhatsApp spec §4.4). The welcome and away-message
/// rows were removed at the user's request; quick replies, closing titles
/// and the knowledge base live here.
class WaAutoMessagesGroup extends ConsumerWidget {
  const WaAutoMessagesGroup({super.key, required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final titles = ref.watch(closeTitlesControllerProvider);
    final kbCount = ref.watch(knowledgeProvider).length;
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
        SettingsTile(
          icon: AppIcons.resolve,
          iconColor: c.textSuccess,
          iconBackground: c.successContainer,
          title: l.wa_ct_title,
          value: titles.loaded ? '${titles.items.length}' : null,
          onTap: () => context.push(Routes.whatsappCloseTitles),
        ),
        SettingsTile(
          icon: AppIcons.kb,
          iconColor: c.primary,
          iconBackground: c.primaryContainer,
          title: l.wa_kb_row,
          value: kbCount > 0 ? '$kbCount' : null,
          onTap: () => context.go(Routes.knowledge),
        ),
      ],
    );
  }
}
