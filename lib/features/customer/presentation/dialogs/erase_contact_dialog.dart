import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/customer_profile_controller.dart';
import '../../../auth/domain/identifier.dart';

/// حذف بيانات العميل (Profile spec §7.7, admin, GDPR/PDPL). The agent must
/// type the last 4 digits of the phone (or the word "حذف" when there's no
/// phone) before "حذف نهائي" enables.
Future<void> showEraseContactDialog(BuildContext context, WidgetRef ref, {required String contactId}) async {
  final contact = ref.read(customerProfileControllerProvider(contactId)).contact;
  if (contact == null) return;
  final l = context.l10n;
  final digits = latinDigitsOnly(contact.phone ?? '');
  final expected = digits.length >= 4 ? digits.substring(digits.length - 4) : l.erase_word;

  final ok = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (ctx) => _EraseDialog(expected: expected, byPhone: digits.length >= 4),
  );
  if (ok != true || !context.mounted) return;

  // Grab what we need before the profile route disappears.
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(customerProfileControllerProvider(contactId).notifier).erase();
    router.go(Routes.conversations);
    if (context.mounted) {
      AppSnackbar.show(context, message: l.erase_done, kind: SnackKind.success);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.erase_done)));
    }
  } catch (_) {
    if (context.mounted) AppSnackbar.show(context, message: l.erase_failed, kind: SnackKind.error);
  }
}

class _EraseDialog extends StatefulWidget {
  const _EraseDialog({required this.expected, required this.byPhone});

  final String expected;
  final bool byPhone;

  @override
  State<_EraseDialog> createState() => _EraseDialogState();
}

class _EraseDialogState extends State<_EraseDialog> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _matches => latinDigitsOnly(_ctrl.text.trim()) == widget.expected || _ctrl.text.trim() == widget.expected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width - 48;
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
                child: Icon(AppIcons.delete, size: 22, color: c.textError),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(header: true, child: Text(l.erase_title, style: t.h4, textAlign: TextAlign.center)),
              const SizedBox(height: AppSpacing.sm),
              Text(l.erase_body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: widget.byPhone ? l.erase_type_digits : l.erase_type_word(widget.expected),
                controller: _ctrl,
                autofocus: true,
                keyboardType: widget.byPhone ? TextInputType.number : TextInputType.text,
                textDirection: widget.byPhone ? TextDirection.ltr : null,
                maxLength: widget.byPhone ? 4 : 10,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l.erase_confirm,
                variant: AppButtonVariant.destructiveFilled,
                size: AppButtonSize.large,
                expand: true,
                onPressed: _matches ? () => Navigator.pop(context, true) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l.erase_cancel,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                expand: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Digits only, Arabic-Indic converted to Latin.
String latinDigitsOnly(String s) => Identifier.latinDigits(s).replaceAll(RegExp(r'[^0-9]'), '');
