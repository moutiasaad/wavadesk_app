import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/presence_controller.dart';
import 'presence_pill.dart';

/// "حالتك" (spec §4.1): 3 radio rows, optional "حتى…", auto-away note.
Future<void> showPresenceSheet(BuildContext context, {String? gender}) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.dash_presence_title,
    builder: (_) => _PresenceSheetBody(gender: gender),
  );
}

class _PresenceSheetBody extends ConsumerStatefulWidget {
  const _PresenceSheetBody({this.gender});

  final String? gender;

  @override
  ConsumerState<_PresenceSheetBody> createState() => _PresenceSheetBodyState();
}

class _PresenceSheetBodyState extends ConsumerState<_PresenceSheetBody> {
  late Presence _choice = ref.read(presenceControllerProvider).presence;
  PresenceDuration? _duration;

  Future<void> _apply(Presence p, PresenceDuration? d) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.dash_presence_failed;
    Navigator.of(context).pop();
    try {
      await ref.read(presenceControllerProvider.notifier).set(p, duration: d);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final current = ref.watch(presenceControllerProvider);
    final dots = {Presence.online: c.presenceOnline, Presence.busy: c.presenceBusy, Presence.away: c.presenceAway};
    final durations = {
      PresenceDuration.m30: l.dash_presence_30m,
      PresenceDuration.h1: l.dash_presence_1h,
      PresenceDuration.endOfDay: l.dash_presence_eod,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioGroup<Presence>(
            groupValue: _choice,
            onChanged: (p) {
              if (p == null) return;
              setState(() => _choice = p);
              // Online needs no "until": apply at once.
              if (p == Presence.online) _apply(p, null);
            },
            child: Column(
              children: [
                for (final p in Presence.values)
                  RadioListTile<Presence>(
                    value: p,
                    title: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: dots[p], shape: BoxShape.circle)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(presenceLabel(l, p, gender: widget.gender), style: t.listTitle),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
              ],
            ),
          ),
          if (_choice != Presence.online) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
              child: Text(l.dash_presence_until, style: t.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final e in durations.entries)
                    AppFilterChip(
                      label: e.value,
                      selected: _duration == e.key,
                      onTap: () => setState(() => _duration = _duration == e.key ? null : e.key),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              child: AppButton(
                label: MaterialLocalizations.of(context).okButtonLabel,
                expand: true,
                onPressed: _choice == current.presence && _duration == null && current.until == null
                    ? () => Navigator.of(context).pop()
                    : () => _apply(_choice, _duration),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
            child: Text(l.dash_presence_auto, style: t.caption.copyWith(color: c.textTertiary)),
          ),
        ],
      ),
    );
  }
}
