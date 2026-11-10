import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import 'customer_profile_view.dart';

/// Tablet (≥ 840dp) side panel next to the chat (Profile spec §2): 360dp,
/// `surfaceElevated`, header "ملف العميل" + ✕.
class CustomerProfilePanel extends ConsumerWidget {
  const CustomerProfilePanel({super.key, required this.contactId, this.conversationId, this.onClose, this.onNote});

  final String contactId;
  final String? conversationId;
  final VoidCallback? onClose;

  /// Passed through for callers; the "ملاحظة" quick action adds a
  /// contact-level note (§5.2).
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    return Container(
      width: 360,
      color: c.surfaceElevated,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsetsDirectional.only(start: 18, end: AppSpacing.sm),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.divider))),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(l.profile_title, style: context.text.h5)),
                ),
                if (onClose != null)
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: CustomerProfileView(contactId: contactId, conversationId: conversationId, container: 'panel'),
            ),
          ),
        ],
      ),
    );
  }
}
