import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../ai_save_feedback.dart';

/// §5.4 handoff message editor with {اسم_العميل} / {وقت_العودة} variables.
Future<void> showHandoffMessageSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(context, title: context.l10n.ai_handoff_msg, builder: (_) => const _MessageBody());
}

class _MessageBody extends ConsumerStatefulWidget {
  const _MessageBody();

  @override
  ConsumerState<_MessageBody> createState() => _MessageBodyState();
}

class _MessageBodyState extends ConsumerState<_MessageBody> {
  static const maxChars = 300;
  late final TextEditingController _ctrl;
  late final String _initial;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(aiAgentControllerProvider).config?.handoff.message ?? '';
    _initial = saved;
    _ctrl = TextEditingController(text: saved);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled && _initial.isEmpty) _ctrl.text = context.l10n.ai_handoff_msg_default;
    _prefilled = true;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _insert(String token) {
    final v = _ctrl.value;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    final text = v.text.replaceRange(sel.start, sel.end, token);
    if (text.characters.length > maxChars) return;
    _ctrl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: sel.start + token.length));
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    Analytics.log('ai_rule_change', {'rule': 'handoff_message', 'value': text.length});
    final nav = Navigator.of(context);
    final r = await saveAiChange(context, ref, (c) => c.copyWith(handoff: c.handoff.copyWith(message: text)));
    if (r == AiSaveResult.saved && mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final canEdit = ref.watch(aiAgentControllerProvider).config?.canEdit ?? false;
    final count = _ctrl.text.characters.length;
    final valid = _ctrl.text.trim().isNotEmpty && count <= maxChars;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(controller: _ctrl, minLines: 3, maxLines: 6, maxLength: maxChars, enabled: canEdit),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count/$maxChars',
            textAlign: TextAlign.end,
            style: t.caption.copyWith(color: count > maxChars ? c.textError : c.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(label: Text(l.ai_var_customer), onPressed: canEdit ? () => _insert('{اسم_العميل}') : null),
              ActionChip(label: Text(l.ai_var_return), onPressed: canEdit ? () => _insert('{وقت_العودة}') : null),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: l.ai_save, expand: true, onPressed: canEdit && valid ? _save : null),
        ],
      ),
    );
  }
}
