import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/chat_controller.dart';

/// "Close conversation" card (web parity: the close modal). The AI writes a
/// short title right away; the agent can edit it, ask for another one, or
/// leave it empty. Returns the title ('' = none) or null when cancelled.
Future<String?> showCloseConversationSheet(BuildContext context, WidgetRef ref, String conversationId) {
  final l = context.l10n;
  return AppBottomSheet.show<String>(
    context,
    title: l.close_title,
    subtitle: l.close_subtitle,
    builder: (_) => _CloseConversationBody(conversationId: conversationId),
  );
}

class _CloseConversationBody extends ConsumerStatefulWidget {
  const _CloseConversationBody({required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<_CloseConversationBody> createState() => _CloseConversationBodyState();
}

class _CloseConversationBodyState extends ConsumerState<_CloseConversationBody> {
  static const _maxLength = 180;
  final _title = TextEditingController();
  bool _suggesting = false;

  /// The agent typed: a late AI answer must not overwrite it.
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _suggest();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    setState(() {
      _suggesting = true;
      _edited = false;
    });
    final title = await ref.read(chatActionsProvider(widget.conversationId)).suggestTitle();
    if (!mounted) return;
    setState(() => _suggesting = false);
    if (_edited) return;
    if (title.isEmpty) {
      if (_title.text.isEmpty) AppSnackbar.show(context, message: context.l10n.close_ai_unavailable);
      return;
    }
    _title.value = TextEditingValue(text: title, selection: TextSelection.collapsed(offset: title.length));
  }

  void _close() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_title.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    return Padding(
      // The sheet frame already lifts above the keyboard.
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: l.close_field_label,
            hint: _suggesting ? l.close_ai_writing : l.close_field_hint,
            controller: _title,
            maxLength: _maxLength,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _edited = true,
            onSubmitted: (_) => _close(),
            suffix: _suggesting
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppSpinner(size: 18, delayed: false, color: c.primary),
                  )
                : null,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _suggesting ? null : _suggest,
              icon: AppIcon(AppIcons.ai, dp: 16, color: _suggesting ? c.textDisabled : c.primary),
              label: Text(_title.text.isEmpty ? l.close_ai_suggest : l.close_ai_again),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.close_hint, style: t.caption.copyWith(color: c.textTertiary)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.close_confirm,
            icon: AppIcons.resolve,
            size: AppButtonSize.large,
            expand: true,
            onPressed: _close,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.common_cancel,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
