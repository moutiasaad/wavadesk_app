import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/preview_formatter.dart';

/// Preview line under the name (Inbox spec §4.5.2). One line, ellipsis.
class ConversationPreviewText extends StatelessWidget {
  const ConversationPreviewText({super.key, required this.preview, required this.unread, this.highlight});

  final PreviewData preview;
  final bool unread;
  final String? highlight;

  /// Plain-text form for the tile's screen-reader label.
  static String describe(PreviewData p, AppLocalizations l) => switch (p.kind) {
    PreviewKind.typing => l.inbox_typing,
    PreviewKind.draft => '${l.inbox_draft_prefix} ${p.text}',
    PreviewKind.note => '${l.inbox_note_prefix} ${p.text}',
    PreviewKind.mine => '${l.inbox_you_prefix} ${p.text}',
    PreviewKind.colleague => '${p.senderFirstName}: ${p.text}',
    PreviewKind.ai => p.text,
    PreviewKind.image => p.text.isEmpty ? l.inbox_image : p.text,
    PreviewKind.voice => l.inbox_voice(AppFormat.clock(p.duration ?? Duration.zero)),
    PreviewKind.file => p.text,
    PreviewKind.location => l.inbox_location,
    PreviewKind.sticker => l.inbox_sticker,
    PreviewKind.deleted => l.inbox_deleted,
    PreviewKind.text || PreviewKind.empty => p.text,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final base = t.listSubtitle.copyWith(
      color: unread ? c.textPrimary : c.textSecondary,
      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
    );

    if (preview.kind == PreviewKind.typing) {
      return Row(
        children: [
          Flexible(
            child: Text(
              l.inbox_typing,
              style: base.copyWith(color: c.primary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const _TypingDots(),
        ],
      );
    }

    InlineSpan icon(IconData data, {Color? color}) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
        child: Icon(data, size: 13, color: color ?? c.textSecondary),
      ),
    );

    final spans = <InlineSpan>[];
    void body(String text, {TextStyle? style}) => spans.addAll(_highlighted(text, style ?? base, c));

    switch (preview.kind) {
      case PreviewKind.draft:
        spans.add(
          TextSpan(
            text: '${l.inbox_draft_prefix} ',
            style: base.copyWith(color: c.textError, fontWeight: FontWeight.w700),
          ),
        );
        body(preview.text);
      case PreviewKind.note:
        spans
          ..add(icon(AppIcons.note))
          ..add(
            TextSpan(
              text: '${l.inbox_note_prefix} ',
              style: base.copyWith(color: c.textSecondary),
            ),
          );
        body(preview.text, style: base.copyWith(color: c.textSecondary));
      case PreviewKind.mine:
        spans
          ..add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: DeliveryTicks(state: preview.delivery ?? DeliveryState.sent),
              ),
            ),
          )
          ..add(TextSpan(text: '${l.inbox_you_prefix} '));
        body(preview.text);
      case PreviewKind.colleague:
        spans.add(TextSpan(text: '${preview.senderFirstName}: '));
        body(preview.text);
      case PreviewKind.ai:
        spans.add(icon(AppIcons.sparkle, color: c.primary));
        body(preview.text);
      case PreviewKind.image:
        spans.add(icon(AppIcons.image));
        body(preview.text.isEmpty ? l.inbox_image : preview.text);
      case PreviewKind.voice:
        spans
          ..add(icon(AppIcons.mic, color: c.primary))
          ..add(TextSpan(text: l.inbox_voice(AppFormat.clock(preview.duration ?? Duration.zero))));
      case PreviewKind.file:
        spans.add(icon(AppIcons.file));
        body(preview.text);
      case PreviewKind.location:
        spans
          ..add(icon(AppIcons.location))
          ..add(TextSpan(text: l.inbox_location));
      case PreviewKind.sticker:
        spans.add(TextSpan(text: l.inbox_sticker));
      case PreviewKind.deleted:
        spans.add(
          TextSpan(
            text: l.inbox_deleted,
            style: base.copyWith(color: c.textTertiary),
          ),
        );
      case PreviewKind.text:
      case PreviewKind.empty:
        body(preview.text);
      case PreviewKind.typing:
        break;
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _highlighted(String text, TextStyle style, AppColors c) {
    final q = highlight?.trim() ?? '';
    if (q.isEmpty) return [TextSpan(text: text, style: style)];
    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final out = <InlineSpan>[];
    var start = 0;
    while (true) {
      final i = lower.indexOf(needle, start);
      if (i < 0) break;
      if (i > start) out.add(TextSpan(text: text.substring(start, i), style: style));
      out.add(
        TextSpan(
          text: text.substring(i, i + needle.length),
          style: style.copyWith(background: Paint()..color = c.searchHighlight),
        ),
      );
      start = i + needle.length;
    }
    if (start < text.length) out.add(TextSpan(text: text.substring(start), style: style));
    return out;
  }
}

/// Delivery ticks, 16dp (Inbox spec §4.5.2; read → `accent`).
class DeliveryTicks extends StatelessWidget {
  const DeliveryTicks({super.key, required this.state, this.size = 16});

  final DeliveryState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (IconData icon, Color color) = switch (state) {
      DeliveryState.sending => (AppIcons.clock, c.textTertiary),
      DeliveryState.sent => (AppIcons.check, c.textTertiary),
      DeliveryState.delivered => (AppIcons.checkDouble, c.textTertiary),
      DeliveryState.read => (AppIcons.checkDouble, c.accent),
      DeliveryState.failed => (AppIcons.alert, c.error),
    };
    return Icon(icon, size: size, color: color);
  }
}

/// Three 3dp dots in a 12dp box, looping (typing is one of the two allowed
/// loops, DS §2). Static under reduce-motion.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: AppMotion.loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.reduced(context) ? _ctrl.stop() : _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: 0.35 + 0.65 * (((_ctrl.value * 3) - i) % 3 < 1 ? 1 : 0),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
