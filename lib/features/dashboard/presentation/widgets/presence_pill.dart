import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../application/presence_controller.dart';
import '../../domain/greeting.dart';
import 'presence_sheet.dart';

/// Gendered presence label (spec §4.1 / §10).
String presenceLabel(AppLocalizations l, Presence p, {String? gender}) {
  final f = Greeting.isFeminine(gender);
  return switch (p) {
    Presence.online => f ? l.dash_presence_online_f : l.dash_presence_online_m,
    Presence.busy => f ? l.dash_presence_busy_f : l.dash_presence_busy_m,
    Presence.away => l.dash_presence_away,
  };
}

/// Header status chip (h36, radius full, dot 8 + label) → presence sheet.
class PresencePill extends ConsumerWidget {
  const PresencePill({super.key, this.gender});

  final String? gender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = ref.watch(presenceControllerProvider).presence;
    final dark = c.isDark;

    final (bg, border, fg, dot) = switch (p) {
      Presence.online => (
          dark ? const Color(0xFF0F2A1A) : const Color(0xFFE9F9EF),
          dark ? const Color(0xFF1E4D30) : const Color(0xFFC7EFD6),
          dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
          c.presenceOnline,
        ),
      Presence.busy => (c.warningContainer, c.warningContainer, dark ? c.textWarning : const Color(0xFFB45309), c.presenceBusy),
      Presence.away => (c.surfaceVariant, c.surfaceVariant, c.textSecondary, c.presenceAway),
    };
    final label = presenceLabel(l, p, gender: gender);

    return Semantics(
      button: true,
      label: l.dash_a11y_presence(label),
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showPresenceSheet(context, gender: gender),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(label, style: t.chipLabel.copyWith(color: fg)),
                  const SizedBox(width: 2),
                  AppIcon(AppIcons.chevronDown, size: AppIconSize.sm, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
