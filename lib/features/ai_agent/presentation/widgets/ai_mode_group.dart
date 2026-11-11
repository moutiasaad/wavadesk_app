import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/data.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../account/channels_screen.dart' show webPanelPage;
import '../../domain/ai_agent_config.dart';
import '../../domain/readiness.dart';
import '../ai_save_feedback.dart';
import '../sheets/ai_confirm_sheets.dart';

String aiModeTitle(AppLocalizations l, AiMode m) => switch (m) {
      AiMode.suggest => l.ai_mode_suggest,
      AiMode.hybrid => l.ai_mode_hybrid,
      AiMode.auto || AiMode.afterHours => l.ai_mode_auto,
    };

/// The web panel's four AI modes: Off, Suggestion, Autonomous, Hybrid.
enum _WebMode { off, suggest, auto, hybrid }

/// "AI mode" radio rows, same choices and wording as the web settings page.
/// Off = the master switch. Where the server can't save Hybrid yet, that row
/// opens the web settings page instead.
class AiModeGroup extends ConsumerWidget {
  const AiModeGroup({super.key, required this.config, required this.interactive});

  final AiAgentConfig config;

  /// Editable (admin, plan allows AI) — also while the AI is off, so a mode
  /// can switch it back on.
  final bool interactive;

  _WebMode get _current {
    if (!config.enabled) return _WebMode.off;
    return switch (config.mode) {
      AiMode.suggest => _WebMode.suggest,
      AiMode.hybrid => _WebMode.hybrid,
      AiMode.auto || AiMode.afterHours => _WebMode.auto,
    };
  }

  Future<void> _select(BuildContext context, WidgetRef ref, _WebMode pick) async {
    final l = context.l10n;
    if (pick == _current) return;

    if (pick == _WebMode.off) {
      if (!await showAiOffConfirm(context, handling: config.handlingNow) || !context.mounted) return;
      Analytics.log('ai_toggle', {'enabled': false, 'handling_now': config.handlingNow});
      await saveAiChange(context, ref, (c) => c.copyWith(enabled: false), successMessage: l.ai_hero_off);
      return;
    }
    if (pick == _WebMode.hybrid && !config.serverHasWebSettings) {
      // This server can't save Hybrid yet: set it on the web panel.
      final role = ref.read(currentAgentProvider).role;
      final ok = await launchUrl(webPanelPage(role, 'ai-settings'), mode: LaunchMode.externalApplication);
      if (context.mounted) AppSnackbar.show(context, message: ok ? l.ai_mode_hybrid_on_web : l.channels_open_web_failed);
      return;
    }

    final mode = switch (pick) {
      _WebMode.suggest => AiMode.suggest,
      _WebMode.hybrid => AiMode.hybrid,
      _ => AiMode.auto,
    };
    // Turning the AI on needs a knowledge base, as on the web.
    if (!Readiness.of(config).kbReady && (!config.enabled || mode != AiMode.suggest)) {
      AppSnackbar.show(context, message: l.ai_mode_needs_ready);
      return;
    }
    // Sending on its own asks for confirmation the first time.
    if (mode != AiMode.suggest && !config.autoConfirmed) {
      final ok = await showAutoReplyConfirm(
        context,
        tested: config.readiness.tested,
        onTryNow: () => context.push(Routes.aiAgentTest),
      );
      if (!ok || !context.mounted) return;
    }
    Analytics.log('ai_mode_change', {'from': _current.name, 'to': pick.name, 'tested': config.readiness.tested});
    await saveAiChange(
      context,
      ref,
      (c) => c.copyWith(enabled: true, mode: mode, autoConfirmed: mode == AiMode.suggest ? null : true),
      successMessage: l.ai_mode_changed(aiModeTitle(l, mode)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final current = _current;
    final rows = [
      (_WebMode.off, l.ai_mode_off, l.ai_mode_off_sub, false),
      (_WebMode.suggest, l.ai_mode_suggest, l.ai_mode_suggest_sub, false),
      (_WebMode.auto, l.ai_mode_auto, l.ai_mode_auto_sub, true),
      (_WebMode.hybrid, l.ai_mode_hybrid, l.ai_mode_hybrid_sub, false),
    ];
    return SettingsGroup(
      title: l.ai_mode,
      children: [
        Semantics(
          container: true,
          label: l.ai_mode,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.divider),
                _ModeRow(
                  title: rows[i].$2,
                  subtitle: rows[i].$3,
                  subtitle2: rows[i].$1 == _WebMode.hybrid && !config.serverHasWebSettings ? l.ai_mode_set_on_web : null,
                  recommended: rows[i].$4,
                  selected: current == rows[i].$1,
                  onTap: interactive ? () => _select(context, ref, rows[i].$1) : null,
                ),
              ],
            ],
          ),
        ),
        // Same note as the web page under Autonomous.
        if (current == _WebMode.auto)
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.successContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.success.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.ai, dp: 16, color: c.textSuccess),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l.ai_mode_auto_info, style: context.text.bodySmall.copyWith(color: c.textPrimary))),
              ],
            ),
          ),
      ],
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.title,
    required this.subtitle,
    this.subtitle2,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? subtitle2;
  final bool recommended;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final reduced = AppMotion.reduced(context);
    final dur = reduced ? Duration.zero : AppMotion.fast;
    final ring = c.isDark ? const Color(0xFF2BB8AD) : c.primary;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      enabled: onTap != null,
      label: '$title، $subtitle',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: dur,
        color: selected ? (c.isDark ? const Color(0xFF0F2E2D) : c.primaryContainer) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Row(
              children: [
                // 22 circle; selected = 7dp primary ring (§4.4), scale 0.6→1.
                SizedBox.square(
                  dimension: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderStrong, width: 2))),
                      AnimatedScale(
                        scale: selected ? 1 : 0.6,
                        duration: dur,
                        child: AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: dur,
                          child: Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface, border: Border.all(color: ring, width: 7)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        children: [
                          Text(title, style: t.listTitle),
                          if (recommended)
                            // Sized to its label: an `alignment` here made the
                            // pill stretch across the whole card.
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.primaryContainer,
                                border: Border.all(color: c.primaryContainerBorder),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(AppIcons.ai, dp: 12, color: c.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    l.ai_recommended,
                                    style: t.caption.copyWith(fontSize: 11, height: 1.3, color: c.onPrimaryContainer, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: t.bodySmall.copyWith(color: c.textSecondary)),
                      if (subtitle2 != null) Text(subtitle2!, style: t.caption.copyWith(color: c.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
