import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.count, this.selectedColor});

  final T value;
  final String label;

  /// Shown after the label in `primary` ("لي (5)").
  final int? count;

  /// Overrides the selected segment bg (presence picker uses success container).
  final Color? selectedColor;
}

/// §8.13 segmented control: height 40, `surfaceVariant` track, radius 12,
/// padding 3; selected segment `surface` + low elevation, radius 9.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 40,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: _SegmentButton<T>(
                segment: s,
                selected: s.value == selected,
                onTap: () => onChanged(s.value),
                minHeight: height - 6,
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({required this.segment, required this.selected, required this.onTap, required this.minHeight});

  final AppSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      selected: selected,
      label: segment.count == null ? segment.label : '${segment.label} ${segment.count}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          constraints: BoxConstraints(minHeight: minHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: selected ? (segment.selectedColor ?? c.surface) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected ? context.shadows.low : null,
            border: selected && c.isDark ? Border.all(color: c.border) : null,
          ),
          child: Text.rich(
            TextSpan(
              text: segment.label,
              children: [
                if (segment.count != null)
                  TextSpan(
                    text: ' (${segment.count})',
                    style: TextStyle(color: c.primary),
                  ),
              ],
            ),
            style: t.buttonSmall.copyWith(color: selected ? c.textPrimary : c.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
