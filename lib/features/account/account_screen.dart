import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/data.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import '../auth/application/auth_session.dart';
import '../shell/home_shell.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const version = '1.0.0';

  String _themeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
        ThemeMode.light => l.account_theme_light,
        ThemeMode.dark => l.account_theme_dark,
        ThemeMode.system => l.account_theme_system,
      };

  void _pickLanguage(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.read(settingsProvider).locale.languageCode;
    AppBottomSheet.show<void>(
      context,
      title: l.account_language,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            for (final (code, label) in const [('ar', 'العربية'), ('en', 'English')])
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

  void _pickTheme(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.read(settingsProvider).themeMode;
    AppBottomSheet.show<void>(
      context,
      title: l.account_appearance,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            for (final m in const [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
              AppRadioRow(
                label: _themeLabel(l, m),
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

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.account_logout_title,
      body: l.account_logout_body,
      confirmLabel: l.account_logout,
      icon: AppIcons.logout,
    );
    if (ok) ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);
    final settings = ref.watch(settingsProvider);
    final whatsapp = ref.watch(whatsappProvider);

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarLarge(title: l.tab_account, background: c.backgroundMuted),
      body: ListView(
        padding: EdgeInsets.only(bottom: tabBarInset(context)),
        children: [
          // Profile card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AppAvatar(
                      name: me.name,
                      id: me.id,
                      size: AppAvatarSize.lg,
                      presence: me.presence,
                      ringColor: c.surface,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(me.name, style: t.h5),
                          Text(
                            ltr(me.email),
                            style: t.bodySmall.copyWith(color: c.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Role pill at the row's end, beside name + email (mockup).
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(me.role.label(l), style: t.tagLabel.copyWith(color: c.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSegmented<Presence>(
                  selected: me.presence,
                  onChanged: ref.read(settingsProvider.notifier).setPresence,
                  segments: [
                    AppSegment(value: Presence.online, label: l.presence_online, selectedColor: c.successContainer),
                    AppSegment(value: Presence.busy, label: l.presence_busy, selectedColor: c.warningContainer),
                    AppSegment(value: Presence.away, label: l.presence_away),
                  ],
                ),
              ],
            ),
          ),
          if (me.canManage)
            SettingsGroup(
              title: l.account_section_admin,
              children: [
                SettingsTile(
                  icon: AppIcons.whatsapp,
                  iconColor: c.textSuccess,
                  iconBackground: c.successContainer,
                  title: l.account_whatsapp,
                  // No status until the real one arrived (no sample "متصل").
                  value: !whatsapp.loaded ? null : (whatsapp.connected ? l.account_whatsapp_connected : l.account_whatsapp_disconnected),
                  onTap: () => context.push(Routes.whatsapp),
                ),
                SettingsTile(
                  icon: AppIcons.channels,
                  iconColor: c.textInfo,
                  iconBackground: c.infoContainer,
                  title: l.account_channels,
                  onTap: () => context.push(Routes.channels),
                ),
                SettingsTile(
                  icon: AppIcons.ai,
                  title: l.account_ai_agent,
                  onTap: () => context.push(Routes.aiAgent),
                ),
                SettingsTile(
                  icon: AppIcons.team,
                  iconColor: c.statusSnoozed,
                  iconBackground: c.statusSnoozedContainer,
                  title: l.account_team,
                  onTap: () => context.push(Routes.team),
                ),
                if (me.isAdmin)
                  SettingsTile(
                    icon: AppIcons.billing,
                    iconColor: c.textWarning,
                    iconBackground: c.warningContainer,
                    title: l.account_subscription,
                    onTap: () => context.push(Routes.subscription),
                  ),
              ],
            ),
          SettingsGroup(
            title: l.account_section_app,
            children: [
              SettingsTile(
                icon: AppIcons.bell,
                title: l.account_notifications,
                onTap: () => context.push(Routes.notificationSettings),
              ),
              SettingsTile(
                icon: AppIcons.language,
                title: l.account_language,
                value: settings.locale.languageCode == 'ar' ? 'العربية' : 'English',
                onTap: () => _pickLanguage(context, ref),
              ),
              SettingsTile(
                icon: AppIcons.theme,
                title: l.account_appearance,
                value: _themeLabel(l, settings.themeMode),
                onTap: () => _pickTheme(context, ref),
              ),
              SettingsTile(
                icon: AppIcons.help,
                title: l.account_help,
                onTap: () => context.push(Routes.help),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.lg),
            child: AppButton(
              label: l.account_logout,
              icon: AppIcons.logout,
              variant: AppButtonVariant.destructive,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => _logout(context, ref),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                l.account_version(version),
                style: t.caption.copyWith(color: c.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
