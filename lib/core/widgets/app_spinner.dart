import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_surface.dart';

/// Circular spinner (§8.15): 18 in buttons, 24 on screens, stroke 2.5.
/// By default it only appears after 300ms so fast actions don't flash.
class AppSpinner extends StatefulWidget {
  const AppSpinner({super.key, this.size = 24, this.color, this.delayed = true});

  final double size;
  final Color? color;
  final bool delayed;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner> {
  late bool _visible = !widget.delayed;

  @override
  void initState() {
    super.initState();
    if (widget.delayed) {
      Future<void>.delayed(AppMotion.spinnerDelay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: _visible
          ? CircularProgressIndicator(
              strokeWidth: 2.5,
              color: widget.color ?? (BrandSurface.of(context) ? Colors.white : context.colors.primary),
              semanticsLabel: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            )
          : null,
    );
  }
}
