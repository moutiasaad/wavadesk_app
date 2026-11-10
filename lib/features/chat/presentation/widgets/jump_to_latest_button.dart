import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Jump to latest (Chat spec §4.8): 40 circle, `surface` + medium shadow,
/// chevron-down 20; new-message `CountBadge` (primary) at top-start.
class JumpToLatestButton extends StatelessWidget {
  const JumpToLatestButton({super.key, required this.newCount, required this.onTap});

  final int newCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final label = newCount > 0 ? '${l.chatlist_jump_latest}، ${l.chat_new_messages(newCount)}' : l.chatlist_jump_latest;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSpacing.minTouch,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: context.shadows.medium),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: AppIcon(AppIcons.chevronDown, color: c.textPrimary),
                ),
              ),
            ),
            if (newCount > 0) PositionedDirectional(top: -2, start: -2, child: CountBadge(count: newCount)),
          ],
        ),
      ),
    );
  }
}
