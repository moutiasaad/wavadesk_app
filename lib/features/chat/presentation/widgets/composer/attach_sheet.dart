import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

enum AttachOption { media, camera, file, location, quickReplies, template, product, note }

/// Whether a product catalog integration is connected. None in the sample
/// workspace, so "منتج" stays hidden.
const bool _hasCatalog = false;

/// Attach sheet (Chat spec §4.7.2): 4-column grid, items 72 — tinted icon
/// tile 52 (radius 16) + caption. Template only for WhatsApp. When the 24h
/// window is closed only templates and media are offered.
Future<AttachOption?> showAttachSheet(BuildContext context, {required bool whatsapp, required bool windowClosed}) {
  return AppBottomSheet.show<AttachOption>(
    context,
    showClose: false,
    builder: (ctx) {
      final c = ctx.colors;
      final l = ctx.l10n;
      final items = <(AttachOption, IconData, String, Color, Color)>[
        (AttachOption.media, AppIcons.image, l.chat_attach_media, c.infoContainer, c.info),
        (AttachOption.camera, AppIcons.camera, l.chat_attach_camera, c.statusSnoozedContainer, c.statusSnoozed),
        if (!windowClosed) (AttachOption.file, AppIcons.file, l.chat_attach_file, c.surfaceVariant, c.textSecondary),
        if (!windowClosed)
          (AttachOption.location, AppIcons.location, l.chat_attach_location, c.successContainer, c.success),
        if (!windowClosed)
          (AttachOption.quickReplies, AppIcons.quickReply, l.chat_attach_quick, c.warningContainer, c.warning),
        if (whatsapp)
          (
            AttachOption.template,
            AppIcons.templates,
            l.chat_attach_template,
            c.channelWhatsappContainer,
            c.channelWhatsapp,
          ),
        if (_hasCatalog && !windowClosed)
          (AttachOption.product, AppIcons.tag, l.chat_attach_product, c.primaryContainer, c.primary),
        (AttachOption.note, AppIcons.note, l.chat_mode_note, c.noteBackground, c.noteForeground),
      ];
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.78,
          children: [
            for (final (opt, icon, label, bg, fg) in items)
              Semantics(
                button: true,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => Navigator.pop(ctx, opt),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                        child: AppIcon(icon, color: fg),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: ctx.text.caption,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
