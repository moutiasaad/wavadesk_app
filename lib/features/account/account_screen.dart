import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api/wd_api.dart';
import '../../core/data/data.dart';
import '../../core/data/team_directory.dart';
import '../../core/models/models.dart';
import '../../core/notifications/push_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/icons/wd_svg_icons.dart';
import '../../core/widgets/widgets.dart';
import '../ai_agent/application/ai_agent_controller.dart';
import '../ai_agent/domain/ai_agent_config.dart';
import '../channels/whatsapp/application/whatsapp_channel_controller.dart';
import '../channels/whatsapp/domain/wa_status.dart';
import '../dashboard/application/presence_controller.dart';
import '../dashboard/presentation/dash_palette.dart';
import '../dashboard/presentation/widgets/dashboard_teal_header.dart';
import '../shell/home_shell.dart';
import 'subscription_info.dart';
import 'widgets/account_header.dart';
import 'widgets/account_online.dart';
import 'widgets/account_sheets.dart';
import 'widgets/delete_account_sheet.dart';
import 'widgets/presence_card.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// Support contact (no Wavadesk support WhatsApp number in the app: email).
final _supportUri = Uri(scheme: 'mailto', path: 'support@wavadesk.com');
final _termsUri = Uri.parse('https://wavadesk.com/legal/terms');

