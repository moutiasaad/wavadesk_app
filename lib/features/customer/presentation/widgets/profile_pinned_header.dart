import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/contact.dart';
import 'profile_hero.dart';

/// Pinned mini-header (§3): appears once the hero scrolls out. Brand
/// surface (BrandHeader, no status-bar padding: it lives in the sheet);
/// avatar 28 + white name + "فتح كصفحة" + ✕ 36.
class ProfilePinnedHeader extends StatelessWidget {
  const ProfilePinnedHeader({super.key, required this.contact, required this.onClose, this.onOpenPage});

  final Contact contact;
  final VoidCallback onClose;
  final VoidCallback? onOpenPage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = profileDisplayName(contact, l);
    return BrandHeader(
      safeTop: false,
      elevated: true,
      padding: const EdgeInsetsDirectional.fromSTEB(18, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
        children: [
          AppAvatar(
            name: name,
            id: contact.id,
            imageUrl: contact.avatarUrl,
            size: AppAvatarSize.sm,
            ringColor: BrandHeader.colorsOf(context).first,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: context.text.h5.copyWith(color: context.colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (onOpenPage != null)
            AppIconButton(
              icon: AppIcons.maximize,
              size: 36,
              iconSize: 18,
              semanticLabel: l.profile_open_page,
              onPressed: onOpenPage,
            ),
          AppIconButton(
            icon: AppIcons.close,
            variant: AppIconButtonVariant.filled,
            size: 36,
            iconSize: 18,
            semanticLabel: l.common_close,
            onPressed: onClose,
          ),
        ],
      ),
      ),
    );
  }
}
