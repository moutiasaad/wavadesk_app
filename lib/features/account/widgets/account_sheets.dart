import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_session.dart';
import '../subscription_info.dart';

// ---- Away with open chats (§4.2) --------------------------------------------

enum AwayChoice { release, keep }

/// "لديك {n} محادثات مفتوحة": return them to unassigned / keep them / cancel
/// (null).
Future<AwayChoice?> showAwayOpenChatsSheet(BuildContext context, {required int count}) {
  final l = context.l10n;
  return AppBottomSheet.show<AwayChoice>(
    context,
    title: l.acc_away_open_title(count),
    subtitle: l.acc_away_open_body,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: l.acc_away_release,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.pop(ctx, AwayChoice.release),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.acc_away_keep,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.pop(ctx, AwayChoice.keep),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: l.common_cancel,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}

// ---- Sign out (§6.1) ----------------------------------------------------------

/// Confirm sheet: red tile, "تسجيل الخروج؟", body, the open-chats line when
/// [openChats] > 0, red filled button (loading while signing out) + cancel.
/// Signing out always clears this device, even when the server call fails.
Future<void> showSignOutSheet(BuildContext context, WidgetRef ref, {int openChats = 0}) {
  return AppBottomSheet.show<void>(context, showClose: false, builder: (_) => _SignOutBody(openChats: openChats));
}

class _SignOutBody extends ConsumerStatefulWidget {
  const _SignOutBody({required this.openChats});

  final int openChats;

  @override
  ConsumerState<_SignOutBody> createState() => _SignOutBodyState();
}

class _SignOutBodyState extends ConsumerState<_SignOutBody> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    await ref.read(authProvider.notifier).signOut();
    if (nav.mounted && nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final red = c.isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.isDark ? const Color(0xFF2A1218) : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AppIcon(AppIcons.logout, dp: 24, color: red),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.acc_logout_title,
            textAlign: TextAlign.center,
            style: t.h4.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.acc_logout_body,
            textAlign: TextAlign.center,
            style: t.bodyMedium.copyWith(fontSize: 14, color: c.textSecondary),
          ),
          if (widget.openChats > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.acc_logout_open(widget.openChats),
              textAlign: TextAlign.center,
              style: t.bodyMedium.copyWith(fontSize: 14, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            button: true,
            label: l.account_logout,
            hint: l.acc_logout_body,
            excludeSemantics: true,
            child: AppButton(
              label: l.account_logout,
              variant: AppButtonVariant.destructiveFilled,
              height: 48,
              expand: true,
              loading: _busy,
              onPressed: _busy ? null : _confirm,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: l.common_cancel,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: _busy ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ---- Plan (§6.3) ----------------------------------------------------------------

/// Plan name + badge, trial progress, usage bars (seats, AI replies) and
/// "إدارة الاشتراك" → the web billing page. Admins who can't manage billing
/// see it read-only.
Future<void> showPlanSheet(BuildContext context, {required SubscriptionInfo info, required bool canManage}) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.account_subscription,
    builder: (ctx) => _PlanBody(info: info, canManage: canManage),
  );
}

/// Days left on a trial (ceil), or null when not on trial / no end date.
int? trialDaysLeft(SubscriptionInfo s) {
  final end = s.endsAt;
  if (!s.onTrial || end == null) return null;
  final left = end.difference(DateTime.now());
  return left.isNegative ? 0 : (left.inHours / 24).ceil();
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.info, required this.canManage});

  final SubscriptionInfo info;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final days = trialDaysLeft(info);
    final (badge, fg, bg) = info.onTrial
        ? (l.acc_plan_badge_trial, c.textWarning, c.warningContainer)
        : (l.acc_plan_badge_active, c.textSuccess, c.successContainer);

    Widget usage(String label, int used, int? limit) {
      final unlimited = limit == null;
      final ratio = unlimited || limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                ),
                Text(
                  unlimited ? l.acc_plan_unlimited : '$used / $limit',
                  textDirection: TextDirection.ltr,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w600, color: c.textSecondary),
                ),
              ],
            ),
            if (!unlimited) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: c.surfaceVariant,
                  color: ratio >= 0.9 ? c.error : c.primary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                info.planName ?? '—',
                textDirection: TextDirection.ltr,
                style: t.h4.copyWith(fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(badge, style: t.tagLabel.copyWith(color: fg)),
              ),
            ],
          ),
          if (days != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l.acc_plan_days_left(days),
              style: t.bodySmall.copyWith(color: days <= 2 ? c.textError : c.textSecondary),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                // Trials run 14 days; the bar shows what's left of them.
                value: (days / 14).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: c.surfaceVariant,
                color: days <= 2 ? c.error : c.warning,
              ),
            ),
          ],
          usage(l.acc_plan_seats, info.seatsUsed, info.seatsLimit),
          if (info.aiLimit != 0) usage(l.acc_plan_ai, info.aiUsed, info.aiLimit),
          const SizedBox(height: AppSpacing.lg),
          if (canManage && info.manageUrl != null)
            AppButton(
              label: l.acc_plan_manage,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => openExternal(context, Uri.parse(info.manageUrl!)),
            )
          else if (!canManage)
            Text(
              l.acc_plan_readonly,
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: c.textTertiary),
            ),
        ],
      ),
    );
  }
}

/// Opens [uri] outside the app (browser / WhatsApp / mail); snackbar when
/// nothing can handle it.
Future<void> openExternal(BuildContext context, Uri uri, {bool inApp = false}) async {
  final l = context.l10n;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: inApp ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) AppSnackbar.show(context, message: l.acc_open_failed, kind: SnackKind.error);
}

// ---- Language / theme (§4.6) ------------------------------------------------------

/// Radios for the app languages (the app ships ar / en / fr).
void showLanguageSheet(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final current = ref.read(settingsProvider).locale.languageCode;
  AppBottomSheet.show<void>(
    context,
    title: l.account_language,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (final (code, label) in const [('ar', 'العربية'), ('en', 'English'), ('fr', 'Français')])
            AppRadioRow(
              label: label,
              selected: current == code,
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(Locale(code));
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    ),
  );
}

String themeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
  ThemeMode.light => l.account_theme_light,
  ThemeMode.dark => l.account_theme_dark,
  ThemeMode.system => l.account_theme_system,
};

/// تلقائي / فاتح / داكن, applied at once.
void showThemeSheet(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final current = ref.read(settingsProvider).themeMode;
  AppBottomSheet.show<void>(
    context,
    title: l.account_appearance,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (final m in const [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
            AppRadioRow(
              label: themeLabel(l, m),
              subtitle: m == ThemeMode.system ? l.account_theme_system_sub : null,
              selected: current == m,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode(m);
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    ),
  );
}
