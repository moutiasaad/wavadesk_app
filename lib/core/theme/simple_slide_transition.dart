import 'package:flutter/material.dart';

/// The one page transition of the app: the new page slides in from the end
/// edge (mirrored in RTL) while the old one shifts a little toward the
/// start. No fade, no zoom. Reduce-motion: no animation.
Widget simpleSlide(BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
  final dir = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
  final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  final outCurve = CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  return SlideTransition(
    position: Tween(begin: Offset.zero, end: Offset(-0.3 * dir, 0)).animate(outCurve),
    child: SlideTransition(
      position: Tween(begin: Offset(dir, 0), end: Offset.zero).animate(inCurve),
      child: child,
    ),
  );
}

/// [simpleSlide] for every `MaterialPageRoute` / `MaterialPage` (theme).
class SimpleSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SimpleSlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      simpleSlide(context, animation, secondaryAnimation, child);
}
