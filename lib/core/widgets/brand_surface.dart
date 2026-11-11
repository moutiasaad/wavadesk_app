import 'package:flutter/widgets.dart';

/// Marks a subtree drawn on the teal brand header ([AppBarStandard]).
/// Icon buttons, text actions, switches and spinners inside switch to
/// light colors so header actions stay readable.
class BrandSurface extends InheritedWidget {
  const BrandSurface({super.key, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BrandSurface>() != null;

  @override
  bool updateShouldNotify(BrandSurface oldWidget) => false;
}
