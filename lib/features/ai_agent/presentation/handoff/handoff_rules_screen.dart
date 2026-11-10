import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../../domain/ai_agent_config.dart';
import '../ai_config_gate.dart';
import '../ai_save_feedback.dart';

/// Handoff rules (AI Agent spec §5.2). Every change auto-saves.
class HandoffRulesScreen extends ConsumerWidget {
  const HandoffRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return AiConfigGate(title: l.ai_handoff, builder: (_) => const SizedBox.shrink());
    final h = cfg.handoff;
    final edit = cfg.canEdit;

    void save(String rule, Object? value, HandoffRules Function(HandoffRules h) change) {
      Analytics.log('ai_rule_change', {'rule': rule, 'value': value});
      saveAiChange(context, ref, (c) => c.copyWith(handoff: change(c.handoff)));
    }

    Future<void> pickTeam() async {
      final teams = ref.read(teamsProvider);
      final picked = await AppBottomSheet.show<String>(
        context,
        title: l.ai_ho_target_team,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final team in teams)
              ListTile(
                title: Text(team.name, style: ctx.text.listTitle),
                trailing: team.id == h.teamId ? Icon(AppIcons.check, color: ctx.colors.primary) : null,
                onTap: () => Navigator.of(ctx).pop(team.id),
              ),
          ],
        ),
      );
      if (picked != null) save('target', 'team', (x) => x.copyWith(target: HandoffTargetType.team, teamId: picked));
    }

    final teamName = h.teamId == null ? null : ref.watch(teamsProvider).where((x) => x.id == h.teamId).firstOrNull?.name;

    Widget radio<T>(T value, String title, {String? subtitle, Widget? trailing}) => RadioListTile<T>(
          value: value,
          enabled: edit,
          title: Text(title, style: t.listTitle),
          subtitle: subtitle == null ? null : Text(subtitle, style: t.caption.copyWith(color: c.textSecondary)),
          secondary: trailing,
          controlAffinity: ListTileControlAffinity.leading,
        );

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: l.ai_handoff),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
              child: Text(l.ai_ho_intro, style: t.bodySmall.copyWith(color: c.textSecondary)),
            ),
            SettingsGroup(
              children: [
                _RuleRow(title: l.ai_ho_human, caption: l.ai_ho_always, value: true, onChanged: null),
                _RuleRow(
                  title: l.ai_ho_complaint,
                  value: h.onComplaint,
                  onChanged: edit ? (v) => save('on_complaint', v, (x) => x.copyWith(onComplaint: v)) : null,
                ),
                _RuleRow(
                  title: l.ai_ho_payment,
                  value: h.onPayment,
                  onChanged: edit ? (v) => save('on_payment', v, (x) => x.copyWith(onPayment: v)) : null,
                ),
                _RuleRow(
                  title: l.ai_ho_no_answer,
                  value: h.onNoAnswer,
                  onChanged: edit ? (v) => save('on_no_answer', v, (x) => x.copyWith(onNoAnswer: v)) : null,
                ),
                _RuleRow(
                  title: l.ai_ho_low_conf,
                  value: h.onLowConfidence,
                  onChanged: edit ? (v) => save('on_low_confidence', v, (x) => x.copyWith(onLowConfidence: v)) : null,
                ),
                _RuleRow(
                  title: l.ai_ho_after_n('${h.afterReplies ?? 4}'),
                  value: h.afterReplies != null,
                  onChanged: edit
                      ? (v) => save('after_replies', v ? 4 : null, (x) => v ? x.copyWith(afterReplies: x.afterReplies ?? 4) : x.copyWith(clearAfterReplies: true))
                      : null,
                  extra: h.afterReplies == null
                      ? null
                      : _Stepper(
                          value: h.afterReplies!,
                          min: 2,
                          max: 10,
                          enabled: edit,
                          onChanged: (n) => save('after_replies', n, (x) => x.copyWith(afterReplies: n)),
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsGroup(
              title: l.ai_ho_keywords,
              children: [
                _KeywordsEditor(
                  keywords: h.keywords,
                  enabled: edit,
                  onChanged: (list) => save('keywords', list.length, (x) => x.copyWith(keywords: list)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsGroup(
              title: l.ai_ho_target,
              children: [
                RadioGroup<HandoffTargetType>(
                  groupValue: h.target,
                  onChanged: (v) {
                    if (v == null || !edit) return;
                    if (v == HandoffTargetType.team) {
                      pickTeam();
                    } else {
                      save('target', v.wire, (x) => x.copyWith(target: v));
                    }
                  },
                  child: Column(
                    children: [
                      radio(HandoffTargetType.unassigned, l.ai_ho_target_unassigned),
                      radio(
                        HandoffTargetType.team,
                        l.ai_ho_target_team,
                        subtitle: h.target == HandoffTargetType.team ? teamName : null,
                        trailing: Icon(AppIcons.chevronEnd, size: 18, color: c.textTertiary),
                      ),
                      radio(HandoffTargetType.lastAgent, l.ai_ho_target_last),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsGroup(
              title: l.ai_ho_after_hours,
              children: [
                RadioGroup<AfterHoursBehavior>(
                  groupValue: h.afterHours,
                  onChanged: (v) {
                    if (v == null || !edit) return;
                    save('after_hours', v.wire, (x) => x.copyWith(afterHours: v));
                  },
                  child: Column(
                    children: [
                      radio(AfterHoursBehavior.tellReturnTime, l.ai_ho_tell_return),
                      radio(AfterHoursBehavior.handoffAndNotify, l.ai_ho_notify),
                    ],
                  ),
                ),
              ],
            ),
            if (!edit)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l.ai_readonly, style: t.caption.copyWith(color: c.textTertiary)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.title, this.caption, required this.value, required this.onChanged, this.extra});

  final String title;
  final String? caption;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: t.listTitle),
                          if (caption != null) Text(caption!, style: t.caption.copyWith(color: c.textTertiary)),
                        ],
                      ),
                    ),
                    AppSwitch(value: value, semanticLabel: title, onChanged: onChanged),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (extra != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 14, bottom: AppSpacing.sm),
            child: Align(alignment: AlignmentDirectional.centerStart, child: extra),
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.enabled, required this.onChanged});

  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(AppIcons.minus, size: 18, color: c.textPrimary),
            onPressed: enabled && value > min ? () => onChanged(value - 1) : null,
          ),
          Semantics(
            value: '$value',
            child: Text('$value', style: t.listTitle.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          IconButton(
            icon: Icon(AppIcons.plus, size: 18, color: c.textPrimary),
            onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _KeywordsEditor extends StatefulWidget {
  const _KeywordsEditor({required this.keywords, required this.enabled, required this.onChanged});

  final List<String> keywords;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_KeywordsEditor> createState() => _KeywordsEditorState();
}

class _KeywordsEditorState extends State<_KeywordsEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final w = _ctrl.text.trim();
    _ctrl.clear();
    if (w.isEmpty || widget.keywords.contains(w) || w.length > 50) return;
    widget.onChanged([...widget.keywords, w]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.keywords.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final k in widget.keywords)
                  InputChip(
                    label: Text(k, style: t.chipLabel),
                    isEnabled: widget.enabled,
                    onDeleted: widget.enabled ? () => widget.onChanged([...widget.keywords]..remove(k)) : null,
                  ),
              ],
            ),
          if (widget.enabled) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _ctrl,
              hint: l.ai_ho_keyword_add,
              textInputAction: TextInputAction.done,
              maxLength: 50,
              onSubmitted: (_) => _add(),
              suffix: IconButton(icon: Icon(AppIcons.plus, size: 18, color: context.colors.primary), onPressed: _add),
            ),
          ],
        ],
      ),
    );
  }
}
