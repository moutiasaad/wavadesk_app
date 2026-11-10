import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import 'subscription_info.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Reopening shows the kept copy at once and refreshes it quietly.
    if (ref.exists(subscriptionInfoProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(subscriptionInfoProvider);
      });
    }
  }

  Future<void> _openBilling(String? url) async {
    final l = context.l10n;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) AppSnackbar.show(context, message: l.subscription_upgrade_web);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;

    Widget body;
    final async = ref.watch(subscriptionInfoProvider);
    final info = async.valueOrNull;
    if (info != null) {
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: () => ref.refresh(subscriptionInfoProvider.future).then((_) {}, onError: (_) {
          if (context.mounted) AppSnackbar.show(context, message: l.account_load_error, kind: SnackKind.error);
        }),
        child: _realBody(context, info),
      );
    } else if (async.hasError) {
      body = EmptyState(
        icon: AppIcons.offline,
        title: l.account_load_error,
        actionLabel: l.common_retry,
        onAction: () => ref.invalidate(subscriptionInfoProvider),
      );
    } else {
      body = AppSkeleton.list(rows: 5);
    }

    return ScrolledUnderBuilder(
      builder: (context, under) => Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(title: l.subscription_title, scrolledUnder: under, background: c.backgroundMuted),
        body: body,
      ),
    );
  }

  Widget _realBody(BuildContext context, SubscriptionInfo s) {
    final l = context.l10n;
    final price = s.priceAmount == null
        ? null
        : l.subscription_per_month('${s.priceAmount}${s.priceCurrency == null ? '' : ' ${s.priceCurrency}'}');
    final String? footer;
    if (s.onTrial && s.endsAt != null) {
      footer = l.subscription_trial_ends(AppFormat.date(context, s.endsAt!));
    } else if (s.renewsAt != null) {
      footer = l.subscription_renews(AppFormat.date(context, s.renewsAt!));
    } else if (s.endsAt != null) {
      footer = l.subscription_ends(AppFormat.date(context, s.endsAt!));
    } else {
      footer = null;
    }
    return _layout(
      context,
      planName: s.planName ?? l.subscription_no_plan,
      price: s.onTrial ? l.subscription_trial : price,
      footer: footer,
      meters: [
        // 0 = the plan has no AI replies: no meter.
        if (s.aiLimit != 0) _meter(context, l.subscription_ai_replies, s.aiUsed, s.aiLimit),
        _meter(context, l.subscription_agents, s.seatsUsed, s.seatsLimit),
      ],
      onBilling: () => _openBilling(s.manageUrl),
    );
  }

  /// [total] null = unlimited (no bar).
  Widget _meter(BuildContext context, String label, int used, int? total) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ratio = total == null || total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: t.listTitle.copyWith(fontSize: 14.5))),
              Text(
                total == null
                    ? l.subscription_usage(AppFormat.number(context, used), l.subscription_unlimited)
                    : l.subscription_usage(AppFormat.number(context, used), AppFormat.number(context, total)),
                style: t.bodySmall.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: ratio > 0.9 ? c.error : c.primary,
                backgroundColor: c.surfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _layout(
    BuildContext context, {
    required String planName,
    required String? price,
    required String? footer,
    required List<Widget> meters,
    required VoidCallback onBilling,
  }) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: context.shadows.primaryGlow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.subscription_current, style: t.caption.copyWith(color: c.onPrimary.withValues(alpha: 0.8))),
              const SizedBox(height: AppSpacing.xs),
              Text(planName, style: t.h2.copyWith(color: c.onPrimary)),
              if (price != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(price, style: t.bodyMedium.copyWith(color: c.onPrimary)),
              ],
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(footer, style: t.caption.copyWith(color: c.onPrimary.withValues(alpha: 0.8))),
              ],
            ],
          ),
        ),
        SettingsGroup(title: l.subscription_section_usage, children: meters),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
          child: Column(
            children: [
              AppButton(
                label: l.subscription_upgrade,
                icon: AppIcons.quickReply,
                size: AppButtonSize.large,
                expand: true,
                onPressed: onBilling,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l.subscription_invoices,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                expand: true,
                onPressed: onBilling,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
