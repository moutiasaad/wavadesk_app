import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'wd_svg_icons.dart';

/// Icon size tokens (Icon Library §2.1).
enum AppIconSize {
  /// Inside chips/badges, meta rows.
  xs(12),

  /// List chevrons, inline with `bodySmall`, tool chips.
  sm(16),

  /// Default: app bar actions, composer, settings, buttons.
  md(18),

  /// Tab bar, primary FAB, hero tiles.
  lg(24),

  /// Small empty states, inline success.
  xl(32),

  /// Empty states, dialog header icons.
  xxl(48);

  const AppIconSize(this.dp);
  final double dp;
}

/// The only way screens draw an icon (Icon Library §5): size token, token
/// color (default `textPrimary`), RTL handled by the glyph itself
/// (`AppIcons` uses Lucide's `…Dir` variants for directional icons), and
/// semantics — decorative icons (no [semanticLabel]) are hidden from screen
/// readers.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = AppIconSize.md, this.dp, this.color, this.semanticLabel});

  /// Null draws an empty box of the same size (like [Icon]).
  final IconData? icon;
  final AppIconSize size;

  /// Container-specific size from §2.2 (settings tile 18, avatar badge 11…);
  /// wins over [size].
  final double? dp;

  /// Always a token; null → `textPrimary`.
  final Color? color;

  /// Set only for icons that carry meaning on their own.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    final px = dp ?? size.dp;
    final tint = color ?? colors?.textPrimary ?? IconTheme.of(context).color;
    final icon = this.icon;
    if (icon != null && WdSvgIcons.isSvg(icon)) {
      Widget svg = SvgPicture.asset(
        WdSvgIcons.assetOf(icon),
        width: px,
        height: px,
        colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
      );
      if (WdSvgIcons.flips(icon, Directionality.of(context))) {
        svg = Transform.flip(flipX: true, child: svg);
      }
      return Semantics(label: semanticLabel, excludeSemantics: true, child: svg);
    }
    final glyph = Icon(icon, size: px, color: tint, semanticLabel: semanticLabel);
    return semanticLabel == null ? ExcludeSemantics(child: glyph) : glyph;
  }
}

/// Loading state of an icon slot (§4): a 2dp spinner the same size/color.
class AppIconSpinner extends StatelessWidget {
  const AppIconSpinner({super.key, this.size = AppIconSize.md, this.color});

  final AppIconSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    return SizedBox.square(
      dimension: size.dp,
      child: CircularProgressIndicator(strokeWidth: 2, color: color ?? colors?.textPrimary),
    );
  }
}
