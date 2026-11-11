import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../ai_save_feedback.dart';

/// Channel key → label (whatsapp / web / messenger; unknown keys raw).
/// The channels the web panel switches the AI on for.
const aiWebChannels = {'whatsapp', 'web'};

String aiChannelLabel(AppLocalizations l, String key) => switch (key) {
      'whatsapp' => l.ai_channel_whatsapp,
      'web' || 'webchat' => l.ai_channel_web,
      'messenger' => l.ai_channel_messenger,
      _ => key,
    };

/// §4.8 channels where the AI may reply: one switch per channel.
Future<void> showChannelsSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(context, title: context.l10n.ai_channels, builder: (_) => const _ChannelsBody());
}

class _ChannelsBody extends ConsumerWidget {
  const _ChannelsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final l = context.l10n;
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return const SizedBox.shrink();

    void toggle(String key, bool on) {
      Analytics.log('ai_rule_change', {'rule': 'channel_$key', 'value': on});
      saveAiChange(context, ref, (c) => c.copyWith(channels: {...c.channels, key: on}));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in cfg.channels.entries)
            if (aiWebChannels.contains(e.key))
            MergeSemantics(
              child: InkWell(
                onTap: cfg.canEdit ? () => toggle(e.key, !e.value) : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      children: [
                        Expanded(child: Text(aiChannelLabel(l, e.key), style: t.listTitle)),
                        AppSwitch(
                          value: e.value,
                          semanticLabel: aiChannelLabel(l, e.key),
                          onChanged: cfg.canEdit ? (v) => toggle(e.key, v) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
