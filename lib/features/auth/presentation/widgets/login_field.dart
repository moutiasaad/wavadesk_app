import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Login v2 §4.2.2 field: 54dp, radius 14, soft fill. Focused = white,
/// 1.5 teal border + 4dp mint ring, teal icon. Error = white, rose border +
/// rose ring, rose icon, message under it (with the alert icon). 60%
/// opacity while the form is submitting.
class LoginField extends StatefulWidget {
  const LoginField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.placeholder,
    this.errorText,
    this.showErrorBorder = false,
    this.enabled = true,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.autofocus = false,
    this.ltrText = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String placeholder;

  /// Message under the field; also turns the field into its error state.
  final String? errorText;

  /// Error border without a message (wrong credentials: both fields, §5.3).
  final bool showErrorBorder;
  final bool enabled;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Email: typed left-to-right but aligned with the leading icon, so in
  /// Arabic it sits on the right next to the icon (§4.2.2).
  final bool ltrText;

  @override
  State<LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(LoginField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_rebuild);
      widget.focusNode.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final dark = c.isDark;
    final focused = widget.focusNode.hasFocus;
    final error = widget.errorText != null || widget.showErrorBorder;

    final soft = dark ? const Color(0xFF1A2428) : const Color(0xFFF3F6F8);
    final white = dark ? const Color(0xFF0F171A) : Colors.white;
    const teal = Color(0xFF0F7E7A);
    final tealDark = dark ? const Color(0xFF2BB8AD) : teal;
    final rose = dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);

    final Color bg;
    final Color border;
    final Color ring;
    final Color iconColor;
    if (error) {
      bg = white;
      border = rose;
      ring = dark ? const Color(0xFF2E1219) : const Color(0xFFFFF1F2);
      iconColor = rose;
    } else if (focused) {
      bg = white;
      border = tealDark;
      ring = dark ? const Color(0xFF0F2E2D) : const Color(0xFFECF7F6);
      iconColor = tealDark;
    } else {
      bg = soft;
      border = Colors.transparent;
      ring = Colors.transparent;
      iconColor = dark ? const Color(0xFF7B8A92) : const Color(0xFF94A3B8);
    }
    final textColor = dark ? const Color(0xFFE6ECEF) : const Color(0xFF0F172A);
    final placeholderColor = dark ? const Color(0xFF7B8A92) : const Color(0xFF94A3B8);
    final style = t.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: textColor, height: 1.3);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final field = AnimatedContainer(
      duration: AppMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 54),
      padding: EdgeInsetsDirectional.only(start: 14, end: widget.trailing == null ? 14 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [if (ring != Colors.transparent) BoxShadow(color: ring, spreadRadius: 4)],
      ),
      child: Row(
        children: [
          AppIcon(widget.icon, dp: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: widget.placeholder,
              textField: true,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                obscureText: widget.obscure,
                obscuringCharacter: '•',
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                autocorrect: false,
                enableSuggestions: !widget.obscure && !widget.ltrText,
                onSubmitted: widget.onSubmitted,
                textDirection: widget.ltrText || widget.obscure ? TextDirection.ltr : null,
                // LTR text, aligned to the icon side: right in Arabic.
                textAlign: (widget.ltrText || widget.obscure) && rtl ? TextAlign.right : TextAlign.start,
                style: widget.obscure && widget.controller.text.isNotEmpty ? style.copyWith(letterSpacing: 3) : style,
                cursorColor: tealDark,
                inputFormatters: widget.ltrText ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))] : null,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.placeholder,
                  hintStyle: style.copyWith(color: placeholderColor, letterSpacing: 0),
                  hintTextDirection: Directionality.of(context),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          ?widget.trailing,
        ],
      ),
    );

    return Opacity(
      opacity: widget.enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          field,
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6, start: 2),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    AppIcon(AppIcons.warning, dp: 14, color: rose),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.errorText!,
                        style: t.bodySmall.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: rose),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
