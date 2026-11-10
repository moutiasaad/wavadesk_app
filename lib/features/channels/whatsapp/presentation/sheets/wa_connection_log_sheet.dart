import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/state/load_state.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';

final _logProvider = FutureProvider.autoDispose<List<WaLogEntry>>((ref) async {
  ref.cacheFor(const Duration(minutes: 2)); // reopening the sheet is instant
  final (rows, _) = await ref.watch(whatsAppApiProvider).log();
  return rows;
});

/// Connection log, last 30 days (WhatsApp spec §6.4).
Future<void> showWaConnectionLogSheet(BuildContext context) => AppBottomSheet.show<void>(
      context,
      title: context.l10n.wa_log,
      builder: (_) => const _Log(),
    );

class _Log extends ConsumerWidget {
  const _Log();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final async = ref.watch(_logProvider);
    if (async.hasError && !async.hasValue) {
      return EmptyState(icon: AppIcons.alert, title: l.wa_load_error, actionLabel: l.wa_retry, onAction: () => ref.invalidate(_logProvider));
    }
    final rows = async.valueOrNull;
    if (rows == null) return const SizedBox(height: 140, child: Center(child: AppSpinner()));
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(l.wa_log_empty, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
      );
    }

    String reason(String? r) => switch (r) {
          'phone_offline' => l.wa_reason_phone_offline,
          'logged_out' => l.wa_reason_logged_out,
          'update' => l.wa_reason_update,
          null || 'other' => '',
          _ => r,
        };

    (Color, String, String?) describe(WaLogEntry e) => switch (e.kind) {
          WaLogKind.connected => (c.success, e.by == null ? l.wa_log_connected : l.wa_log_connected_by(e.by!), null),
          WaLogKind.disconnected => (
              c.error,
              l.wa_log_disconnected(e.durationSeconds == null ? '—' : AppFormat.shortDuration(context, Duration(seconds: e.durationSeconds!))),
              e.reason == null ? null : reason(e.reason),
            ),
          WaLogKind.disconnectedBy => (c.error, e.by == null ? l.wa_disconnected : l.wa_log_disconnected_by(e.by!), null),
          WaLogKind.connectStarted => (c.textTertiary, e.by == null ? l.wa_log_connect_started : l.wa_log_connect_started_by(e.by!), null),
          WaLogKind.reconnected => (c.primary, e.by == null ? l.wa_log_reconnected : l.wa_log_reconnected_by(e.by!), null),
          WaLogKind.recovered => (c.info, l.wa_log_recovered('${e.count ?? 0}'), null),
          WaLogKind.other => (c.textTertiary, e.reason ?? '—', null),
        };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++)
            Builder(builder: (context) {
              final e = rows[i];
              final (dot, title, sub) = describe(e);
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                          if (i < rows.length - 1) Expanded(child: Container(width: 2, color: c.divider)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                            if (sub != null && sub.isNotEmpty) Text(sub, style: t.bodySmall.copyWith(color: c.textSecondary)),
                            Text(
                              '${AppFormat.dayLabel(context, e.at)} · ${AppFormat.time(context, e.at)}',
                              style: t.caption.copyWith(color: c.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
