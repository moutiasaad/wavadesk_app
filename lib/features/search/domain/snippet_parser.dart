import '../../../core/utils/arabic_normalizer.dart';

/// One run of snippet text; [hit] runs get the `mark` style.
typedef SnippetPart = ({String text, bool hit});

/// `<em>` markup ↔ spans, and local snippet building (Search spec §6.1).
abstract final class SnippetParser {
  static const context = 40;
  static final _tag = RegExp(r'<em>(.*?)</em>', dotAll: true);

  /// "كم سعر الـ<em>توصيل</em> للدمام؟" → parts. Unknown tags are dropped.
  static List<SnippetPart> parse(String markup) {
    final parts = <SnippetPart>[];
    var last = 0;
    for (final m in _tag.allMatches(markup)) {
      if (m.start > last) parts.add((text: _strip(markup.substring(last, m.start)), hit: false));
      parts.add((text: _strip(m.group(1) ?? ''), hit: true));
      last = m.end;
    }
    if (last < markup.length) parts.add((text: _strip(markup.substring(last)), hit: false));
    return [
      for (final p in parts)
        if (p.text.isNotEmpty) p,
    ];
  }

  static String _strip(String s) => s.replaceAll(RegExp(r'</?[a-z]+>'), '');

  /// Plain text without markers.
  static String plain(String markup) => parse(markup).map((p) => p.text).join();

  /// Wraps every normalized match of [normalizedQuery] in `<em>`.
  static String mark(String text, String normalizedQuery) {
    final ranges = ArabicNormalizer.matchRanges(text, normalizedQuery);
    if (ranges.isEmpty) return text;
    final b = StringBuffer();
    var last = 0;
    for (final (s, e) in ranges) {
      b
        ..write(text.substring(last, s))
        ..write('<em>')
        ..write(text.substring(s, e))
        ..write('</em>');
      last = e;
    }
    b.write(text.substring(last));
    return b.toString();
  }

  /// ±40 chars around the first match with leading/trailing "…", marked.
  static String build(String text, String normalizedQuery) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final first = ArabicNormalizer.matchRange(flat, normalizedQuery);
    if (first == null) return flat.length > context * 2 ? '${flat.substring(0, context * 2)}…' : flat;
    var start = (first.$1 - context).clamp(0, flat.length);
    var end = (first.$2 + context).clamp(0, flat.length);
    // Don't cut words in half.
    while (start > 0 && flat[start - 1] != ' ' && first.$1 - start < context + 12) {
      start--;
    }
    while (end < flat.length && flat[end] != ' ' && end - first.$2 < context + 12) {
      end++;
    }
    final core = mark(flat.substring(start, end).trim(), normalizedQuery);
    return '${start > 0 ? '…' : ''}$core${end < flat.length ? '…' : ''}';
  }
}
