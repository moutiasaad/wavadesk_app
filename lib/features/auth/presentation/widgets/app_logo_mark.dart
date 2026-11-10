import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';

/// Login spec §4.1: 64×64 rounded square (radius 20), `primary`, white wave
/// mark 34×34, primary glow. The tile keeps the brand teal `#0F7E7A` in dark
/// mode too (§10).
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wavadesk',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.light.primary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: context.shadows.primaryGlow,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/brand/wave_mark.svg',
          width: size * 34 / 64,
          height: size * 34 / 64,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
