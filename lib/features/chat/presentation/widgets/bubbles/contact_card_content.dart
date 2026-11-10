import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Shared contact (Chat spec §4.4): avatar 36 + name + phone (LTR) + "حفظ".
class ContactCardContent extends StatelessWidget {
  const ContactCardContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final name = message.contactName ?? l.media_contact;
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 36,
                child: FittedBox(
                  child: AppAvatar(name: name, id: '${message.id}-contact', size: AppAvatarSize.md),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: t.bodyMedium.copyWith(color: foreground, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.contactPhone != null)
                      Text(
                        message.contactPhone!,
                        style: t.caption.copyWith(color: foreground.withValues(alpha: 0.7)),
                        textDirection: TextDirection.ltr,
                      ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 14, color: foreground.withValues(alpha: 0.15)),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: message.isOutgoing ? foreground : c.primary,
              textStyle: t.buttonSmall,
              minimumSize: const Size(48, 36),
            ),
            onPressed: () => AppSnackbar.show(context, message: l.bubble_contact_saved, kind: SnackKind.success),
            child: Text(l.bubble_save_contact),
          ),
        ],
      ),
    );
  }
}
