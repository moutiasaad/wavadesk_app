import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../ai_config_gate.dart';
import '../ai_save_feedback.dart';

/// §4.8 extra instructions appended to the AI's system prompt (≤ 1,000).
class CustomInstructionsScreen extends StatelessWidget {
  const CustomInstructionsScreen({super.key});

  // The text field is seeded from the loaded config, so wait for it.
  @override
  Widget build(BuildContext context) => AiConfigGate(title: context.l10n.ai_instructions, builder: (_) => const _InstructionsEditor());
}

class _InstructionsEditor extends ConsumerStatefulWidget {
  const _InstructionsEditor();

  @override
  ConsumerState<_InstructionsEditor> createState() => _CustomInstructionsScreenState();
}

class _CustomInstructionsScreenState extends ConsumerState<_InstructionsEditor> {
  static const maxChars = 1000;
  late final TextEditingController _ctrl;
  late final String _initial;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = ref.read(aiAgentControllerProvider).config?.customInstructions ?? '';
    _ctrl = TextEditingController(text: _initial)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final text = _ctrl.text.trim();
    Analytics.log('ai_rule_change', {'rule': 'custom_instructions', 'value': text.length});
    final nav = Navigator.of(context);
    final r = await saveAiChange(context, ref, (c) => c.copyWith(customInstructions: text));
    if (!mounted) return;
    setState(() => _saving = false);
    if (r == AiSaveResult.saved) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final canEdit = ref.watch(aiAgentControllerProvider).config?.canEdit ?? false;
    final count = _ctrl.text.characters.length;
    final dirty = _ctrl.text.trim() != _initial.trim();
    final valid = count <= maxChars;

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.ai_instructions,
        actions: [
          if (canEdit) AppBarTextAction(label: l.ai_save, onPressed: dirty && valid && !_saving ? _save : null),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              controller: _ctrl,
              hint: l.ai_instructions_ph,
              minLines: 8,
              maxLines: 16,
              maxLength: maxChars,
              enabled: canEdit,
              autofocus: canEdit,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$count/$maxChars',
              textAlign: TextAlign.end,
              style: t.caption.copyWith(color: valid ? c.textTertiary : c.textError),
            ),
          ],
        ),
      ),
    );
  }
}
