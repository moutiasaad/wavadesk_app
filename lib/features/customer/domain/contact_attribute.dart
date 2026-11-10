import 'package:flutter/foundation.dart';

enum AttributeType { text, number, date, bool, url, select }

/// Workspace-defined custom attribute (Profile spec §5.6, §9 `attributes`).
@immutable
class ContactAttribute {
  const ContactAttribute({required this.key, required this.label, required this.type, this.value});

  final String key;
  final String label;
  final AttributeType type;

  /// String / num / bool / ISO date string, per [type].
  final Object? value;

  bool get isEmpty => value == null || (value is String && (value as String).trim().isEmpty);

  ContactAttribute withValue(Object? v) => ContactAttribute(key: key, label: label, type: type, value: v);

  factory ContactAttribute.fromJson(Map<String, dynamic> j) => ContactAttribute(
        key: '${j['key']}',
        label: (j['label'] as String?) ?? '${j['key']}',
        type: AttributeType.values.firstWhere((t) => t.name == j['type'], orElse: () => AttributeType.text),
        value: j['value'],
      );

  Map<String, Object?> toJson() => {'key': key, 'label': label, 'type': type.name, 'value': value};

  /// Type-aware display: bool ✓/✗, date `d/M/yyyy`, number as-is.
  String display({required String yes, required String no}) {
    final v = value;
    if (v == null) return '';
    return switch (type) {
      AttributeType.bool => v == true || v == 'true' ? '✓ $yes' : '✗ $no',
      AttributeType.date => () {
          final d = DateTime.tryParse('$v');
          return d == null ? '$v' : '${d.day}/${d.month}/${d.year}';
        }(),
      _ => '$v',
    };
  }
}
