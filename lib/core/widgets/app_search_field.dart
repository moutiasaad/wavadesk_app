import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';

/// §8.12. Height 44, radius 12, `surfaceVariant`, no border. Focused: `surface`
/// + 1.5dp `primary` border + 4dp `primaryContainer` ring, clear button, and
/// an "إلغاء" text button at the end of the row.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.autofocus = false,
    this.showCancel = true,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called by the "إلغاء" button. Defaults to clearing + unfocusing.
  final VoidCallback? onCancel;
  final bool autofocus;
  final bool showCancel;

  /// Read-only fields act as a button that opens the search screen.
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    _controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _controller.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final focused = _focus.hasFocus;

    final field = AnimatedContainer(
      duration: AppMotion.fast,
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: focused ? c.surface : c.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: focused ? c.primary : Colors.transparent, width: 1.5),
        boxShadow: focused ? [BoxShadow(color: c.primaryContainer, spreadRadius: 4)] : null,
      ),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.xs),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 16, color: c.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: t.bodyMedium,
              cursorColor: c.primary,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: t.bodyMedium.copyWith(color: c.textTertiary),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            Semantics(
              button: true,
              label: context.l10n.common_clear_search,
              excludeSemantics: true,
              child: InkResponse(
                radius: 20,
                onTap: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
                child: SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: c.borderStrong, shape: BoxShape.circle),
                      child: const Icon(AppIcons.close, size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(child: field),
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: widget.showCancel && (focused || _controller.text.isNotEmpty)
              ? TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: c.primary,
                    textStyle: t.buttonMedium,
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.xs),
                  ),
                  onPressed:
                      widget.onCancel ??
                      () {
                        _controller.clear();
                        widget.onChanged?.call('');
                        _focus.unfocus();
                      },
                  child: Text(context.l10n.common_cancel),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
