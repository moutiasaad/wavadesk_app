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
import '../wa_save_feedback.dart';

/// "متقدم" (admin, WhatsApp spec §4.7).
class WaAdvancedGroup extends ConsumerWidget {
  const WaAdvancedGroup({super.key, required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final a = channel.advanced;

    Widget toggle(String title, bool value, WaAdvanced Function(bool v) edit) => _SwitchRow(
          title: title,
          value: value,
          onChanged: (v) => saveWaChange(context, ref, (ctrl) => ctrl.saveAdvanced(edit(v))),
        );

    return SettingsGroup(
      title: l.wa_advanced,
      children: [
        toggle(l.wa_read_receipts, a.sendReadReceipts, (v) => a.copyWith(sendReadReceipts: v)),
        toggle(l.wa_mark_read_open, a.markReadOnOpen, (v) => a.copyWith(markReadOnOpen: v)),
        toggle(l.wa_auto_transcribe, a.autoTranscribeVoice, (v) => a.copyWith(autoTranscribeVoice: v)),
        if (!channel.isCloud) toggle(l.wa_ignore_groups, a.ignoreGroups, (v) => a.copyWith(ignoreGroups: v)),
        SettingsTile(
          icon: AppIcons.block,
          iconColor: c.textError,
          iconBackground: c.errorContainer,
          title: l.wa_blocked,
          onTap: () => _showBlockedSheet(context),
        ),
        SettingsTile(
          icon: AppIcons.clock,
          title: l.wa_hours,
          onTap: () => context.push(Routes.aiAgentHours),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(title, style: context.text.listTitle.copyWith(fontSize: 14.5))),
                AppSwitch(value: value, semanticLabel: title, onChanged: onChanged),
              ],
            ),
          ),
        ),
      );
}

final _blockedProvider = FutureProvider.autoDispose<List<WaBlockedContact>>((ref) => ref.watch(whatsAppApiProvider).blocked());

Future<void> _showBlockedSheet(BuildContext context) => AppBottomSheet.show<void>(
      context,
      title: context.l10n.wa_blocked,
      builder: (_) => const _BlockedList(),
    );

class _BlockedList extends ConsumerWidget {
  const _BlockedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final async = ref.watch(_blockedProvider);
    final rows = async.valueOrNull;
    if (rows == null) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: Center(child: AppSpinner()));
    }
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(l.wa_blocked_empty, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                AppAvatar(name: b.name ?? b.phone, id: b.id, size: AppAvatarSize.sm),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (b.name != null) Text(b.name!, style: t.listTitle.copyWith(fontSize: 14)),
                      Text(formatWaPhone(b.phone), textDirection: TextDirection.ltr, style: t.bodySmall.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                AppButton(
                  label: l.wa_unblock,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    try {
                      await ref.read(whatsAppApiProvider).unblock(b.id);
                      ref.invalidate(_blockedProvider);
                      if (context.mounted) AppSnackbar.show(context, message: l.wa_unblocked, kind: SnackKind.success);
                    } catch (_) {
                      if (context.mounted) AppSnackbar.show(context, message: l.wa_save_failed, kind: SnackKind.error);
                    }
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
