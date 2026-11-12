import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_session.dart';

/// "حذف الحساب": red warning, what deletion means, password (obscured, eye
/// toggle), red confirm disabled until a password is typed, cancel.
/// `DELETE me {password}` → 204 clears this device like a sign-out (the
/// server has revoked every session); errors stay in the sheet.
Future<void> showDeleteAccountSheet(BuildContext context) {
  return AppBottomSheet.show<void>(
    context,
    showClose: false,
    builder: (_) => const _DeleteAccountBody(),
  );
}

class _DeleteAccountBody extends ConsumerStatefulWidget {
  const _DeleteAccountBody();

  @override
  ConsumerState<_DeleteAccountBody> createState() => _DeleteAccountBodyState();
}

class _DeleteAccountBodyState extends ConsumerState<_DeleteAccountBody> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _fieldError;
  String? _bannerError;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _fieldError = null;
      _bannerError = null;
    });
    final nav = Navigator.of(context);
    try {
      await ref.read(wdApiRequiredProvider).delete('me', body: {'password': _password.text});
      if (nav.mounted && nav.canPop()) nav.pop();
      await ref.read(authProvider.notifier).signOutLocal();
    } on WdApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        switch (e.code) {
          case 'invalid_credentials':
            _fieldError = l.del_wrong_password;
            _password.clear();
          case 'last_admin' || 'role_forbidden':
            _bannerError = e.message ?? l.del_failed;
          case 'not_found':
            _bannerError = l.del_not_available;
          default:
            _bannerError = e.isNetwork ? l.login_err_offline : (e.message ?? l.del_failed);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bannerError = l.del_failed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final dark = c.isDark;
    final red = dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    final redBg = dark ? const Color(0xFF2A1218) : const Color(0xFFFFF1F2);
    final canConfirm = !_busy && _password.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: redBg, borderRadius: BorderRadius.circular(14)),
              child: AppIcon(AppIcons.warning, dp: 24, color: red),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.del_title,
            textAlign: TextAlign.center,
            style: t.h4.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l.del_body, textAlign: TextAlign.center, style: t.bodyMedium.copyWith(fontSize: 14, color: c.textSecondary)),
          if (_bannerError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: redBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dark ? const Color(0xFF5B1B2A) : const Color(0xFFFECDD3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(AppIcons.warning, dp: 18, color: red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_bannerError!, style: t.bodySmall.copyWith(fontWeight: FontWeight.w600, color: red))),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l.del_password,
            controller: _password,
            obscure: _obscure,
            enabled: !_busy,
            error: _fieldError,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _fieldError = null),
            onSubmitted: (_) => canConfirm ? _confirm() : null,
            suffix: IconButton(
              tooltip: _obscure ? l.del_show_pw : l.del_hide_pw,
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: AppIcon(AppIcons.showPassword, dp: 18, color: c.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.del_confirm,
            variant: AppButtonVariant.destructiveFilled,
            height: 48,
            expand: true,
            loading: _busy,
            onPressed: canConfirm ? _confirm : null,
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
