import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../dashboard/application/presence_controller.dart';
import '../../dashboard/presentation/dash_palette.dart';
import 'account_online.dart';
import 'account_sheets.dart';

/// "حالتي" card (Account §4.2): 3-way segmented متاح · مشغول · غير متاح.
/// Optimistic (header dot + dashboard subline follow at once), reverted with
/// a snackbar when `PUT me/presence` fails. Going away with open chats asks
/// what to do with them first.
class PresenceCard extends ConsumerWidget {
  const PresenceCard({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref, Presence next) async {
    final l = context.l10n;
    if (next == ref.read(presenceControllerProvider).presence) return;
    if (!(ref.read(accountOnlineProvider).valueOrNull ?? true)) {
      AppSnackbar.show(context, message: l.acc_offline_presence, kind: SnackKind.error);
      return;
    }
    if (next == Presence.away) {
      final open = await myOpenChatsCount(ref);
      if (!context.mounted) return;
      if (open > 0) {
        final choice = await showAwayOpenChatsSheet(context, count: open);
        if (choice == null || !context.mounted) return;
        if (choice == AwayChoice.release) unawaitedRelease(context, ref);
      }
    }
    try {
      await ref.read(presenceControllerProvider.notifier).set(next);
    } catch (_) {
      if (context.mounted) AppSnackbar.show(context, message: l.acc_presence_failed, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    final presence = ref.watch(presenceControllerProvider).presence;
    final reduced = AppMotion.reduced(context);
    final dark = c.isDark;

    (Color, Color) active(Presence v) => switch (v) {
      Presence.online =>
        dark ? (const Color(0xFF0F2A1A), const Color(0xFF4ADE80)) : (const Color(0xFFE9F9EF), const Color(0xFF15803D)),
      Presence.busy =>
        dark ? (const Color(0xFF2A2010), const Color(0xFFFBBF24)) : (const Color(0xFFFEF3E2), const Color(0xFFB45309)),
      Presence.away =>
        dark ? (const Color(0xFF1C272C), const Color(0xFF93A3AB)) : (const Color(0xFFEEF2F5), const Color(0xFF475569)),
    };
    const order = [Presence.online, Presence.busy, Presence.away];
    String label(Presence v) => switch (v) {
      Presence.online => l.presence_online,
      Presence.busy => l.presence_busy,
      Presence.away => l.presence_away,
    };
    final index = order.indexOf(presence);
    final (selBg, _) = active(presence);
    final big = MediaQuery.textScalerOf(context).scale(10) >= 20;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.acc_my_status,
            style: t.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: l.acc_my_status,
            container: true,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1A2428) : const Color(0xFFF3F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  const gap = 4.0;
                  final w = (box.maxWidth - gap * 2) / 3;
                  final h = big ? 48.0 : 36.0;
                  return SizedBox(
                    height: h,
                    child: Stack(
                      children: [
                        // The active pill slides between segments (200ms).
                        AnimatedPositionedDirectional(
                          duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          start: index * (w + gap),
                          top: 0,
                          width: w,
                          height: h,
                          child: AnimatedContainer(
                            duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
                            decoration: BoxDecoration(color: selBg, borderRadius: BorderRadius.circular(9)),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < order.length; i++) ...[
                              if (i > 0) const SizedBox(width: gap),
                              SizedBox(
                                width: w,
                                height: h,
                                child: Semantics(
                                  inMutuallyExclusiveGroup: true,
                                  checked: order[i] == presence,
                                  button: true,
                                  label: label(order[i]),
                                  excludeSemantics: true,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(9),
                                    onTap: () => _pick(context, ref, order[i]),
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
                                        style: t.bodyMedium.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: order[i] == presence ? active(order[i]).$2 : c.textSecondary,
                                        ),
                                        child: Text(label(order[i]), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Open conversations assigned to me (`conversations/count?segment=mine`);
/// 0 when the count can't be read.
Future<int> myOpenChatsCount(WidgetRef ref) async {
  try {
    final r = await ref.read(wdApiRequiredProvider).get('conversations/count', query: {'segment': 'mine'});
    return (r.map['count'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
}

/// "إعادتها لغير المُسندة": unassign my open chats (first 50) in one bulk call.
void unawaitedRelease(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  () async {
    try {
      final api = ref.read(wdApiRequiredProvider);
      final r = await api.get('conversations', query: {'segment': 'mine', 'limit': 50});
      final ids = [for (final row in r.list) '${row['id']}'];
      if (ids.isEmpty) return;
      await api.post('conversations/bulk', body: {'action': 'unassign', 'ids': ids});
      if (context.mounted) AppSnackbar.show(context, message: l.acc_released(ids.length), kind: SnackKind.success);
    } catch (_) {
      if (context.mounted) AppSnackbar.show(context, message: l.acc_presence_failed, kind: SnackKind.error);
    }
  }();
}