/// الحساب والإعدادات — tab root (spec "15 Account.md"): teal header that
/// scrolls away (white compact bar fades in), حالتي card, الإدارة (role
/// rules), التطبيق, حول التطبيق, red-outline sign out.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  bool _collapsed = false;
  int _versionTaps = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Fresh row values each time the tab is built (quiet: cached values stay).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final me = ref.read(currentAgentProvider);
      if (me.canManage) ref.read(teamDirectoryProvider.notifier).refresh();
      if (me.isAdmin) {
        ref.read(whatsAppChannelControllerProvider.notifier).load(silent: true);
        ref.read(aiAgentControllerProvider.notifier).refreshIfStale();
        ref.invalidate(subscriptionInfoProvider);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final header = _headerKey.currentContext?.size?.height ?? 120;
    final top = MediaQuery.viewPaddingOf(context).top;
    final collapsed = _scroll.offset >= header - top - 52;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  Future<void> _signOut() async {
    final presence = ref.read(presenceControllerProvider).presence;
    final open = presence == Presence.online ? await myOpenChatsCount(ref) : 0;
    if (!mounted) return;
    await showSignOutSheet(context, ref, openChats: open);
  }

  void _tapVersion(PackageInfo? info) {
    if (++_versionTaps < 7) return;
    _versionTaps = 0;
    final me = ref.read(currentAgentProvider);
    final debug = [
      'Wavadesk ${info?.version ?? '?'} (${info?.buildNumber ?? '?'})',
      'user ${me.id} · ${me.role.name}',
      'api $apiBaseUrl',
      'locale ${Localizations.localeOf(context).toLanguageTag()}',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: debug));
    AppSnackbar.show(context, message: context.l10n.acc_debug_copied, kind: SnackKind.success);
  }

  // ---- row values ----------------------------------------------------------------

  /// (value, color, badge) for "واتساب الخاص بك"; null value = still loading.
  (String?, Color?, Color?) _whatsapp(AppLocalizations l, AppColors c) {
    final s = ref.watch(whatsAppChannelControllerProvider);
    final ch = s.channel;
    if (ch == null) {
      if (s.loading || (s.error == null && !s.offline)) return (null, null, null);
      return s.error != null ? ('—', null, null) : (l.acc_wa_pending, c.textSecondary, null);
    }
    final dark = c.isDark;
    final green = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    final red = dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    final amber = dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    return switch (ch.status) {
      WaStatus.connected || WaStatus.syncing => (l.acc_wa_connected, green, null),
      WaStatus.connecting => (l.acc_wa_connecting, c.textSecondary, null),
      WaStatus.phoneOffline => (l.acc_wa_phone_off, amber, null),
      WaStatus.disconnected || WaStatus.restricted => (l.acc_wa_disconnected, red, red),
      WaStatus.pending => (l.acc_wa_pending, c.textSecondary, null),
    };
  }

  String? _ai(AppLocalizations l) {
    final cfg = ref.watch(aiAgentControllerProvider).config;
    if (cfg == null) return null;
    if (!cfg.enabled || !cfg.planAllowsAi) return l.acc_ai_off;
    return switch (cfg.mode) {
      AiMode.suggest => l.acc_ai_suggest,
      AiMode.hybrid => l.acc_ai_hybrid,
      AiMode.auto || AiMode.afterHours => l.acc_ai_on,
    };
  }

  /// (subtitle, red?) for "الاشتراك"; subtitle null while loading.
  (String?, bool) _plan(AppLocalizations l) {
    final info = ref.watch(subscriptionInfoProvider).valueOrNull;
    if (info == null) return (null, false);
    final plan = info.planName ?? '—';
    final days = trialDaysLeft(info);
    if (days != null) return (days == 0 ? l.acc_plan_trial_ended(plan) : l.acc_plan_trial(plan, days), days <= 2);
    return (l.acc_plan_active(plan), false);
  }

  (String, Color?) _notifications(AppLocalizations l, AppColors c) {
    if (ref.watch(pushPermissionProvider) == PushPermission.denied) {
      return (l.acc_notif_denied, c.isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48));
    }
    final s = ref.watch(settingsProvider);
    if (s.notifyWaiting) return (l.acc_notif_all, null);
    if (s.notifyNewAssigned) return (l.acc_notif_assigned, null);
    if (s.notifyMentions) return (l.acc_notif_mentions, null);
    return (l.acc_notif_none, null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    final me = ref.watch(currentAgentProvider);
    final settings = ref.watch(settingsProvider);
    final online = ref.watch(accountOnlineProvider).valueOrNull ?? true;
    final reduced = AppMotion.reduced(context);
    final info = ref.watch(_packageInfoProvider).valueOrNull;

    // Icon tile palettes (§4.4, dark §11).
    final dark = c.isDark;
    final (waBg, waFg) = dark
        ? (const Color(0x2625D366), const Color(0xFF4ADE80))
        : (const Color(0xFFE8F9EF), const Color(0xFF15803D));
    final (tealBg, tealFg) = dark
        ? (const Color(0xFF0F2E2D), const Color(0xFF5EEAD4))
        : (const Color(0xFFECF7F6), const Color(0xFF0F7E7A));
    final (amBg, amFg) = dark
        ? (const Color(0xFF2A2010), const Color(0xFFFBBF24))
        : (const Color(0xFFFEF3E2), const Color(0xFFB45309));
    final (grBg, grFg) = dark
        ? (const Color(0xFF1C272C), const Color(0xFF93A3AB))
        : (const Color(0xFFF1F4F6), const Color(0xFF475569));
    final red = dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);

    final admin = me.isAdmin;
    final lead = me.role == AgentRole.supervisor;

    final adminRows = <Widget>[
      if (admin)
        ...() {
          final (waValue, waColor, waBadge) = _whatsapp(l, c);
          return [
            SettingsTile(
              icon: AppIcons.whatsapp,
              iconBackground: waBg,
              iconColor: waFg,
              iconBadge: waBadge,
              title: l.account_whatsapp,
              value: waValue,
              valueColor: waColor,
              valueLoading: waValue == null,
              onTap: () => context.push(Routes.whatsapp),
            ),
            // Web parity: the web panel's channel list (Messenger, website chat…).
            SettingsTile(
              icon: AppIcons.channels,
              iconBackground: tealBg,
              iconColor: tealFg,
              title: l.account_channels,
              onTap: () => context.push(Routes.channels),
            ),
            SettingsTile(
              icon: AppIcons.ai,
              iconBackground: tealBg,
              iconColor: tealFg,
              title: l.account_ai_agent,
              value: _ai(l),
              valueLoading: _ai(l) == null,
              onTap: () => context.push(Routes.aiAgent),
            ),
          ];
        }(),
      if (admin || lead)
        SettingsTile(
          icon: AppIcons.team,
          iconBackground: tealBg,
          iconColor: tealFg,
          title: l.account_team,
          value: () {
            final dir = ref.watch(teamDirectoryProvider);
            return dir.members.isEmpty ? null : '${dir.members.length}';
          }(),
          valueLoading: ref.watch(teamDirectoryProvider).members.isEmpty,
          onTap: () => context.push(Routes.team),
        ),
      if (admin)
        ...() {
          final (planSub, planRed) = _plan(l);
          final planInfo = ref.watch(subscriptionInfoProvider).valueOrNull;
          return [
            SettingsTile(
              icon: AppIcons.star,
              iconBackground: amBg,
              iconColor: amFg,
              title: l.account_subscription,
              subtitle: planSub,
              subtitleColor: planRed ? red : null,
              valueLoading: planSub == null,
              iconBadge: planRed ? red : null,
              onTap: planInfo == null
                  ? () => context.push(Routes.subscription)
                  : () => showPlanSheet(context, info: planInfo, canManage: admin),
            ),
          ];
        }(),
    ];

    final (notifValue, notifColor) = _notifications(l, c);
    final version = info == null ? null : '${info.version} (${info.buildNumber})';

    final content = CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: KeyedSubtree(key: _headerKey, child: const AccountTealHeader()),
        ),
        if (!online)
          SliverToBoxAdapter(
            child: Container(
              color: c.warningContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                l.acc_offline,
                textAlign: TextAlign.center,
                style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.textWarning),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PresenceCard(),
                  if (adminRows.isNotEmpty) SettingsGroup(title: l.acc_sec_admin, children: adminRows),
                  SettingsGroup(
                    title: l.acc_sec_app,
                    children: [
                      SettingsTile(
                        icon: AppIcons.bell,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.account_notifications,
                        value: notifValue,
                        valueColor: notifColor,
                        onTap: () => context.push(Routes.notificationSettings),
                      ),
                      SettingsTile(
                        icon: AppIcons.globe,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.account_language,
                        value: switch (settings.locale.languageCode) {
                          'ar' => 'العربية',
                          'fr' => 'Français',
                          _ => 'English',
                        },
                        onTap: () => showLanguageSheet(context, ref),
                      ),
                      SettingsTile(
                        icon: AppIcons.theme,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.account_appearance,
                        value: themeLabel(l, settings.themeMode),
                        onTap: () => showThemeSheet(context, ref),
                      ),
                      SettingsTile(
                        icon: AppIcons.lock,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.acc_security,
                        onTap: () => context.push(Routes.security),
                      ),
                      SettingsTile(
                        icon: AppIcons.play,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.account_help,
                        onTap: () => context.push(Routes.help),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: l.acc_sec_about,
                    children: [
                      SettingsTile(
                        icon: AppIcons.file,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.acc_terms,
                        onTap: () => openExternal(context, _termsUri, inApp: true),
                      ),
                      SettingsTile(
                        icon: AppIcons.conversation,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: l.acc_contact,
                        onTap: () => openExternal(context, _supportUri),
                      ),
                      SettingsTile(
                        icon: WdSvgIcons.logo,
                        iconBackground: tealBg,
                        iconColor: tealFg,
                        title: l.acc_version,
                        value: version,
                        valueDirection: TextDirection.ltr,
                        valueLoading: version == null,
                        showChevron: false,
                        onTap: () => _tapVersion(info),
                      ),
                    ],
                  ),
                  _DangerButton(icon: AppIcons.logout, label: l.account_logout, hint: l.acc_logout_body, onTap: _signOut),
                  _DangerButton(
                    icon: AppIcons.delete,
                    label: l.del_row,
                    hint: l.del_title,
                    onTap: () => showDeleteAccountSheet(context),
                  ),
                  SizedBox(height: tabBarInset(context) + 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: p.page,
      body: Stack(
        children: [
          content,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: reduced ? Duration.zero : AppMotion.fast,
              child: _collapsed ? TealCollapsedBar(title: l.acc_title) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Red-outline destructive row (§4.7 sign out; delete account below it):
/// 48 high, radius 14, white, border `#FECDD3`, icon 16 + label 15/800 red;
/// pressed `#FFF1F2`.
class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.icon, required this.label, required this.hint, required this.onTap});

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = c.isDark;
    final red = dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: dark ? const Color(0xFF5B1B2A) : const Color(0xFFFECDD3)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Semantics(
        button: true,
        label: label,
        hint: hint,
        excludeSemantics: true,
        child: Material(
          color: dark ? const Color(0xFF151E22) : Colors.white,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            highlightColor: dark ? const Color(0xFF2A1218) : const Color(0xFFFFF1F2),
            splashColor: Colors.transparent,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(icon, dp: 16, color: red),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: context.text.buttonMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
