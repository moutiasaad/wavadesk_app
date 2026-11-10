import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Reply-quote preview above the field (Chat spec §4.7): 48dp,
/// `surfaceVariant`, 3dp `primary` start bar, sender + one line, ✕.
class ReplyPreviewBar extends StatelessWidget {
  const ReplyPreviewBar({super.key, required this.message, required this.senderName, required this.onClose});

  final Message message;
  final String senderName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final preview = message.text.isNotEmpty ? message.text : message.kind.label(l);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: c.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.composer_reply_to(senderName), style: t.chatSenderLabel.copyWith(color: c.primary)),
                    Text(
                      preview,
                      style: t.bodySmall.copyWith(color: c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: AppIconButton(
                icon: AppIcons.close,
                size: 32,
                iconSize: 16,
                semanticLabel: l.composer_cancel_reply,
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
