import 'package:flutter/material.dart';

import '../../../../core/icons/wd_svg_icons.dart';
import '../../../../core/theme/app_theme.dart';

/// Login v2 §4.2.4: 54dp full-width, radius 14, fixed right→left teal
/// gradient (not flipped in LTR), deep teal glow. Arrow + label centred,
/// the arrow first (on the right in Arabic). Presses to 0.98. While
/// [loading] a white spinner replaces the content; [success] shows a white
/// check (§11). Never disabled for empty fields — only while [locked].
class LoginPrimaryButton extends StatefulWidget {
  const LoginPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.success = false,
    this.locked = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool success;
  final bool locked;

  @override
  State<LoginPrimaryButton> createState() => _LoginPrimaryButtonState();
}

class _LoginPrimaryButtonState extends State<LoginPrimaryButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final reduced = AppMotion.reduced(context);
    final busy = widget.loading || widget.success;
    final enabled = !busy && !widget.locked;

    final Widget content;
    if (widget.success) {
      content = const AppIcon(AppIcons.check, dp: 22, color: Colors.white, key: ValueKey('ok'));
    } else if (widget.loading) {
      content = const SizedBox.square(
        key: ValueKey('spin'),
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    } else {
      content = Row(
        key: const ValueKey('label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(WdSvgIcons.arrow, dp: 22, color: Colors.white),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: t.buttonLarge.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _down && !reduced ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            opacity: widget.locked ? 0.55 : 1,
            duration: AppMotion.fast,
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF1F9A8F), Color(0xFF11827B), Color(0xFF0D6E69)],
                  stops: [0, 0.55, 1],
                ),
                boxShadow: const [
                  BoxShadow(offset: Offset(0, 10), blurRadius: 22, spreadRadius: -12, color: Color(0xCC0D6E69)),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(duration: AppMotion.fast, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
