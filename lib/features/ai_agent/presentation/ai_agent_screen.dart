import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/ai_agent_controller.dart';
import '../domain/ai_agent_config.dart';
import '../domain/readiness.dart';
import 'ai_save_feedback.dart';
import 'sheets/ai_confirm_sheets.dart';
import 'widgets/ai_advanced_group.dart';
import 'widgets/ai_mode_group.dart';
import 'widgets/ai_performance_group.dart';
import 'widgets/ai_readiness_card.dart';
import 'widgets/ai_rules_group.dart';
import 'widgets/ai_status_hero.dart';
import 'widgets/ai_test_button.dart';

/// وكيل الذكاء الاصطناعي (spec "11 AI Agent.md").
class AiAgentScreen extends ConsumerStatefulWidget {
  const AiAgentScreen({super.key});

  @override
  ConsumerState<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends ConsumerState<AiAgentScreen> {
  bool _logged = false;
  bool _countUp = true;

  @override
  void initState() {
    super.initState();
    // The provider outlives the screen: show the last config at once and
    // refresh it quietly (the first visit loads from the provider's build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(aiAgentControllerProvider).config != null) ref.read(aiAgentControllerProvider.notifier).load();
    });
  }

  /// Master switch (§4.1, §6.1, §6.2).
  Future<void> _toggle(AiAgentConfig c, bool on) async {
    final l = context.l10n;
    if (!on) {
      if (!await showAiOffConfirm(context, handling: c.handlingNow) || !mounted) return;
      Analytics.log('ai_toggle', {'enabled': false, 'handling_now': c.handlingNow});
      await saveAiChange(context, ref, (cfg) => cfg.copyWith(enabled: false), successMessage: l.ai_hero_off);
      return;
    }
    if (!Readiness.of(c).kbReady) {
      final choice = await showReadinessBlocker(context);
      if (!mounted) return;
      switch (choice) {
        case ReadinessBlockerChoice.addAnswers:
          context.go(Routes.knowledge);
          return;
        case ReadinessBlockerChoice.enableSuggest:
          Analytics.log('ai_toggle', {'enabled': true, 'handling_now': c.handlingNow});
          await saveAiChange(context, ref, (cfg) => cfg.copyWith(enabled: true, mode: AiMode.suggest));
          return;
        case null:
          return;
      }
    }
    if (!mounted) return;
    Analytics.log('ai_toggle', {'enabled': true, 'handling_now': c.handlingNow});
    await saveAiChange(context, ref, (cfg) => cfg.copyWith(enabled: true));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final state = ref.watch(aiAgentControllerProvider);
    final cfg = state.config;
    final reduced = AppMotion.reduced(context);

    if (cfg != null && !_logged) {
      _logged = true;
      Analytics.log('ai_settings_view', {'enabled': cfg.enabled, 'mode': cfg.mode.wire, 'readiness_complete': Readiness.of(cfg).complete});
      Future<void>.delayed(const Duration(milliseconds: 500), () => mounted ? setState(() => _countUp = false) : null);
    }

    final editable = cfg != null && cfg.canEdit && cfg.planAllowsAi;
    // Sections are interactive only while the AI is on (§4.1: dim to 50%).
    final interactive = editable && cfg.enabled;

    Widget body;
    if (cfg == null && state.error != null) {
      body = EmptyState(
        icon: state.offline ? AppIcons.offline : AppIcons.error,
        title: l.ai_load_error,
        actionLabel: l.ai_retry,
        onAction: ref.read(aiAgentControllerProvider.notifier).load,
      );
    } else if (cfg == null) {
      body = const _AiAgentSkeleton();
    } else {
      Widget dimmed(Widget child) => AnimatedOpacity(
            opacity: cfg.enabled || !cfg.canEdit ? 1 : 0.5,
            duration: reduced ? Duration.zero : AppMotion.normal,
            child: IgnorePointer(ignoring: !interactive, child: child),
          );
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: ref.read(aiAgentControllerProvider.notifier).load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            if (!cfg.canEdit)
              _InfoBanner(icon: AppIcons.lock, text: l.ai_readonly),
            if (!cfg.planAllowsAi)
              _PlanOffCard(isAdmin: ref.watch(currentAgentProvider).isAdmin),
            const SizedBox(height: AppSpacing.sm),
            AiStatusHero(config: cfg, countUp: _countUp),
            if (cfg.canEdit && cfg.planAllowsAi) AiReadinessCard(config: cfg),
            // Modes stay usable while the AI is off: picking one switches it on.
            AiModeGroup(config: cfg, interactive: editable),
            dimmed(AiRulesGroup(config: cfg, interactive: interactive)),
            AiPerformanceGroup(config: cfg),
            dimmed(AiAdvancedGroup(config: cfg, interactive: interactive)),
            const AiTestButton(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.ai_title,
        background: c.backgroundMuted,
        actions: [
          if (cfg != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Semantics(
                label: l.ai_master_switch,
                value: cfg.enabled ? l.ai_state_on : l.ai_state_off,
                child: AppSwitch(
                  value: cfg.enabled,
                  semanticLabel: l.ai_master_switch,
                  onChanged: editable ? (v) => _toggle(cfg, v) : null,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _Shake(trigger: state.revertTick, child: body),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          AppIcon(icon, dp: 18, color: c.textInfo),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.text.bodySmall.copyWith(color: c.textPrimary))),
        ],
      ),
    );
  }
}

class _PlanOffCard extends StatelessWidget {
  const _PlanOffCard({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.warningContainer, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Row(
        children: [
          AppIcon(AppIcons.warning, dp: 18, color: c.textWarning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l.ai_plan_off, style: context.text.bodySmall.copyWith(fontWeight: FontWeight.w700))),
          if (isAdmin)
            AppButton(
              label: l.ai_view_plans,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push(Routes.subscription),
            ),
        ],
      ),
    );
  }
}

/// Revert after a failed save: subtle 200 ms shake (§12).
class _Shake extends StatefulWidget {
  const _Shake({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

  @override
  void didUpdateWidget(_Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !AppMotion.reduced(context)) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final v = _ctrl.value;
          final dx = v == 0 || v == 1 ? 0.0 : 4 * (v < 0.5 ? v * 2 : (1 - v) * 2) * (v * 8 % 2 < 1 ? 1 : -1);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: widget.child,
      );
}

/// Loading (§7): hero at 30% teal + group skeletons.
class _AiAgentSkeleton extends StatelessWidget {
  const _AiAgentSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget group(double h) => Container(
          height: h,
          margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.all(14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [SkeletonBox(width: 140, height: 12), SizedBox(height: 14), SkeletonBox(width: 220, height: 10)],
          ),
        );
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            height: 92,
            margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(AppRadius.xxl)),
          ),
          group(190),
          group(140),
          group(230),
        ],
      ),
    );
  }
}
