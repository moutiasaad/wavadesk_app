import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';

/// Login v2 §4.1 teal header: 170° gradient, brand row (logo tile,
/// "Wavadesk", language pill) and the mirrored top wave (75%) along the
/// bottom. [compact] = screens under 700dp (bottom padding 72, wave 100).
class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key,
    required this.languageLabel,
    required this.languageSemantics,
    required this.onLanguage,
    this.compact = false,
  });

  final String languageLabel;
  final String languageSemantics;
  final VoidCallback onLanguage;
  final bool compact;

  /// 170° CSS gradient (top-start → bottom-end), not mirrored in RTL.
  static const _gradient = LinearGradient(
    begin: Alignment(-0.17, -1),
    end: Alignment(0.17, 1),
    colors: [Color(0xFF0F7A74), Color(0xFF16897F), Color(0xFF22998D)],
    stops: [0, 0.45, 1],
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final waveHeight = compact ? 100.0 : 130.0;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: ClipRect(
        child: Stack(
          children: [
            // The flip is part of the design: same in RTL and LTR.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: waveHeight,
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0.75,
                  child: Transform.flip(
                    flipX: true,
                    child: SvgPicture.asset('assets/images/login_wave_top.svg', fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, top + 6, 22, compact ? 72 : 96),
              child: Row(
                children: [
                  const _LogoTile(),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Wavadesk',
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: context.text.h3.copyWith(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  _LanguagePill(label: languageLabel, semantics: languageSemantics, onTap: onLanguage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 42×42 tile, radius 13, soft drop shadow: the app's launcher icon itself
/// (assets/icon/app_icon.png), with a thin white edge so it reads on the
/// teal header.
class _LogoTile extends StatelessWidget {
  const _LogoTile();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
        boxShadow: const [BoxShadow(offset: Offset(0, 8), blurRadius: 18, spreadRadius: -8, color: Color(0x4D000000))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.5),
        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      ),
    ),
  );
}

/// h36 outlined pill: globe 16 + language name + chevron 12 pointing down.
class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.label, required this.semantics, required this.onTap});

  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // chev.svg points left in RTL (drawn) and right in LTR (flipped): turn
    // it a quarter so it points down either way.
    final quarter = (rtl ? -1 : 1) * math.pi / 2;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.50))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AppIcons.globe, dp: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: context.text.buttonSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.rotate(
                    angle: quarter,
                    child: const AppIcon(AppIcons.chevronForward, dp: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
