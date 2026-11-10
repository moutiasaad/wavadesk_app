import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../application/composer_controller.dart';

/// Horizontal 64×64 thumbnails (radius 10) with ✕ and an upload progress
/// ring (Chat spec §4.7).
class AttachmentsPreview extends StatelessWidget {
  const AttachmentsPreview({super.key, required this.attachments, required this.onRemove});

  final List<PendingAttachment> attachments;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(top: 8),
          itemCount: attachments.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) => _Thumb(attachment: attachments[i], onRemove: onRemove),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.attachment, required this.onRemove});

  final PendingAttachment attachment;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final a = attachment;
    final isImage = a.kind == MessageKind.image;
    return Semantics(
      label: a.ready ? a.name : '${a.name}، ${l.composer_uploading((a.progress * 100).round())}',
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isImage ? c.primaryContainer : c.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.kind.icon, size: 22, color: isImage ? c.primary : c.textSecondary),
                  if (!isImage)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Text(
                        a.name,
                        style: context.text.overline.copyWith(color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                ],
              ),
            ),
            if (!a.ready)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.scrim.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator(
                        value: a.progress.clamp(0.02, 1),
                        strokeWidth: 2.5,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              top: -8,
              end: -8,
              child: Semantics(
                button: true,
                label: l.composer_remove_attachment,
                excludeSemantics: true,
                child: InkResponse(
                  radius: 18,
                  onTap: () => onRemove(a.id),
                  child: SizedBox.square(
                    dimension: 28,
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.background, width: 2),
                        ),
                        child: Icon(AppIcons.close, size: 11, color: c.onSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
