import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';

/// Handoff rule / reason code → label (AI Agent spec §4.7, §5.5).
String aiReasonLabel(AppLocalizations l, String? rule) {
  if (rule == null || rule.isEmpty) return l.ai_reason_other;
  if (rule.startsWith('keyword:')) return l.ai_reason_keyword(rule.substring('keyword:'.length));
  return switch (rule) {
    'human_request' => l.ai_reason_human_request,
    'complaint' => l.ai_reason_complaint,
    'payment' => l.ai_reason_payment,
    'no_answer' => l.ai_reason_no_answer,
    'low_confidence' => l.ai_reason_low_confidence,
    'after_replies' => l.ai_reason_after_replies,
    _ => l.ai_reason_other,
  };
}

String aiToneLabel(AppLocalizations l, AiTone t) => switch (t) {
      AiTone.friendly => l.ai_tone_friendly,
      AiTone.formal => l.ai_tone_formal,
      AiTone.concise => l.ai_tone_concise,
    };

/// "لماذا هذا الرد؟" (§5.5): sources, confidence, rule, tone.
Future<void> showAiWhySheet(BuildContext context, AiTestReply reply) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.ai_test_why,
    builder: (_) => _WhyBody(reply: reply),
  );
}

class _WhyBody extends ConsumerWidget {
  const _WhyBody({required this.reply});

  final AiTestReply reply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final kb = ref.read(knowledgeProvider.notifier);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xs),
          child: Text(title, style: t.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
        );
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text(label, style: t.bodyMedium.copyWith(color: c.textSecondary))),
              Text(value, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    final conf = reply.confidence;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          section(l.ai_why_sources),
          if (reply.sources.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              child: Text(l.ai_why_no_sources, style: t.bodySmall.copyWith(color: c.textTertiary)),
            )
          else
            for (final (id, title) in reply.sources)
              () {
                // Only entries the app knows locally can be opened.
                final local = kb.byId(id) ?? kb.byId(id.replaceFirst('kb_', ''));
                return ListTile(
                  dense: true,
                  leading: Icon(AppIcons.knowledge, size: 18, color: c.primary),
                  title: Text(title, style: t.bodyMedium),
                  trailing: local == null ? null : Icon(AppIcons.chevronEnd, size: 16, color: c.textTertiary),
                  onTap: local == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          context.push(Routes.editKnowledge(local.id));
                        },
                );
              }(),
          const Divider(height: AppSpacing.xl),
          row(l.ai_why_confidence, conf == null ? '—' : '${(conf * 100).round()}%'),
          row(l.ai_why_rule, reply.ruleTriggered == null ? '—' : aiReasonLabel(l, reply.ruleTriggered)),
          row(l.ai_why_tone, aiToneLabel(l, reply.tone)),
        ],
      ),
    );
  }
}
