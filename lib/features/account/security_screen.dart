import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wd_api_provider.dart';
import '../../core/data/data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import '../auth/application/auth_session.dart';
import '../auth/data/biometric_service.dart';
import '../conversations/domain/relative_time_formatter.dart';
import 'channels_screen.dart' show webPanelPage;
import 'widgets/account_sheets.dart';

/// One signed-in device from `GET auth/sessions`.
@immutable
class _Device {
  const _Device({required this.id, required this.name, required this.platform, this.lastSeen, this.current = false});

  factory _Device.fromJson(Map<String, dynamic> j) => _Device(
    id: '${j['id']}',
    name: '${j['device_name'] ?? j['model'] ?? ''}'.trim(),
    platform: '${j['platform'] ?? ''}',
    lastSeen: j['last_seen_at'] is String ? DateTime.tryParse(j['last_seen_at'] as String)?.toLocal() : null,
    current: j['current'] == true,
  );

  final String id;
  final String name;
  final String platform;
  final DateTime? lastSeen;
  final bool current;
}

final _devicesProvider = FutureProvider.autoDispose<List<_Device>>((ref) async {
  final r = await ref.watch(wdApiRequiredProvider).get('auth/sessions');
  return [for (final row in r.list) _Device.fromJson(Map<String, dynamic>.from(row))];
});

/// الأمان (Account §5.3): password (changed on the web panel — the mobile
/// API has no password endpoint), biometric sign-in, signed-in devices with
/// per-device and "all other devices" sign-out.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  late bool _biometric = ref.read(authRepositoryProvider).biometricEnabled;
  final Set<String> _busy = {};

  Future<void> _toggleBiometric(bool on) async {
    final l = context.l10n;
    final repo = ref.read(authRepositoryProvider);
    if (on) {
      final svc = ref.read(biometricServiceProvider);
      if (await svc.availableKind() == null) {
        if (mounted) AppSnackbar.show(context, message: l.sec_biometric_unavailable, kind: SnackKind.error);
        return;
      }
      if (await svc.authenticate(l.sec_biometric_reason) != BiometricResult.success) return;
    }
    await repo.setBiometricEnabled(on);
    if (mounted) setState(() => _biometric = on);
  }

  Future<void> _revoke(_Device d) async {
    final l = context.l10n;
    setState(() => _busy.add(d.id));
    try {
      await ref.read(wdApiRequiredProvider).delete('auth/sessions/${d.id}');
      ref.invalidate(_devicesProvider);
      if (mounted) AppSnackbar.show(context, message: l.sec_logout_done, kind: SnackKind.success);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.prof_save_failed, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy.remove(d.id));
    }
  }

  Future<void> _revokeOthers(List<_Device> devices) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.sec_logout_others,
      body: l.sec_logout_others_body,
      confirmLabel: l.sec_device_logout,
      icon: AppIcons.logout,
    );
    if (!ok || !mounted) return;
    final api = ref.read(wdApiRequiredProvider);
    final others = devices.where((d) => !d.current).toList();
    setState(() => _busy.addAll(others.map((d) => d.id)));
    // `auth/logout-all` would sign this device out too: revoke one by one.
    await Future.wait([for (final d in others) api.delete('auth/sessions/${d.id}').then((_) {}, onError: (_) {})]);
    ref.invalidate(_devicesProvider);
    if (!mounted) return;
    setState(() => _busy.clear());
    AppSnackbar.show(context, message: l.sec_logout_done, kind: SnackKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);
    final devices = ref.watch(_devicesProvider);
    final now = DateTime.now();
    final (grBg, grFg) = c.isDark
        ? (const Color(0xFF1C272C), const Color(0xFF93A3AB))
        : (const Color(0xFFF1F4F6), const Color(0xFF475569));

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: l.acc_security),
      body: ListView(
        // The first group has no title, so it needs its own gap under the app bar.
        padding: EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          SettingsGroup(
            children: [
              SettingsTile(
                icon: AppIcons.password,
                iconBackground: grBg,
                iconColor: grFg,
                title: l.sec_change_pw,
                subtitle: l.sec_change_pw_sub,
                onTap: () => openExternal(context, webPanelPage(me.role, 'profile')),
              ),
              SettingsTile(
                icon: AppIcons.faceId,
                iconBackground: grBg,
                iconColor: grFg,
                title: l.sec_biometric,
                trailing: AppSwitch(value: _biometric, semanticLabel: l.sec_biometric, onChanged: _toggleBiometric),
              ),
            ],
          ),
          devices.when(
            loading: () => SettingsGroup(
              title: l.sec_devices,
              children: const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: AppSpinner(size: 22)),
                ),
              ],
            ),
            error: (_, _) => SettingsGroup(
              title: l.sec_devices,
              children: [
                SettingsTile(
                  title: l.sec_devices_failed,
                  value: l.common_retry,
                  onTap: () => ref.invalidate(_devicesProvider),
                ),
              ],
            ),
            data: (list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsGroup(
                  title: l.sec_devices,
                  children: [
                    for (final d in list)
                      SettingsTile(
                        icon: AppIcons.device,
                        iconBackground: grBg,
                        iconColor: grFg,
                        title: d.name.isEmpty ? d.platform : d.name,
                        subtitle: d.lastSeen == null
                            ? d.platform
                            : l.sec_last_active(RelativeTimeFormatter.format(d.lastSeen!, now, l, context.localeName)),
                        trailing: d.current
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(l.sec_this_device, style: t.tagLabel.copyWith(color: c.primary)),
                              )
                            : _busy.contains(d.id)
                            ? const AppSpinner(size: 18)
                            : TextButton(
                                onPressed: () => _revoke(d),
                                style: TextButton.styleFrom(
                                  foregroundColor: c.textError,
                                  textStyle: t.buttonSmall,
                                  minimumSize: const Size(48, 40),
                                ),
                                child: Text(l.sec_device_logout),
                              ),
                      ),
                  ],
                ),
                if (list.any((d) => !d.current))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppButton(
                      label: l.sec_logout_others,
                      variant: AppButtonVariant.destructive,
                      expand: true,
                      onPressed: _busy.isNotEmpty ? null : () => _revokeOthers(list),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
