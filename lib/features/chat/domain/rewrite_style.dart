import 'package:flutter/widgets.dart';

import '../../../core/theme/app_icons.dart';
import '../../../l10n/app_localizations.dart';

/// A rewrite style (Rewrite spec §5.4). Built-ins carry a fixed [id] that is
/// sent as `style`; workspace styles defined by admins carry their own id and
/// a server-provided [customLabel].
@immutable
class RewriteStyle {
  const RewriteStyle._(this.id, {this.icon, this.allowedInNote = false}) : customLabel = null;

  const RewriteStyle.custom({required this.id, required String label})
    : icon = null,
      allowedInNote = false,
      customLabel = label;

  final String id;
  final IconData? icon;

  /// Notes only get the non-tone styles: أقصر · صحّح الإملاء · ترجم (§2).
  final bool allowedInNote;

  /// Workspace ("أساليب فريقك") styles only.
  final String? customLabel;

  bool get isCustom => customLabel != null;
  bool get isTranslate => id == translate.id;

  // Chips, in mockup order (§5.4).
  static const professional = RewriteStyle._('professional', icon: AppIcons.briefcase);
  static const shorter = RewriteStyle._('shorter', icon: AppIcons.minus, allowedInNote: true);
  static const friendlier = RewriteStyle._('friendlier', icon: AppIcons.smile);
  static const apology = RewriteStyle._('apology', icon: AppIcons.heartHandshake);
  static const fix = RewriteStyle._('fix', icon: AppIcons.spellCheck, allowedInNote: true);
  static const translate = RewriteStyle._('translate', icon: AppIcons.language, allowedInNote: true);

  // "المزيد ▾" menu (§5.4.2).
  static const formal = RewriteStyle._('formal');
  static const saudi = RewriteStyle._('saudi');
  static const msa = RewriteStyle._('msa');
  static const greeting = RewriteStyle._('greeting');
  static const bullets = RewriteStyle._('bullets');
  static const sales = RewriteStyle._('sales');
  static const simple = RewriteStyle._('simple');

  static const chips = [professional, shorter, friendlier, apology, fix, translate];

  /// Knowledge-base answers (Add Answer spec §4.6): no apology, + bullets.
  static const kbAnswerChips = [professional, shorter, friendlier, fix, translate, bullets];
  static const more = [formal, saudi, msa, greeting, bullets, sales, simple];

  static const defaultStyle = professional;

  /// First style when the sheet opens on a note and the last-used one is a
  /// tone style: spelling only, it never changes the meaning.
  static const defaultNoteStyle = fix;

  static RewriteStyle? builtIn(String id) {
    for (final s in [...chips, ...more]) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<RewriteStyle> chipsFor({required bool note}) => note
      ? [
          for (final s in chips)
            if (s.allowedInNote) s,
        ]
      : chips;

  /// Chip / menu label. The translate label flips with the source language.
  String label(AppLocalizations l, {required bool sourceIsArabic}) {
    if (customLabel != null) return customLabel!;
    return switch (id) {
      'professional' => l.rw_style_professional,
      'shorter' => l.rw_style_shorter,
      'friendlier' => l.rw_style_friendlier,
      'apology' => l.rw_style_apology,
      'fix' => l.rw_style_fix,
      'translate' => sourceIsArabic ? l.rw_style_to_en : l.rw_style_to_ar,
      'formal' => l.rw_style_formal,
      'saudi' => l.rw_style_saudi,
      'msa' => l.rw_style_msa,
      'greeting' => l.rw_style_greeting,
      'bullets' => l.rw_style_bullets,
      'sales' => l.rw_style_sales,
      'simple' => l.rw_style_simple,
      _ => id,
    };
  }

  @override
  bool operator ==(Object other) => other is RewriteStyle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
