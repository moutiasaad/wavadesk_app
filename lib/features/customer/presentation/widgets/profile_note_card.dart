import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../chat/presentation/widgets/context_strip.dart' show DashedRRectPainter;
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../domain/contact_note.dart';

/// Team note card (§5.5): internal-note style — amber bg, dashed border
/// (pinned: stronger `#E9C46A`), radius 14, padding 10/12, mentions bold,
/// footer "{author} · {date}" + pin icon.
class ProfileNoteCard extends StatelessWidget {
  const ProfileNoteCard({super.key, required this.note, this.onLongPress, this.actions = const {}});

  final ContactNote note;
  final VoidCallback? onLongPress;

  /// Long-press actions exposed as semantic custom actions.
  final Map<CustomSemanticsAction, VoidCallback> actions;

  static const _pinnedBorder = Color(0xFFE9C46A);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final date = RelativeTimeFormatter.dayMonth(note.createdAt, DateTime.now(), context.localeName);
    final style = t.bodySmall.copyWith(fontSize: 13, color: c.noteForeground);
    final border = note.pinned ? (c.isDark ? c.textWarning : _pinnedBorder) : c.noteBorder;

    return Semantics(
      label: l.profile_note_a11y(note.authorName, date, note.text),
      customSemanticsActions: actions,
      excludeSemantics: true,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: CustomPaint(
          painter: DashedRRectPainter(color: border, radius: AppRadius.lg, strokeWidth: note.pinned ? 1.5 : 1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(color: c.noteBackground, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: _spans(note, style, c)), style: style),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (note.pinned) ...[
                      AppIcon(AppIcons.pin, size: AppIconSize.xs, color: c.noteForeground.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        '${note.authorName} · $date',
                        style: t.caption.copyWith(fontSize: 11.5, color: c.noteForeground.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "@name" for each mention → bold.
  static List<InlineSpan> _spans(ContactNote note, TextStyle style, AppColors c) {
    if (note.mentions.isEmpty) return [TextSpan(text: note.text)];
    final pattern = RegExp(note.mentions.map((m) => RegExp.escape('@$m')).join('|'));
    final out = <InlineSpan>[];
    var start = 0;
    for (final m in pattern.allMatches(note.text)) {
      if (m.start > start) out.add(TextSpan(text: note.text.substring(start, m.start)));
      out.add(TextSpan(text: m.group(0), style: style.copyWith(fontWeight: FontWeight.w800)));
      start = m.end;
    }
    if (start < note.text.length) out.add(TextSpan(text: note.text.substring(start)));
    return out;
  }
}
