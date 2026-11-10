import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/arabic_normalizer.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../search/application/in_conversation_search_controller.dart';

/// Bubble text (Chat spec §4.4): `chatMessage`, URLs / phones / emails
/// auto-linked (underlined, same color), direction auto-detected from the
/// first strong character, LTR fragments bidi-isolated.
class TextContent extends StatefulWidget {
  const TextContent({
    super.key,
    required this.text,
    required this.color,
    this.maxLines,
    this.mentions = const [],
    this.searchQuery = '',
  });

  final String text;
  final Color color;
  final int? maxLines;

  /// @mentions rendered bold in `textWarning` (internal notes).
  final List<String> mentions;

  /// Normalized in-conversation search query: matches get the `mark`
  /// style (Search spec §11, §6.1).
  final String searchQuery;

  /// First strong character decides the bubble's direction (§11).
  static TextDirection directionOf(String text) {
    for (final r in text.runes) {
      if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFEFC)) return TextDirection.rtl;
      if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A) || (r >= 0xC0 && r <= 0x24F)) {
        return TextDirection.ltr;
      }
    }
    return TextDirection.rtl;
  }

  static final _emojiRune = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{1F3FB}-\u{1F3FF}]',
    unicode: true,
  );

  /// 1–3 emoji and nothing else → large emoji, no bubble (§4.4).
  static bool isEmojiOnly(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    final glyphs = t.characters.where((g) => g.trim().isNotEmpty).toList();
    if (glyphs.isEmpty || glyphs.length > 3) return false;
    return glyphs.every((g) => g.runes.every((r) => _emojiRune.hasMatch(String.fromCharCode(r))));
  }

  @override
  State<TextContent> createState() => _TextContentState();
}

class _TextContentState extends State<TextContent> {
  final _recognizers = <TapGestureRecognizer>[];

  static final _link = RegExp(r'(https?://[^\s]+|www\.[^\s]+)|([\w.+-]+@[\w-]+\.[\w.]+)|(\+?\d[\d\s-]{6,}\d)');

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _tap(Uri uri) {
    final r = TapGestureRecognizer()..onTap = () => launchUrl(uri, mode: LaunchMode.externalApplication);
    _recognizers.add(r);
    return r;
  }

  List<InlineSpan> _spans(TextStyle base) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final c = context.colors;
    final text = widget.text;
    final spans = <InlineSpan>[];
    var start = 0;

    final markBg = searchMarkColor(c);
    // Highlighted runs keep the text color, +100 weight (§6.1).
    void marked(String s, [TextStyle? style]) {
      final ranges = ArabicNormalizer.matchRanges(s, widget.searchQuery);
      if (ranges.isEmpty) {
        spans.add(TextSpan(text: s, style: style));
        return;
      }
      var i = 0;
      for (final (a, b) in ranges) {
        if (a > i) spans.add(TextSpan(text: s.substring(i, a), style: style));
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: markBg, borderRadius: BorderRadius.circular(3)),
              child: Text(s.substring(a, b), style: base.merge(style).copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        );
        i = b;
      }
      if (i < s.length) spans.add(TextSpan(text: s.substring(i), style: style));
    }

    void plain(String s) {
      if (s.isEmpty) return;
      if (widget.mentions.isEmpty) {
        marked(s);
        return;
      }
      // Bold @mentions.
      final re = RegExp(widget.mentions.map((m) => RegExp.escape('@$m')).join('|'));
      var i = 0;
      for (final m in re.allMatches(s)) {
        if (m.start > i) marked(s.substring(i, m.start));
        spans.add(
          TextSpan(
            text: m.group(0),
            style: TextStyle(fontWeight: FontWeight.w700, color: c.textWarning),
          ),
        );
        i = m.end;
      }
      if (i < s.length) marked(s.substring(i));
    }

    for (final m in _link.allMatches(text)) {
      plain(text.substring(start, m.start));
      final raw = m.group(0)!;
      final uri = m.group(1) != null
          ? Uri.parse(raw.startsWith('http') ? raw : 'https://$raw')
          : m.group(2) != null
          ? Uri(scheme: 'mailto', path: raw)
          : Uri(scheme: 'tel', path: raw.replaceAll(RegExp(r'[\s-]'), ''));
      // LTR fragment inside RTL text: isolate (§11).
      spans.add(
        TextSpan(
          text: ltr(raw),
          style: const TextStyle(decoration: TextDecoration.underline),
          recognizer: _tap(uri),
        ),
      );
      start = m.end;
    }
    plain(text.substring(start));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final style = context.text.chatMessage.copyWith(color: widget.color);
    return Text.rich(
      TextSpan(style: style, children: _spans(style)),
      textDirection: TextContent.directionOf(widget.text),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
