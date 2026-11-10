import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/wd_api.dart' show useRealApi;
import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../application/whatsapp_channel_controller.dart';
import '../data/whatsapp_api.dart' show WaDemoScenario;
import '../domain/wa_channel.dart';
import '../domain/wa_status.dart';
import 'sheets/wa_connection_log_sheet.dart';
import 'wa_links.dart';
import 'widgets/wa_advanced_group.dart';
import 'widgets/wa_auto_messages_group.dart';
import 'widgets/wa_connection_card.dart';
import 'widgets/wa_disconnect_button.dart';
import 'widgets/wa_numbers_group.dart';
import 'widgets/wa_status_alert.dart';
import 'widgets/wa_templates_section.dart';

/// واتساب الخاص بك — `/settings/whatsapp` (WhatsApp spec "14 WhatsApp.md").
class WhatsAppChannelScreen extends ConsumerStatefulWidget {
  const WhatsAppChannelScreen({super.key});

  @override
  ConsumerState<WhatsAppChannelScreen> createState() => _WhatsAppChannelScreenState();
}

enum _Menu { refresh, log, help, demo }

class _WhatsAppChannelScreenState extends ConsumerState<WhatsAppChannelScreen> {
  late final WhatsAppChannelController _ctrl;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ref.read(whatsAppChannelControllerProvider.notifier);
    _ctrl.startPolling();
    // Fresh status on every visit (the provider outlives the screen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(whatsAppChannelControllerProvider).channel != null) _ctrl.load(silent: true);
    });
  }

  @override
  void dispose() {
    _ctrl.stopPolling();
    super.dispose();
  }

  Future<void> _demo() async {
    final picked = await AppBottomSheet.show<WaDemoScenario>(
      context,
      title: context.l10n.wa_demo_state,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in WaDemoScenario.values)
            AppRadioRow(label: s.name, selected: false, onTap: () => Navigator.of(ctx).pop(s)),
        ],
      ),
    );
    if (picked != null) await _ctrl.setDemoScenario(picked);
  }

  void _onMenu(_Menu m) {
    switch (m) {
      case _Menu.refresh:
        _ctrl.refreshStatus();
      case _Menu.log:
        showWaConnectionLogSheet(context);
      case _Menu.help:
        WaLinks.help();
      case _Menu.demo:
        _demo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final state = ref.watch(whatsAppChannelControllerProvider);
    final ch = state.channel;
    final me = ref.watch(currentAgentProvider);

    if (ch != null && !_logged) {
      _logged = true;
      Analytics.log('wa_view', {'status': ch.status.wire, 'type': ch.connectionType.wire, 'role': me.role.name});
    }

    final admin = ch?.permissions.isAdmin ?? false;

    Widget body;
    if (ch == null && state.error != null) {
      body = EmptyState(
        icon: state.offline ? AppIcons.wifiOff : AppIcons.alert,
        title: l.wa_load_error,
        actionLabel: l.wa_retry,
        onAction: _ctrl.load,
      );
    } else if (ch == null) {
      body = const _Skeleton();
    } else if (!ch.planHasWhatsApp) {
      body = _PlanUpsell(channel: ch);
    } else {
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: () => _ctrl.load(silent: true),
        child: ListView(
          padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom),
          children: [
            WaConnectionCard(channel: ch, flashTick: state.statusFlash, offline: state.offline),
            for (final a in waAlerts(ch)) WaStatusAlert(kind: a, channel: ch),
            WaAutoMessagesGroup(channel: ch),
            if (ch.isCloud && ch.templatesSupported) const WaTemplatesSection(limit: 4),
            if (admin || !ch.isPending) WaNumbersGroup(channel: ch),
            if (ch.permissions.canEditAdvanced && !ch.isPending) WaAdvancedGroup(channel: ch),
            if (ch.permissions.canDisconnect && !ch.isPending) WaDisconnectButton(channel: ch) else const SizedBox(height: AppSpacing.lg),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.wa_title,
        background: c.backgroundMuted,
        actions: [
          if (admin || !useRealApi)
            PopupMenuButton<_Menu>(
              icon: Icon(AppIcons.more, color: c.textPrimary),
              tooltip: l.wa_more,
              onSelected: _onMenu,
              itemBuilder: (_) => [
                if (admin) PopupMenuItem(value: _Menu.refresh, child: Text(l.wa_refresh)),
                if (admin) PopupMenuItem(value: _Menu.log, child: Text(l.wa_log)),
                PopupMenuItem(value: _Menu.help, child: Text(l.wa_help)),
                if (!useRealApi) PopupMenuItem(value: _Menu.demo, child: Text(l.wa_demo_state)),
              ],
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            ConnectionBanner(state: state.offline && ch != null ? NetworkState.offline : NetworkState.online),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// §7 "Plan without WhatsApp".
class _PlanUpsell extends StatelessWidget {
  const _PlanUpsell({required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EmptyState(
      icon: AppIcons.whatsapp,
      title: l.wa_plan_title,
      body: l.wa_plan_body,
      actionLabel: channel.permissions.isAdmin ? l.wa_view_plans : null,
      actionVariant: AppButtonVariant.primary,
      onAction: channel.permissions.isAdmin ? () => WaLinks.billing(channel.upgradeUrl) : null,
    );
  }
}

/// Loading (§7): card skeleton (tile + 2 lines + 3 stat blocks) + groups.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    BoxDecoration card() => BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: c.border),
        );
    Widget group(double h) => Container(
          height: h,
          margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
          padding: const EdgeInsets.all(14),
          decoration: card(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [SkeletonBox(width: 150, height: 12), SizedBox(height: 14), SkeletonBox(width: 220, height: 10)],
          ),
        );
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: card(),
            child: const Column(
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 52, height: 52, circle: true),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SkeletonBox(width: 120, height: 14), SizedBox(height: 8), SkeletonBox(width: 150, height: 11)],
                      ),
                    ),
                    SkeletonBox(width: 64, height: 28, radius: AppRadius.full),
                  ],
                ),
                SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(child: Column(children: [SkeletonBox(width: 40, height: 16), SizedBox(height: 6), SkeletonBox(width: 60, height: 10)])),
                    Expanded(child: Column(children: [SkeletonBox(width: 40, height: 16), SizedBox(height: 6), SkeletonBox(width: 60, height: 10)])),
                    Expanded(child: Column(children: [SkeletonBox(width: 40, height: 16), SizedBox(height: 6), SkeletonBox(width: 60, height: 10)])),
                  ],
                ),
              ],
            ),
          ),
          group(190),
          group(130),
        ],
      ),
    );
  }
}
