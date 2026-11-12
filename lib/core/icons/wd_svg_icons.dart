import 'package:flutter/widgets.dart';

/// The 44 design icons exported 1:1 from the mockup (`assets/icons/*.svg`,
/// 24×24, stroke 1.9). They replace Lucide wherever a design icon exists.
///
/// Each one is a const [IconData] tagged with [family], so `AppIcons` keeps
/// its type and every screen picks them up unchanged; [AppIcon] sees the tag
/// and draws the SVG instead of a font glyph. Nothing else may draw these
/// with a plain `Icon` — the font does not exist.
abstract final class WdSvgIcons {
  static const String family = 'WdSvg';

  static const IconData alert = IconData(0xE000, fontFamily: family);
  static const IconData archive = IconData(0xE001, fontFamily: family);
  static const IconData arrow = IconData(0xE002, fontFamily: family);
  static const IconData back = IconData(0xE003, fontFamily: family);
  static const IconData block = IconData(0xE004, fontFamily: family);
  static const IconData bell = IconData(0xE005, fontFamily: family);
  static const IconData book = IconData(0xE006, fontFamily: family);
  static const IconData chat = IconData(0xE007, fontFamily: family);
  static const IconData check = IconData(0xE008, fontFamily: family);
  static const IconData checks = IconData(0xE009, fontFamily: family);
  static const IconData chevron = IconData(0xE00A, fontFamily: family);
  static const IconData attach = IconData(0xE00B, fontFamily: family);
  static const IconData clock = IconData(0xE00C, fontFamily: family);
  static const IconData more = IconData(0xE00D, fontFamily: family);
  static const IconData edit = IconData(0xE00E, fontFamily: family);
  static const IconData eye = IconData(0xE00F, fontFamily: family);
  static const IconData faceId = IconData(0xE010, fontFamily: family);
  static const IconData file = IconData(0xE011, fontFamily: family);
  static const IconData filter = IconData(0xE012, fontFamily: family);
  static const IconData globe = IconData(0xE013, fontFamily: family);
  static const IconData grid = IconData(0xE014, fontFamily: family);
  static const IconData image = IconData(0xE015, fontFamily: family);
  static const IconData link = IconData(0xE016, fontFamily: family);
  static const IconData lock = IconData(0xE017, fontFamily: family);
  static const IconData mic = IconData(0xE018, fontFamily: family);
  static const IconData note = IconData(0xE019, fontFamily: family);
  static const IconData logout = IconData(0xE01A, fontFamily: family);
  static const IconData phone = IconData(0xE01B, fontFamily: family);
  static const IconData play = IconData(0xE01C, fontFamily: family);
  static const IconData add = IconData(0xE01D, fontFamily: family);
  static const IconData qa = IconData(0xE01E, fontFamily: family);
  static const IconData redo = IconData(0xE01F, fontFamily: family);
  static const IconData search = IconData(0xE020, fontFamily: family);
  static const IconData send = IconData(0xE021, fontFamily: family);
  static const IconData ai = IconData(0xE022, fontFamily: family);
  static const IconData star = IconData(0xE023, fontFamily: family);
  static const IconData theme = IconData(0xE024, fontFamily: family);
  static const IconData tag = IconData(0xE025, fontFamily: family);
  static const IconData userPlus = IconData(0xE026, fontFamily: family);
  static const IconData user = IconData(0xE027, fontFamily: family);
  static const IconData users = IconData(0xE028, fontFamily: family);
  static const IconData whatsapp = IconData(0xE029, fontFamily: family);
  static const IconData logo = IconData(0xE02A, fontFamily: family);
  static const IconData close = IconData(0xE02B, fontFamily: family);

  /// File per code point (same order as above).
  static const List<String> _files = [
    'alert', 'arch', 'arr', 'back', 'ban', 'bell', 'book', 'chat', 'check', 'checks', 'chev', //
    'clip', 'clock', 'dots', 'edit', 'eye', 'face', 'file', 'flt', 'globe', 'grid', 'img', //
    'link', 'lock', 'mic', 'note', 'out', 'phone', 'play', 'plus', 'qa', 'redo', 'search', //
    'send', 'spark', 'star', 'sun', 'tag', 'uplus', 'user', 'users', 'wa', 'wave', 'x',
  ];

  /// Directional glyphs and the direction they are drawn for. The mockup is
  /// Arabic-first: back / chevron / send / logout already point the RTL way,
  /// so they flip in LTR; arrow and redo are drawn LTR and flip in RTL.
  /// Everything else (chat bubble, WhatsApp, play…) never flips.
  static const Map<String, TextDirection> _drawnFor = {
    'back': TextDirection.rtl,
    'chev': TextDirection.rtl,
    'send': TextDirection.rtl,
    'out': TextDirection.rtl,
    'arr': TextDirection.ltr,
    'redo': TextDirection.ltr,
  };

  static bool isSvg(IconData? icon) => icon != null && icon.fontFamily == family;

  static String assetOf(IconData icon) => 'assets/icons/${_files[icon.codePoint - 0xE000]}.svg';

  /// Whether [icon] must be mirrored for the ambient [direction].
  static bool flips(IconData icon, TextDirection direction) {
    final drawn = _drawnFor[_files[icon.codePoint - 0xE000]];
    return drawn != null && drawn != direction;
  }
}
