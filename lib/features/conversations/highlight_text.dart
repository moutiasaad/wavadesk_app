import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Text with case-insensitive [query] matches highlighted (§8.12: bg
/// `searchHighlight`, radius 3).
class HighlightText extends StatelessWidget {
  const HighlightText(this.text, {super.key, required this.style, this.query, this.maxLines = 1});

  final String text;
  final TextStyle style;
  final String? query;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final q = query?.trim() ?? '';
    if (q.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final i = lower.indexOf(needle, start);
      if (i < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            decoration: BoxDecoration(color: context.colors.searchHighlight, borderRadius: BorderRadius.circular(3)),
            child: Text(text.substring(i, i + needle.length), style: style),
          ),
        ),
      );
      start = i + needle.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Shortens [text] around the first match so the match stays visible.
String snippetAround(String text, String query, {int lead = 24}) {
  final i = text.toLowerCase().indexOf(query.trim().toLowerCase());
  if (i <= lead) return text;
  return '…${text.substring(i - lead)}';
}
