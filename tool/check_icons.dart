// Icon Library guard (§5, §10): every icon goes through AppIcons + AppIcon.
//
//   dart run tool/check_icons.dart
//
// Fails (exit 1) when lib/ outside lib/core/icons/ uses an icon set directly
// (`Icons.`, `CupertinoIcons.`, `LucideIcons.`, `SimpleIcons.`,
// `FontAwesomeIcons.`) or draws a raw `Icon(` instead of `AppIcon(`.
import 'dart:io';

final _forbidden = RegExp(r'(?<![A-Za-z_$.])(Icons|CupertinoIcons|LucideIcons|SimpleIcons|FontAwesomeIcons)\.');
final _rawIcon = RegExp(r'(?<![A-Za-z_$.])Icon\(');

void main() {
  final hits = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/core/icons/') || path.startsWith('lib/l10n/')) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//')) continue;
      if (_forbidden.hasMatch(line) || _rawIcon.hasMatch(line)) hits.add('$path:${i + 1}: ${line.trim()}');
    }
  }
  if (hits.isEmpty) {
    stdout.writeln('check_icons: OK — all icons go through AppIcons/AppIcon.');
    return;
  }
  stderr.writeln('check_icons: ${hits.length} direct icon use(s) outside lib/core/icons/:');
  hits.forEach(stderr.writeln);
  exit(1);
}
