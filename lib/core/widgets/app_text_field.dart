import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// §8.21 text field: min height 52, radius 14, 1.5dp `border`, `bodyLarge`.
/// Focus: 1.5dp `primary` + 4dp `primaryContainer` ring. Error: `error`
/// border + `textError` helper. Label above in `inputLabel`, 6 gap.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.onChanged,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.autofillHints,
    this.textDirection,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
    this.style,
    this.textAlign = TextAlign.start,
    this.obscuringCharacter = '•',
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  /// Force LTR for emails/phones (§11 bidi).
  final TextDirection? textDirection;
  final bool enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  /// Overrides the default `bodyLarge` input text style.
  final TextStyle? style;
  final TextAlign textAlign;
  final String obscuringCharacter;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool readOnly;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final focused = _focus.hasFocus;
    final hasError = widget.error != null;
    final borderColor = hasError ? c.error : (focused ? c.primary : c.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          // The visible label is read as part of the field (below), not twice.
          ExcludeSemantics(child: Text(widget.label!, style: t.inputLabel)),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: widget.enabled ? c.surface : c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: focused && !hasError
                ? [BoxShadow(color: c.primaryContainer, spreadRadius: 4)]
                : focused && hasError
                ? [BoxShadow(color: c.errorContainer, spreadRadius: 4)]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: widget.maxLines > 1 ? 15 : 0),
                  child: Icon(widget.prefixIcon, size: 18, color: c.textTertiary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Semantics(
                  label: widget.label,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscure,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    minLines: widget.obscure ? 1 : widget.minLines,
                    maxLines: widget.obscure ? 1 : widget.maxLines,
                    maxLength: widget.maxLength,
                    autofillHints: widget.autofillHints,
                    textDirection: widget.textDirection,
                    inputFormatters: widget.inputFormatters,
                    readOnly: widget.readOnly,
                    textAlign: widget.textAlign,
                    obscuringCharacter: widget.obscuringCharacter,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.enableSuggestions,
                    textCapitalization: widget.textCapitalization,
                    style: widget.style ?? t.bodyLarge,
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: widget.hint,
                      hintStyle: (widget.style ?? t.bodyLarge).copyWith(color: c.textTertiary, letterSpacing: 0),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
        if (hasError || widget.helper != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: hasError,
            child: Text(
              widget.error ?? widget.helper!,
              style: t.bodySmall.copyWith(color: hasError ? c.textError : c.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}
