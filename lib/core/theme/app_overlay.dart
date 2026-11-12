import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// System bars for a screen region. The app draws edge-to-edge, so both bars
/// are transparent: the status bar shows the header behind it, and the
/// navigation bar (3-button or gesture) shows the tab bar / page behind it.
/// Flutter's `SystemUiOverlayStyle.light` / `.dark` presets paint the
/// navigation bar solid black, so headers must use this instead.
SystemUiOverlayStyle appOverlay(BuildContext context, {required bool lightStatusIcons}) {
  final dark = Theme.of(context).extension<AppColors>()?.isDark ?? Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: lightStatusIcons ? Brightness.light : Brightness.dark,
    // iOS reads the bar's background brightness instead.
    statusBarBrightness: lightStatusIcons ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
