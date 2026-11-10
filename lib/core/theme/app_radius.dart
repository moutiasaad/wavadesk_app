import 'package:flutter/widgets.dart';

/// Border radius tokens from Design System §6.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 20;
  static const double dialog = 24;
  static const double sheet = 28;
  static const double full = 999;

  /// Corner used for the chat bubble "tail" (§6).
  static const double bubbleTail = 6;

  static BorderRadius circular(double r) => BorderRadius.circular(r);

  /// Bubble shape: 18 on every corner except the tail corner (6).
  /// Uses logical corners so RTL mirrors automatically.
  static BorderRadiusDirectional bubble({required bool outgoing, required bool hasTail}) {
    const r = Radius.circular(xl);
    const tail = Radius.circular(bubbleTail);
    if (!hasTail) return const BorderRadiusDirectional.all(r);
    return outgoing
        ? const BorderRadiusDirectional.only(topStart: r, topEnd: r, bottomStart: r, bottomEnd: tail)
        : const BorderRadiusDirectional.only(topStart: r, topEnd: r, bottomStart: tail, bottomEnd: r);
  }
}
