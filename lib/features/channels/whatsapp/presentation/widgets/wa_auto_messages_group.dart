import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/wa_channel.dart';
import '../wa_save_feedback.dart';

String waDelayLabel(AppLocalizations l, int s) => switch (s) {
      0 => l.wa_now,
      30 => l.wa_delay_30s,
      60 => l.wa_delay_1m,
      120 => l.wa_delay_2m,
      300 => l.wa_delay_5m,
      _ => '$s s',
    };

String _preview(String s, int n) {
  final one = s.replaceAll('\n', ' ').trim();
  return one.length <= n ? one : '${one.substring(0, n)}…';
}

/// "الرسائل التلقائية" (WhatsApp spec §4.4).
class WaAutoMessagesGroup extends ConsumerWidget {
  const WaAutoMessagesGroup({super.key, required this.channel});

  final WaChannel channel;

  Future<void> _toggleWelcome(BuildContext context, WidgetRef ref, bool v) {
    final l = context.l10n;
    final before = channel.welcome;
    Analytics.log('wa_auto_toggle', {'kind': 'welcome', 'enabled': v});
    return saveWaChange(
      context,
      ref,
      (c) => c.saveWelcome(before.copyWith(enabled: v)),
      successMessage: v ? l.wa_welcome_on : l.wa_welcome_off,
      onUndo: () => saveWaChange(context, ref, (c) => c.saveWelcome(before)),
    );
  }

  Future<void> _toggleAway(BuildContext context, WidgetRef ref, bool v) {
    final l = context.l10n;
    final before = channel.away;
    Analytics.log('wa_auto_toggle', {'kind': 'away', 'enabled': v});
    return saveWaChange(
      context,
      ref,
      (c) => c.saveAway(before.copyWith(enabled: v)),
      successMessage: v ? l.wa_away_on : l.wa_away_off,
      onUndo: () => saveWaChange(context, ref, (c) => c.saveAway(before)),
    );
  }

  Future<void> _delaySheet(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final current = channel.welcome.delaySeconds;
    final picked = await AppBottomSheet.show<int>(
      context,
      title: l.wa_welcome_delay,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in const [0, 30, 60, 120, 300])
            AppRadioRow(label: waDelayLabel(l, s), selected: s == current, onTap: () => Navigator.of(ctx).pop(s)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
    if (picked == null || picked == current || !context.mounted) return;
    await saveWaChange(context, ref, (c) => c.saveWelcome(channel.welcome.copyWith(delaySeconds: picked)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final pending = channel.isPending;
    final canEdit = channel.permissions.canEditAuto && !pending;
    final away = channel.away;
    final welcome = channel.welcome;

    final welcomeSub = pending ? l.wa_enable_after : (welcome.text.isEmpty ? null : _preview(welcome.text, 40));
    final awaySub = pending ? l.wa_enable_after : (away.handledByAi ? l.wa_away_ai : (away.text.isEmpty ? null : _preview(away.text, 40)));

    final awaySwitch = AppSwitch(
      value: away.enabled && !away.handledByAi,
      semanticLabel: l.wa_away,
      onChanged: canEdit && !away.handledByAi ? (v) => _toggleAway(context, ref, v) : null,
    );

    return Opacity(
      opacity: pending ? 0.6 : 1,
      child: SettingsGroup(
        title: l.wa_auto,
        children: [
          SettingsTile(
            icon: AppIcons.conversation,
            title: l.wa_welcome,
            subtitle: welcomeSub,
            trailing: AppSwitch(
              value: welcome.enabled,
              semanticLabel: l.wa_welcome,
              onChanged: canEdit ? (v) => _toggleWelcome(context, ref, v) : null,
            ),
            onTap: pending ? null : () => context.push(Routes.whatsappWelcome),
          ),
          SettingsTile(
            icon: AppIcons.clock,
            iconColor: c.textWarning,
            iconBackground: c.warningContainer,
            title: l.wa_away,
            subtitle: awaySub,
            trailing: away.handledByAi ? Tooltip(message: l.wa_away_ai_banner, child: awaySwitch) : awaySwitch,
            onTap: pending ? null : () => context.push(Routes.whatsappAway),
          ),
          SettingsTile(
            icon: AppIcons.send,
            iconColor: c.textInfo,
            iconBackground: c.infoContainer,
            title: l.wa_quick,
            value: '${channel.quickRepliesCount}',
            onTap: () => context.push(Routes.whatsappQuickReplies),
          ),
          if (welcome.enabled && !pending)
            SettingsTile(
              icon: AppIcons.waiting,
              iconColor: c.textSecondary,
              iconBackground: c.surfaceVariant,
              title: l.wa_welcome_delay,
              value: waDelayLabel(l, welcome.delaySeconds),
              onTap: canEdit ? () => _delaySheet(context, ref) : null,
            ),
        ],
      ),
    );
  }
}
