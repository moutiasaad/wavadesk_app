import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale from Design System §4. Every style uses Cairo; colors default to
/// `textPrimary` and callers override with `copyWith(color: …)`.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles._(this._c);

  factory AppTextStyles.of(AppColors colors) => AppTextStyles._(colors);

  final AppColors _c;

  static const fontFamily = 'Cairo';
  static const monoFamily = 'IBMPlexMono';
  static const _tabular = [FontFeature.tabularFigures()];

  TextStyle _s(
    double size,
    FontWeight weight,
    double height, {
    double letterSpacing = 0,
    Color? color,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? _c.textPrimary,
    fontFeatures: tabular ? _tabular : null,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // §4.2 Type scale
  TextStyle get displayLarge => _s(32, FontWeight.w800, 1.25, letterSpacing: -0.3);
  TextStyle get h1 => _s(28, FontWeight.w800, 1.3, letterSpacing: -0.2);
  TextStyle get h2 => _s(24, FontWeight.w800, 1.3, letterSpacing: -0.1);
  TextStyle get h3 => _s(20, FontWeight.w800, 1.35);
  TextStyle get h4 => _s(18, FontWeight.w700, 1.4);
  TextStyle get h5 => _s(16, FontWeight.w700, 1.4);
  TextStyle get h6 => _s(14, FontWeight.w700, 1.45);
  TextStyle get bodyLarge => _s(16, FontWeight.w500, 1.6);
  TextStyle get bodyMedium => _s(14, FontWeight.w500, 1.55);
  TextStyle get bodySmall => _s(13, FontWeight.w500, 1.5);
  TextStyle get caption => _s(12, FontWeight.w600, 1.4);
  TextStyle get overline => _s(11, FontWeight.w700, 1.3, letterSpacing: 0.2);
  TextStyle get listTitle => _s(15, FontWeight.w700, 1.35);
  TextStyle get listSubtitle => _s(14, FontWeight.w500, 1.45, color: _c.textSecondary);

  // §4.3 Component styles
  TextStyle get buttonLarge => _s(16, FontWeight.w700, 1.2);
  TextStyle get buttonMedium => _s(14, FontWeight.w700, 1.2);
  TextStyle get buttonSmall => _s(13, FontWeight.w700, 1.2);
  TextStyle get chatMessage => _s(13.5, FontWeight.w500, 1.6);
  TextStyle get chatMessageEmoji => _s(32, FontWeight.w400, 1.2);
  TextStyle get chatSenderLabel => _s(10.5, FontWeight.w800, 1.3);
  TextStyle get chatTimestamp => _s(10, FontWeight.w600, 1.2, tabular: true);
  TextStyle get listTimestamp => _s(12, FontWeight.w600, 1.2, color: _c.textTertiary, tabular: true);
  TextStyle get dayDivider => _s(11, FontWeight.w700, 1.2, color: _c.textSecondary);
  TextStyle get badge => _s(11, FontWeight.w800, 1.0, tabular: true);
  TextStyle get chipLabel => _s(13, FontWeight.w700, 1.2);
  TextStyle get tagLabel => _s(11.5, FontWeight.w700, 1.2);
  TextStyle get metricValue => _s(28, FontWeight.w800, 1.2, tabular: true);
  TextStyle get inputLabel => _s(13, FontWeight.w700, 1.3);

  /// Order IDs, API keys (§4.1). Always LTR.
  TextStyle get mono =>
      TextStyle(fontFamily: monoFamily, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5, color: _c.textPrimary);

  /// Material [TextTheme] mapping so stock widgets pick up Cairo + tokens.
  TextTheme toTextTheme() => TextTheme(
    displayLarge: displayLarge,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleLarge: h4,
    titleMedium: h5,
    titleSmall: h6,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: buttonMedium,
    labelMedium: caption,
    labelSmall: overline,
  );

  @override
  AppTextStyles copyWith() => this;

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return t < 0.5 ? this : other;
  }
}
