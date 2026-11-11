import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';

/// The website's green Wavadesk logo (public/images/wavadesk-icon-gradient
/// .svg): gradient tile with the white wave, with a soft brand glow. Same
/// look in light and dark mode.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wavadesk',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // The SVG tile has rx 16 of 64 and a 2/64 inset.
          borderRadius: BorderRadius.circular(size * 15 / 64),
          boxShadow: context.shadows.primaryGlow,
        ),
        child: SvgPicture.asset(
          'assets/brand/wavadesk_logo.svg',
          width: size,
          height: size,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
