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
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth * 0.85),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
            decoration: BoxDecoration(color: c.bubbleSystem, borderRadius: BorderRadius.circular(AppRadius.full)),
            child: Text(
              text(context, message, meId),
              style: context.text.caption.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
