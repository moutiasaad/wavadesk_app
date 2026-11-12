import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/system_event_formatter.dart';

/// Centered system pill (DS §8.4 `system`, Chat spec §9 copy): `bubbleSystem`
/// bg, `caption` `textSecondary`, radius full, max 85% width.
class SystemEventPill extends StatelessWidget {
  const SystemEventPill({super.key, required this.message, required this.meId});

  final Message message;
  final String meId;

  static String text(BuildContext context, Message m, String meId) {
    final e = m.systemEvent;
    if (e == null) return m.text;
    final l = context.l10n;
    return SystemEventFormatter.format(
      e,
      l: l,
      meId: meId,
      formatTime: (t) => '${AppFormat.date(context, t)} ${AppFormat.time(context, t)}',
      priorityLabel: (name) => Priority.values.where((p) => p.name == name).firstOrNull?.label(l) ?? name,
      channelLabel: (name) => Channel.values.where((c) => c.name == name).firstOrNull?.label(l) ?? name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = c.isDark;
    final e = message.systemEvent;
    // Claim v2 §4.2 / §4.4: the AI handoff pill (teal, spark) and the
    // "you claimed it" pill (green, check); everything else stays neutral.
    final handoff = e?.kind == SystemEventKind.aiHandoff;
    final claimedByMe = e?.kind == SystemEventKind.claimed && (e?.actorId == null || e?.actorId == meId);
    final Color bg;
    final Color fg;
    Color? border;
    IconData? icon;
    if (handoff) {
      bg = dark ? const Color(0xFF0F2E2D) : const Color(0xFFECF7F6);
      border = dark ? const Color(0xFF1D4744) : const Color(0xFFD6EFED);
      fg = dark ? const Color(0xFF5EEAD4) : const Color(0xFF0A5E5B);
      icon = AppIcons.ai;
    } else if (claimedByMe) {
      bg = dark ? const Color(0xFF0F2A1A) : const Color(0xFFE9F9EF);
      fg = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
      icon = AppIcons.check;
    } else {
      bg = c.bubbleSystem;
      fg = c.textSecondary;
    }
    final styled = handoff || claimedByMe;
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth * (styled ? 0.9 : 0.85)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: styled ? 12 : AppSpacing.md, vertical: styled ? 6 : 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: border == null ? null : Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[AppIcon(icon, dp: 12, color: styled && handoff ? c.primary : fg), const SizedBox(width: 5)],
                Flexible(
                  child: Text(
                    text(context, message, meId),
                    style: context.text.caption.copyWith(
                      fontSize: styled ? 12 : null,
                      fontWeight: styled ? FontWeight.w600 : null,
                      color: fg,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
