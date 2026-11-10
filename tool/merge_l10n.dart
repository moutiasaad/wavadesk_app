// Merges the per-feature ARB fragments in `l10n_parts/` into
// `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`, then the Flutter tool
// generates `AppLocalizations` from them.
//
//   dart run tool/merge_l10n.dart && flutter gen-l10n
//
// Fragments are named `<feature>.<locale>.arb`. Keys follow
// `feature_element_description` (Design System §12.3). A key defined in two
// fragments, or present in one locale but not the other, fails the merge.
import 'dart:convert';
import 'dart:io';

void main() {
  const locales = ['ar', 'en'];
  final parts = Directory('l10n_parts')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final merged = <String, Map<String, dynamic>>{
    for (final l in locales) l: {'@@locale': l},
  };
  final owner = <String, Map<String, String>>{for (final l in locales) l: {}};
  var failed = false;

  for (final file in parts) {
    final name = file.uri.pathSegments.last;
    final segs = name.split('.');
    final locale = segs[segs.length - 2];
    if (!locales.contains(locale)) continue;
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    data.forEach((key, value) {
      if (key.startsWith('@@')) return;
      final prev = owner[locale]![key];
      if (prev != null) {
        stderr.writeln('Duplicate key "$key" in $name (already in $prev)');
        failed = true;
        return;
      }
      owner[locale]![key] = name;
      merged[locale]![key] = value;
    });
  }

  final arKeys = merged['ar']!.keys.where((k) => !k.startsWith('@')).toSet();
  final enKeys = merged['en']!.keys.where((k) => !k.startsWith('@')).toSet();
  for (final k in arKeys.difference(enKeys)) {
    stderr.writeln('Missing English translation: $k (${owner['ar']![k]})');
    failed = true;
  }
  for (final k in enKeys.difference(arKeys)) {
    stderr.writeln('Missing Arabic translation: $k (${owner['en']![k]})');
    failed = true;
  }
  if (failed) exit(1);

  const encoder = JsonEncoder.withIndent('  ');
  Directory('lib/l10n').createSync(recursive: true);
  for (final l in locales) {
    File('lib/l10n/app_$l.arb').writeAsStringSync('${encoder.convert(merged[l])}\n');
  }
  stdout.writeln('Merged ${parts.length} fragments → ${arKeys.length} keys per locale.');
}
