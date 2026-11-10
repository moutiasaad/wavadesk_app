import 'package:flutter/material.dart';

/// Elevation tokens from Design System §7. Mostly flat: lists and cards use
/// 1dp borders; shadows are only for floating layers.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.low,
    required this.medium,
    required this.mediumUp,
    required this.high,
    required this.primaryGlow,
  });

  /// Bubbles, selected segment. Empty in dark mode (replaced by a border).
  final List<BoxShadow> low;

  /// AI suggestion card, menus, FAB.
  final List<BoxShadow> medium;

  /// Same as [medium] but cast upward (AI card floating above the composer).
  final List<BoxShadow> mediumUp;

  /// Bottom sheets, dialogs, snackbar.
  final List<BoxShadow> high;

  /// Primary FAB, app logo.
  final List<BoxShadow> primaryGlow;

  static const light = AppShadows(
    low: [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0F0F172A))],
    medium: [BoxShadow(offset: Offset(0, 8), blurRadius: 24, spreadRadius: -12, color: Color(0x400F172A))],
    mediumUp: [BoxShadow(offset: Offset(0, -8), blurRadius: 24, spreadRadius: -12, color: Color(0x400F172A))],
    high: [BoxShadow(offset: Offset(0, 24), blurRadius: 60, spreadRadius: -18, color: Color(0x590F172A))],
    primaryGlow: [BoxShadow(offset: Offset(0, 14), blurRadius: 30, spreadRadius: -10, color: Color(0x8C0F7E7A))],
  );

  static const dark = AppShadows(
    low: [],
    medium: [BoxShadow(offset: Offset(0, 8), blurRadius: 24, spreadRadius: -12, color: Color(0x99000000))],
    mediumUp: [BoxShadow(offset: Offset(0, -8), blurRadius: 24, spreadRadius: -12, color: Color(0x99000000))],
    high: [BoxShadow(offset: Offset(0, 24), blurRadius: 60, spreadRadius: -18, color: Color(0xB3000000))],
    primaryGlow: [BoxShadow(offset: Offset(0, 14), blurRadius: 30, spreadRadius: -10, color: Color(0x660F7E7A))],
  );

  @override
  AppShadows copyWith() => this;

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return t < 0.5 ? this : other;
  }
}
