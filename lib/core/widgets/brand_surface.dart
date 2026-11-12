import 'package:flutter/widgets.dart';

/// Marks a subtree drawn in the app header ([BrandHeader]).
/// Header icon buttons use one glyph size and text actions turn into
/// small teal links.
class BrandSurface extends InheritedWidget {
  const BrandSurface({super.key, required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BrandSurface>() != null;

  @override
  bool updateShouldNotify(BrandSurface oldWidget) => false;
}
