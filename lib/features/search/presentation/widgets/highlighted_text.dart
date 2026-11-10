import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../application/in_conversation_search_controller.dart' show searchMarkColor;
import '../../domain/snippet_parser.dart';

/// Search-result text with `mark` runs: bg #FDF0C4 (dark #4A3B0B), radius
/// 3, H2 padding, weight +100, colour unchanged (Search spec §6.1).
///
/// Give either server [markup] (`<em>…</em>`) or [text] + a normalized
/// [query] — matching is done on folded text so "توصيل" marks "التوصيل".
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    this.text,
    this.markup,
    this.query = '',
    required this.style,
    this.maxLines = 1,
    this.textDirection,
  }) : assert(text != null || markup != null);

  final String? text;
  final String? markup;
  final String query;
  final TextStyle style;
  final int maxLines;
  final TextDirection? textDirection;

  static FontWeight _heavier(FontWeight? w) {
    final i = ((w ?? FontWeight.w500).value ~/ 100).clamp(1, 9);
    return FontWeight.values[(i).clamp(0, 8)];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = markup != null
        ? SnippetParser.parse(markup!)
        : SnippetParser.parse(SnippetParser.mark(text!, ArabicNormalizer.normalize(query)));
    final weight = _heavier(style.fontWeight);
    final scaler = MediaQuery.textScalerOf(context);
    return Text.rich(
      TextSpan(
        children: [
          for (final p in parts)
            if (!p.hit)
              TextSpan(text: p.text)
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: searchMarkColor(c), borderRadius: BorderRadius.circular(3)),
                  child: Text(
                    p.text,
                    style: style.copyWith(fontWeight: weight),
                    textScaler: scaler,
                  ),
                ),
              ),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textDirection: textDirection,
      // Highlight is visual only (§12).
      semanticsLabel: parts.map((p) => p.text).join(),
    );
  }
}
