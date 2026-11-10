import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';

/// Navigation targets from the login screen whose flows have their own,
/// not-yet-written specs (Login spec §1 "Out of scope"). Each shows a
/// styled placeholder so the routes work end to end.
class _AuthPlaceholder extends StatelessWidget {
  const _AuthPlaceholder({required this.title, required this.icon, this.body});

  final String title;
  final IconData icon;
  final String? body;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBarStandard(title: title),
        body: EmptyState(icon: icon, title: context.l10n.auth_coming_soon_title, body: body),
      );
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.identifier});

  /// Identifier typed on the login screen, forwarded via `extra`.
  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = identifier?.trim() ?? '';
    return _AuthPlaceholder(
      title: l.login_forgot,
      icon: AppIcons.lock,
      body: id.isEmpty ? l.auth_forgot_placeholder : l.auth_forgot_placeholder_for(ltr(id)),
    );
  }
}

class TwoFactorScreen extends StatelessWidget {
  const TwoFactorScreen({super.key});

  @override
  Widget build(BuildContext context) => _AuthPlaceholder(
        title: context.l10n.auth_2fa_title,
        icon: AppIcons.security,
        body: context.l10n.auth_2fa_placeholder,
      );
}

class WorkspacePickerScreen extends StatelessWidget {
  const WorkspacePickerScreen({super.key});

  @override
  Widget build(BuildContext context) => _AuthPlaceholder(
        title: context.l10n.auth_workspace_title,
        icon: AppIcons.team,
        body: context.l10n.auth_workspace_placeholder,
      );
}
