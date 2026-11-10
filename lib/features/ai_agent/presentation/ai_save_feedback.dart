import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/ai_agent_controller.dart';
import '../domain/ai_agent_config.dart';

/// Auto-save with the shared snackbars (AI Agent spec §2, §7):
/// - saved + [successMessage] → snackbar with **تراجع** (risky changes);
/// - failure → reverted + **تعذّر حفظ التغيير** + **إعادة المحاولة**;
/// - 409 → **عدّل {name} الإعدادات للتو** (values already reloaded);
/// - offline → **التعديل يتطلب اتصالًا بالإنترنت**.
///
/// Read-only users never reach this (controls are disabled).
Future<AiSaveResult> saveAiChange(
  BuildContext context,
  WidgetRef ref,
  AiAgentConfig Function(AiAgentConfig c) edit, {
  String? successMessage,
  bool undoable = true,
}) async {
  final l = context.l10n;
  final ctrl = ref.read(aiAgentControllerProvider.notifier);
  final before = ref.read(aiAgentControllerProvider).config;
  final result = await ctrl.apply(edit);
  if (!context.mounted) return result;
  switch (result) {
    case AiSaveResult.saved:
      if (successMessage != null) {
        AppSnackbar.show(
          context,
          message: successMessage,
          kind: SnackKind.success,
          actionLabel: undoable && before != null ? l.ai_undo : null,
          onAction: undoable && before != null ? () => ctrl.restore(before) : null,
        );
      }
    case AiSaveResult.failed:
    case AiSaveResult.forbidden:
      AppSnackbar.show(
        context,
        message: l.ai_save_failed,
        kind: SnackKind.error,
        actionLabel: l.ai_retry,
        onAction: () => saveAiChange(context, ref, edit, successMessage: successMessage, undoable: undoable),
      );
    case AiSaveResult.conflict:
      final name = ref.read(aiAgentControllerProvider).conflictBy;
      AppSnackbar.show(context, message: name == null || name.isEmpty ? l.ai_conflict_anon : l.ai_conflict(name));
    case AiSaveResult.offline:
      AppSnackbar.show(context, message: l.ai_offline, kind: SnackKind.error);
  }
  return result;
}
