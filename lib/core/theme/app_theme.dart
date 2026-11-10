import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_icons.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, AppShadows.light);
  static ThemeData get dark => _build(AppColors.dark, AppShadows.dark);

  static ThemeData _build(AppColors c, AppShadows shadows) {
    final text = AppTextStyles.of(c);
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      tertiary: c.accent,
      onTertiary: c.onPrimary,
      error: c.error,
      onError: Colors.white,
      errorContainer: c.errorContainer,
      onErrorContainer: c.textError,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.surfaceVariant,
      outline: c.border,
      outlineVariant: c.divider,
      scrim: c.scrim,
      shadow: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: text.toTextTheme(),
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.divider,
      splashFactory: InkRipple.splashFactory,
      highlightColor: c.surfaceVariant.withValues(alpha: 0.6),
      splashColor: c.surfaceVariant.withValues(alpha: 0.6),
      focusColor: c.accent.withValues(alpha: 0.24),
      extensions: [c, text, shadows],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.textPrimary,
        titleTextStyle: text.h4,
        // §10 rule 8: status bar icons light on dark, dark on light.
        systemOverlayStyle: c.isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary, refreshBackgroundColor: c.surface),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        modalBackgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: text.caption.copyWith(color: c.onSecondary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Token accessors: `context.colors.primary`, `context.text.h1`,
/// `context.shadows.medium`.
extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTextStyles get text => Theme.of(this).extension<AppTextStyles>()!;
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
