import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// On the brand header: a light pill field (46, radius 14, `surface`, white
/// ring when focused) + clear ⊗ 22 + white "إلغاء" (Search spec §4.1). Hero
/// tag `search-field`.
class SearchHeader extends StatefulWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCancel,
    this.placeholder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;
  final String? placeholder;

  static const heroTag = 'search-field';

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  static final _rtl = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
  static final _ltr = RegExp(r'[A-Za-zÀ-ɏ0-9+]');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  TextDirection? _direction(String s) {
    for (final ch in s.characters) {
      if (_rtl.hasMatch(ch)) return TextDirection.rtl;
      if (_ltr.hasMatch(ch)) return TextDirection.ltr;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final focused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    final style = t.bodyLarge.copyWith(fontSize: 15, color: c.textPrimary);

    final field = Material(
      type: MaterialType.transparency,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 46,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: focused ? c.primary : Colors.transparent, width: 1.5),
          boxShadow: focused ? [BoxShadow(color: Colors.white.withValues(alpha: 0.35), spreadRadius: 3)] : null,
        ),
        padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
        child: Row(
          children: [
            AppIcon(AppIcons.search, size: AppIconSize.sm, color: c.textTertiary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                label: l.search_field_label,
                textField: true,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  style: style,
                  textDirection: _direction(widget.controller.text),
                  textInputAction: TextInputAction.search,
                  cursorColor: c.primary,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.placeholder ?? l.search_placeholder,
                    hintMaxLines: 1,
                    hintStyle: style.copyWith(color: c.textTertiary),
                  ),
                ),
              ),
            ),
            if (hasText)
              _ClearButton(
                label: l.search_clear,
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged('');
                  widget.focusNode.requestFocus(); // keeps focus
                },
              ),
          ],
        ),
      ),
    );

    return _StatusBarBleed(
      child: BrandHeader(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: AppMotion.reduced(context) ? field : Hero(tag: SearchHeader.heroTag, child: field),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: t.buttonMedium,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(l.search_cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// 22 circle `borderStrong` + white ✕ 13 (stroke 3), 44 hit.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: c.borderStrong, shape: BoxShape.circle),
              child: const AppIcon(AppIcons.close, size: AppIconSize.xs, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen puts this header inside a top SafeArea, so the status-bar
/// strip above it would keep the page color: paint the brand gradient there
/// too (outside the header's own bounds; nothing else is drawn there).
class _StatusBarBleed extends StatelessWidget {
  const _StatusBarBleed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).top;
    // Not under a SafeArea (BrandHeader pads itself) or no status bar.
    if (inset == 0 || MediaQuery.paddingOf(context).top > 0) return child;
    final colors = BrandHeader.colorsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -inset,
          left: 0,
          right: 0,
          height: inset + 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [colors.first, Color.lerp(colors.first, colors.last, 0.5)!],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
