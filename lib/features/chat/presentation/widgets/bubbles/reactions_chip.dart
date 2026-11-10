import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// Emoji reactions under a bubble (Chat spec §4.4): h22, radius full,
/// `surface` + `border`; positioned by the bubble to overlap its
/// bottom-start corner by 8dp.
class ReactionsChip extends StatelessWidget {
  const ReactionsChip({super.key, required this.reactions});

  final List<Reaction> reactions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final emojis = <String, int>{};
    for (final r in reactions) {
      emojis[r.emoji] = (emojis[r.emoji] ?? 0) + 1;
    }
    final text = [for (final e in emojis.entries) e.value > 1 ? '${e.key}${e.value}' : e.key].join(' ');
    return Semantics(
      label: context.l10n.bubble_reactions(emojis.keys.join(' ')),
      excludeSemantics: true,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, height: 1),
          textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        ),
      ),
    );
  }
}
