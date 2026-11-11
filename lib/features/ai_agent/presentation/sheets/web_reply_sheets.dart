import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../ai_save_feedback.dart';

/// Web "Suggestions per message": 1–5.
Future<void> showSuggestionCountSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.ai_suggestions,
    subtitle: context.l10n.ai_suggestions_sub,
    builder: (_) => const _SuggestionCountBody(),
  );
}

class _SuggestionCountBody extends ConsumerWidget {
  const _SuggestionCountBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
      child: Row(
        children: [
          for (var n = 1; n <= 5; n++) ...[
            if (n > 1) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CountChip(
                n: n,
                selected: cfg.suggestionCount == n,
                onTap: !cfg.canEdit || cfg.suggestionCount == n
                    ? null
                    : () {
                        Analytics.log('ai_rule_change', {'rule': 'suggestion_count', 'value': n});
                        saveAiChange(context, ref, (c) => c.copyWith(suggestionCount: n));
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.n, required this.selected, required this.onTap});

  final int n;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$n',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primary : c.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: selected ? c.primary : c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(
                '$n',
                style: context.text.h4.copyWith(color: selected ? c.onPrimary : c.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web "Escalation keywords": words in a customer message that hand the
/// conversation to a person.
Future<void> showEscalationKeywordsSheet(BuildContext context, WidgetRef ref) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.ai_keywords,
    subtitle: context.l10n.ai_keywords_sub,
    builder: (_) => const _KeywordsBody(),
  );
}

class _KeywordsBody extends ConsumerStatefulWidget {
  const _KeywordsBody();

  @override
  ConsumerState<_KeywordsBody> createState() => _KeywordsBodyState();
}

class _KeywordsBodyState extends ConsumerState<_KeywordsBody> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _save(List<String> words) {
    saveAiChange(context, ref, (c) => c.copyWith(handoff: c.handoff.copyWith(keywords: words)));
  }

  void _add() {
    final cfg = ref.read(aiAgentControllerProvider).config;
    final word = _field.text.trim();
    if (cfg == null || word.isEmpty) return;
    final words = cfg.handoff.keywords;
    if (words.any((w) => w.toLowerCase() == word.toLowerCase())) {
      _field.clear();
      return;
    }
    Analytics.log('ai_rule_change', {'rule': 'keywords', 'value': 'add'});
    _save([...words, word]);
    _field.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return const SizedBox.shrink();
    final words = cfg.handoff.keywords;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (words.isEmpty)
            Text(l.ai_keywords_empty, style: t.bodySmall.copyWith(color: c.textSecondary))
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final w in words)
                  InputChip(
                    label: Text(w),
                    onDeleted: cfg.canEdit ? () => _save([for (final x in words) if (x != w) x]) : null,
                    deleteButtonTooltipMessage: l.ai_keywords_remove,
                  ),
              ],
            ),
          if (cfg.canEdit) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _field,
              hint: l.ai_keywords_hint,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              suffix: AppIconButton(icon: AppIcons.add, semanticLabel: l.ai_keywords_add, onPressed: _add),
            ),
          ],
        ],
      ),
    );
  }
}
