import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/application/conversation_filters_controller.dart';
import '../../domain/metric_formatters.dart';

/// Server channel key → app [Channel]. Official WhatsApp (wacloud) folds
/// into WhatsApp: the inbox filter can't tell them apart.
Channel dashboardChannel(String key) => switch (key) {
      'whatsapp' || 'wacloud' => Channel.whatsapp,
      'messenger' => Channel.messenger,
      'webchat' || 'web' => Channel.web,
      'instagram' => Channel.instagram,
      'email' => Channel.email,
      'telegram' => Channel.telegram,
      'sms' => Channel.sms,
      _ => Channel.other,
    };

/// "حسب القناة" (Dashboard spec §4.8) — max 5 rows; tap filters the inbox.
class ChannelsBreakdownCard extends ConsumerWidget {
  const ChannelsBreakdownCard({super.key, required this.channels});

  /// Server key → conversations in range.
  final Map<String, int> channels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    final merged = <Channel, int>{};
    for (final e in channels.entries) {
      final ch = dashboardChannel(e.key);
      merged[ch] = (merged[ch] ?? 0) + e.value;
    }
    final rows = (merged.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList();
    final max = rows.isEmpty ? 1 : rows.first.value.clamp(1, 1 << 31);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.dash_by_channel, style: t.h6.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final r in rows)
            Semantics(
              button: true,
              label: '${r.key.label(l)}: ${MetricFormat.grouped(r.value)}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () {
                  Analytics.log('dash_metric_tap', {'metric': 'channel_${r.key.name}'});
                  final filters = ref.read(conversationFiltersProvider.notifier);
                  filters.setSegment(InboxSegment.all);
                  filters.setAdvanced(ref.read(conversationFiltersProvider).advanced.copyWith(channels: {r.key}));
                  context.go(Routes.conversations);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 104,
                        child: Align(alignment: AlignmentDirectional.centerStart, child: ChannelBadge.chip(channel: r.key)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: Container(
                            height: 8,
                            color: c.surfaceVariant,
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: (r.value / max).clamp(0.02, 1.0),
                              child: Container(color: r.key.brand(c).withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        MetricFormat.grouped(r.value),
                        style: t.bodySmall.copyWith(fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
