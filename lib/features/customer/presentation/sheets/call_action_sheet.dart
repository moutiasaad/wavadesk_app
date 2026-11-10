import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/customer_profile_controller.dart';

enum _CallOption { phone, whatsapp, copy }

/// Call action sheet (Profile spec §7.4): phone call · WhatsApp call · copy
/// number · cancel. Logs "اتصل {actor} بالعميل" in the current conversation.
Future<void> showCallActionSheet(BuildContext context, WidgetRef ref, {required String contactId, String? conversationId}) async {
  final phone = ref.read(customerProfileControllerProvider(contactId)).contact?.phone;
  if (phone == null) return;
  final l = context.l10n;
  final picked = await AppBottomSheet.show<_CallOption>(
    context,
    showClose: false,
    builder: (ctx) => Column(
      children: [
        SheetActionRow(icon: AppIcons.call, label: l.call_phone, onTap: () => Navigator.pop(ctx, _CallOption.phone)),
        SheetActionRow(icon: AppIcons.whatsapp, label: l.call_whatsapp, onTap: () => Navigator.pop(ctx, _CallOption.whatsapp)),
        SheetActionRow(icon: AppIcons.copy, label: l.call_copy, onTap: () => Navigator.pop(ctx, _CallOption.copy)),
        SheetActionRow(icon: AppIcons.close, label: l.call_cancel, onTap: () => Navigator.pop(ctx)),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;

  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final waDigits = digits.replaceAll('+', '');
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  switch (picked) {
    case _CallOption.phone:
      Analytics.log('profile_quick_action', {'action': 'call'});
      if (!await open(Uri(scheme: 'tel', path: digits)) && context.mounted) {
        AppSnackbar.show(context, message: l.call_failed, kind: SnackKind.error);
        return;
      }
    case _CallOption.whatsapp:
      Analytics.log('profile_quick_action', {'action': 'call'});
      final ok = await open(Uri.parse('whatsapp://send?phone=$waDigits')) || await open(Uri.parse('https://wa.me/$waDigits'));
      if (!ok && context.mounted) {
        AppSnackbar.show(context, message: l.call_failed, kind: SnackKind.error);
        return;
      }
    case _CallOption.copy:
      await Clipboard.setData(ClipboardData(text: phone));
      HapticFeedback.lightImpact();
      if (context.mounted) AppSnackbar.show(context, message: l.call_copied, kind: SnackKind.success);
      return;
  }
  // Optional system event in the current conversation.
  if (conversationId != null) {
    ref.read(inboxProvider.notifier).addSystemEvent(conversationId, SystemEventKind.called);
  }
}
