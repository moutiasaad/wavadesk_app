import 'package:flutter/widgets.dart';

/// Motion tokens (§12.2). Nothing runs longer than 300ms; the only looping
/// animations are the typing indicator and the live dot (§2).
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);
  static const Curve standard = Curves.easeOutCubic;

  /// Typing indicator and skeleton shimmer loop.
  static const loop = Duration(milliseconds: 1200);

  /// Spinners never appear for actions shorter than this (§8.15).
  static const spinnerDelay = Duration(milliseconds: 300);

  /// Whether the platform asked for reduced motion (§11).
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
