import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../application/whatsapp_channel_controller.dart';

/// Optimistic save with the shared snackbars (same pattern as the AI agent's
/// `saveAiChange`): success → [successMessage] + **تراجع** when [onUndo];
/// failure → reverted + **تعذّر حفظ التغيير** + **إعادة المحاولة**;
/// offline → **التعديل يتطلب اتصالًا بالإنترنت**.
Future<WaSaveResult> saveWaChange(
  BuildContext context,
  WidgetRef ref,
  Future<WaSaveResult> Function(WhatsAppChannelController ctrl) run, {
  String? successMessage,
  VoidCallback? onUndo,
}) async {
  final l = context.l10n;
  final ctrl = ref.read(whatsAppChannelControllerProvider.notifier);
  final result = await run(ctrl);
  if (!context.mounted) return result;
  switch (result) {
    case WaSaveResult.saved:
      if (successMessage != null) {
        AppSnackbar.show(
          context,
          message: successMessage,
          kind: SnackKind.success,
          actionLabel: onUndo == null ? null : l.wa_undo,
          onAction: onUndo,
        );
      }
    case WaSaveResult.failed:
    case WaSaveResult.forbidden:
      AppSnackbar.show(
        context,
        message: l.wa_save_failed,
        kind: SnackKind.error,
        actionLabel: l.wa_retry,
        onAction: () => saveWaChange(context, ref, run, successMessage: successMessage, onUndo: onUndo),
      );
    case WaSaveResult.offline:
      AppSnackbar.show(context, message: l.wa_offline, kind: SnackKind.error);
    case WaSaveResult.handledByAi:
      AppSnackbar.show(context, message: l.wa_away_ai_banner);
  }
  return result;
}
