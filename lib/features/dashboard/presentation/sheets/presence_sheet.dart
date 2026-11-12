import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/presence_controller.dart';
import '../../domain/greeting.dart';
import '../dash_palette.dart';

/// Gendered presence label: متاح / مشغول / غير متاح.
String presenceLabel(AppLocalizations l, Presence p, {String? gender}) {
  final f = Greeting.isFeminine(gender);
  return switch (p) {
    Presence.online => f ? l.dash_presence_online_f : l.dash_presence_online_m,
    Presence.busy => f ? l.dash_presence_busy_f : l.dash_presence_busy_m,
    Presence.away => l.dash_presence_away,
  };
}

Color presenceColor(Presence p) => switch (p) {
      Presence.online => DashPalette.online,
      Presence.busy => DashPalette.busy,
      Presence.away => DashPalette.away,
    };

/// Presence sheet (Dashboard v2 §6.2): 3 radio rows with colored dots.
/// Picking one updates the header at once (optimistic), then the API.
Future<void> showPresenceSheet(BuildContext context, {String? gender}) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.dash_presence_title,
    builder: (_) => _PresenceSheetBody(gender: gender),
  );
}

class _PresenceSheetBody extends ConsumerWidget {
  const _PresenceSheetBody({this.gender});

  final String? gender;

  Future<void> _pick(BuildContext context, WidgetRef ref, Presence p) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.dash_presence_failed;
    Navigator.of(context).pop();
    try {
      await ref.read(presenceControllerProvider.notifier).set(p);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final l = context.l10n;
    final current = ref.watch(presenceControllerProvider).presence;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: RadioGroup<Presence>(
        groupValue: current,
        onChanged: (p) {
          if (p != null) _pick(context, ref, p);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in Presence.values)
              RadioListTile<Presence>(
                value: p,
                title: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: presenceColor(p), shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(presenceLabel(l, p, gender: gender), style: t.listTitle),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
          ],
        ),
      ),
    );
  }
}
