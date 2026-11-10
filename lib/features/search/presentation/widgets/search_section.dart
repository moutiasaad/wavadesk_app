import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Section header (`caption` 12.5/700, padding 16/22/6) + "عرض الكل (n)"
/// in الكل, "(محليًا)" offline (Search spec §6, §8).
class SearchSection extends StatelessWidget {
  const SearchSection({
    super.key,
    required this.title,
    required this.children,
    this.total = 0,
    this.onSeeAll,
    this.local = false,
  });

  final String title;
  final List<Widget> children;
  final int total;
  final VoidCallback? onSeeAll;
  final bool local;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.screenH,
            end: onSeeAll == null ? AppSpacing.screenH : AppSpacing.xs,
            top: 22 - (onSeeAll == null ? 0 : 10),
            bottom: onSeeAll == null ? 6 : 0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    local ? '$title ${l.search_local}' : title,
                    style: context.text.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              if (onSeeAll != null)
                AppButton(
                  label: l.search_see_all(total),
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  horizontalPadding: AppSpacing.sm,
                  onPressed: onSeeAll,
                ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}
