import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/contact.dart';

/// Danger zone (§5.10): block (destructive) / unblock (secondary), hint,
/// and admin-only "حذف بيانات العميل".
class ProfileDangerZone extends StatelessWidget {
  const ProfileDangerZone({super.key, required this.contact, this.onBlock, this.onUnblock, this.onErase});

  final Contact contact;

  /// Null hides the button (no can_block / offline handled by caller).
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;

  /// Admin only (can_delete).
  final VoidCallback? onErase;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final blocked = contact.isBlocked;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contact.permissions.canBlock) ...[
            AppButton(
              label: blocked ? l.profile_unblock : l.profile_block_cta,
              icon: blocked ? AppIcons.unblock : AppIcons.block,
              variant: blocked ? AppButtonVariant.secondary : AppButtonVariant.destructive,
              size: AppButtonSize.large,
              expand: true,
              onPressed: blocked ? onUnblock : onBlock,
            ),
            if (!blocked) ...[
              const SizedBox(height: 6),
              Text(l.profile_block_hint, style: t.caption.copyWith(color: c.textTertiary), textAlign: TextAlign.center),
            ],
          ],
          if (onErase != null && contact.permissions.canDelete)
            Center(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: c.textError, textStyle: t.buttonSmall, minimumSize: const Size(48, 48)),
                onPressed: onErase,
                child: Text(l.profile_erase),
              ),
            ),
        ],
      ),
    );
  }
}
