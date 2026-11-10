import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/customer_profile_controller.dart';

/// حظر {name}؟ (Profile spec §7.5). Optional reason chips; on success the
/// profile stays open, the chat switches to the blocked bar, and an Undo
/// snackbar appears.
Future<void> showBlockContactDialog(BuildContext context, WidgetRef ref, {required String contactId}) async {
  final contact = ref.read(customerProfileControllerProvider(contactId)).contact;
  if (contact == null) return;
  final l = context.l10n;
  final name = contact.name ?? l.block_unnamed;

  // null = cancelled; '' = confirmed without a reason.
  final reason = await showDialog<String>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (ctx) => _BlockDialog(name: name),
  );
  if (reason == null || !context.mounted) return;

  try {
    final undo = await ref
        .read(customerProfileControllerProvider(contactId).notifier)
        .block(reason: reason.isEmpty ? null : reason);
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      message: l.block_done,
      kind: SnackKind.success,
      actionLabel: l.undo,
      onAction: () => undo(),
    );
  } catch (_) {
    if (context.mounted) AppSnackbar.show(context, message: l.block_failed, kind: SnackKind.error);
  }
}

class _BlockDialog extends StatefulWidget {
  const _BlockDialog({required this.name});

  final String name;

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width - 48;
    final reasons = [
      ('spam', l.block_reason_spam),
      ('fraud', l.block_reason_fraud),
      ('abuse', l.block_reason_abuse),
      ('other', l.block_reason_other),
    ];
    return Dialog(
      backgroundColor: c.surfaceElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.clamp(0, 360)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.errorContainer, shape: BoxShape.circle),
                child: Icon(AppIcons.block, size: 22, color: c.textError),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(header: true, child: Text(l.block_title(widget.name), style: t.h4, textAlign: TextAlign.center)),
              const SizedBox(height: AppSpacing.sm),
              Text(l.block_body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              Text(l.block_reason_label, style: t.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (key, label) in reasons)
                    AppFilterChip(
                      label: label,
                      selected: _reason == key,
                      onTap: () => setState(() => _reason = _reason == key ? null : key),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l.block_confirm,
                variant: AppButtonVariant.destructiveFilled,
                size: AppButtonSize.large,
                expand: true,
                onPressed: () => Navigator.pop(context, _reason ?? ''),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l.block_cancel,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
