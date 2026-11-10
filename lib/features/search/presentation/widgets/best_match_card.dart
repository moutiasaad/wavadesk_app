import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/search_query.dart';

/// "أفضل نتيجة" — single high-confidence phone / email match (§6.6):
/// card radius 18, avatar 50, name h5, phone, quick actions.
class BestMatchCard extends StatelessWidget {
  const BestMatchCard({super.key, required this.hit, required this.onOpenChat, required this.onProfile, this.onCall});

  final ContactHit hit;
  final VoidCallback? onOpenChat;
  final VoidCallback onProfile;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              header: true,
              child: Text(
                l.search_best_match,
                style: t.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: onProfile,
                  child: Row(
                    children: [
                      AppAvatar(
                        name: hit.name,
                        id: hit.id,
                        imageUrl: hit.avatarUrl,
                        channel: hit.channel,
                        size: AppAvatarSize.lg,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hit.name, style: t.h5, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if ((hit.phone ?? hit.matchedValue).isNotEmpty)
                              Text(
                                ltr(hit.phone ?? hit.matchedValue),
                                style: t.bodySmall.copyWith(color: c.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    AppButton(
                      label: l.search_open_chat,
                      size: AppButtonSize.small,
                      icon: AppIcons.conversations,
                      onPressed: onOpenChat,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: l.search_profile,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.secondary,
                      onPressed: onProfile,
                    ),
                    const Spacer(),
                    if (onCall != null)
                      AppIconButton(
                        icon: AppIcons.call,
                        variant: AppIconButtonVariant.outlined,
                        semanticLabel: l.search_call,
                        onPressed: onCall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
