import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Exact colors of Dashboard v2 (§4, §10), light and dark.
@immutable
class DashPalette {
  const DashPalette._({
    required this.page,
    required this.card,
    required this.cardBorder,
    required this.waitingFg,
    required this.waitingBg,
    required this.waitingBorder,
    required this.aiFg,
    required this.aiBg,
    required this.aiBorder,
    required this.up,
    required this.down,
    required this.barPast,
    required this.barCurrent,
    required this.barFuture,
    required this.axis,
  });

  /// Header fill in both themes.
  static const header = Color(0xFF0F7E7A);
  static const unreadDot = Color(0xFFFB7185);
  static const tooltip = Color(0xFF0D1417);
  static const online = Color(0xFF22C55E);
  static const busy = Color(0xFFF59E0B);
  static const away = Color(0xFF94A3B8);

  final Color page;
  final Color card;
  final Color cardBorder;
  final Color waitingFg;
  final Color waitingBg;
  final Color waitingBorder;
  final Color aiFg;
  final Color aiBg;
  final Color aiBorder;
  final Color up;
  final Color down;
  final Color barPast;
  final Color barCurrent;
  final Color barFuture;
  final Color axis;

  static const _light = DashPalette._(
    page: Color(0xFFF6F8FA),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE9EEF2),
    waitingFg: Color(0xFFE11D48),
    waitingBg: Color(0xFFFFF7F8),
    waitingBorder: Color(0xFFFECDD3),
    aiFg: Color(0xFF0A5E5B),
    aiBg: Color(0xFFECF7F6),
    aiBorder: Color(0xFFD6EFED),
    up: Color(0xFF15803D),
    down: Color(0xFFE11D48),
    barPast: Color(0xFFD6EFED),
    barCurrent: Color(0xFF0F7E7A),
    barFuture: Color(0xFFEEF2F5),
    axis: Color(0xFF94A3B8),
  );

  static const _dark = DashPalette._(
    page: Color(0xFF0B1215),
    card: Color(0xFF151E22),
    cardBorder: Color(0xFF243036),
    waitingFg: Color(0xFFFB7185),
    waitingBg: Color(0xFF2A1218),
    waitingBorder: Color(0xFF5B1B2A),
    aiFg: Color(0xFF5EEAD4),
    aiBg: Color(0xFF0F2E2D),
    aiBorder: Color(0xFF1D4744),
    up: Color(0xFF4ADE80),
    down: Color(0xFFFB7185),
    barPast: Color(0xFF1D4744),
    barCurrent: Color(0xFF2BB8AD),
    barFuture: Color(0xFF1C272C),
    axis: Color(0xFF64748B),
  );

  static DashPalette of(BuildContext context) => context.colors.isDark ? _dark : _light;
}

/// Card shell shared by the KPI tiles, chart and team cards: radius 16,
/// 1dp border, no shadow.
class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.borderColor, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = DashPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: borderColor ?? p.cardBorder),
    );
    return Material(
      color: color ?? p.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
