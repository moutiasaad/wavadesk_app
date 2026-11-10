import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// "عمليات البحث الأخيرة" + مسح; rows 48: 🕘 · text (LTR isolate for
/// numbers) · ✕ (Search spec §5). Removal animates size + fade 150ms.
class RecentSearches extends StatelessWidget {
  const RecentSearches({
    super.key,
    required this.items,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  static bool _numeric(String s) => RegExp(r'^[\d\s+#\-()٠-٩]+$').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final reduced = AppMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenH, end: AppSpacing.xs, top: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.search_recent,
                    style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
                  ),
                ),
              ),
              AppButton(
                label: l.search_clear,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                horizontalPadding: AppSpacing.sm,
                onPressed: onClear,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: reduced ? Duration.zero : AppMotion.fast,
          alignment: AlignmentDirectional.topStart,
          child: Column(
            children: [
              for (final q in items)
                KeyedSubtree(
                  key: ValueKey(q),
                  child: InkWell(
                    onTap: () => onTap(q),
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenH, end: AppSpacing.xs),
                        child: Row(
                          children: [
                            AppIcon(AppIcons.history, size: AppIconSize.sm, color: c.textTertiary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _numeric(q) ? ltr(q) : q,
                                style: t.bodyMedium.copyWith(color: c.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppIconButton(
                              icon: AppIcons.close,
                              iconSize: 16,
                              iconColor: c.textTertiary,
                              semanticLabel: l.search_recent_remove(q),
                              onPressed: () => onRemove(q),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
