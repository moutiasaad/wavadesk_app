import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wd_api_provider.dart';
import '../../core/data/data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import '../auth/application/auth_session.dart';
import '../auth/data/auth_api.dart';
import 'channels_screen.dart' show webPanelPage;
import 'widgets/account_sheets.dart';

/// الملف الشخصي (Account §5.1): avatar 88, name (2–50), read-only email.
/// The mobile API saves the name only (`PATCH me`); photo, phone and
/// signature are edited on the web panel.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final String _initial = ref.read(currentAgentProvider).name;
  late final _name = TextEditingController(text: _initial);
  bool _saving = false;
  String? _error;

  bool get _dirty => _name.text.trim() != _initial.trim();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final name = _name.text.trim();
    if (name.characters.length < 2 || name.characters.length > 50) {
      setState(() => _error = l.prof_name_error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(wdApiRequiredProvider).patch('me', body: {'name': name});
      final repo = ref.read(authRepositoryProvider);
      final s = repo.session;
      if (s != null) {
        await repo.saveSession(
          Session(
            accessToken: s.accessToken,
            refreshToken: s.refreshToken,
            expiresAt: s.expiresAt,
            user: {...s.user, 'name': name},
            workspace: s.workspace,
            signingSecret: s.signingSecret,
            sessionId: s.sessionId,
            permissions: s.permissions,
          ),
        );
      }
      ref.invalidate(currentAgentProvider);
      if (!mounted) return;
      AppSnackbar.show(context, message: l.prof_saved, kind: SnackKind.success);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(context, message: l.prof_save_failed, kind: SnackKind.error);
      }
    }
  }

  Future<bool> _confirmDiscard() {
    final l = context.l10n;
    return AppDialog.confirm(
      context,
      title: l.prof_discard,
      body: l.prof_discard_body,
      confirmLabel: l.prof_discard_ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(
          title: l.prof_title,
          actions: [AppBarTextAction(label: l.prof_save, onPressed: _dirty && !_saving ? _save : null)],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Center(
              child: AppAvatar(name: me.name, id: me.id, imageUrl: me.avatarUrl, size: AppAvatarSize.xxl),
            ),
            Center(
              child: TextButton(
                onPressed: () => openExternal(context, webPanelPage(me.role, 'profile')),
                style: TextButton.styleFrom(
                  foregroundColor: c.primary,
                  textStyle: t.buttonSmall,
                  minimumSize: const Size(48, 44),
                ),
                child: Text(l.prof_photo_web),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l.prof_name,
              controller: _name,
              error: _error,
              maxLength: 50,
              textInputAction: TextInputAction.done,
              enabled: !_saving,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _dirty ? _save() : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l.prof_email,
              controller: TextEditingController(text: me.email),
              enabled: false,
              textDirection: TextDirection.ltr,
              suffix: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: AppIcon(AppIcons.lock, dp: 16, color: c.textTertiary),
              ),
              helper: l.prof_email_locked,
            ),
          ],
        ),
      ),
    );
  }
}
