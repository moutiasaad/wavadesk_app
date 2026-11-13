import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_session.dart';
import '../application/workspace_block.dart';

/// Covers the whole app while the workspace is closed (trial ended,
/// subscription expired, blocked by Wavadesk). Admins can open billing on the
/// web; everyone can re-check (after paying) or sign out.
///
/// Shown from [MaterialApp.builder], above the router: no Navigator or
/// ScaffoldMessenger here, so feedback is inline.
class WorkspaceBlockedScreen extends ConsumerStatefulWidget {
  const WorkspaceBlockedScreen({super.key, required this.reason});

  final WorkspaceBlockReason reason;

  @override
  ConsumerState<WorkspaceBlockedScreen> createState() => _WorkspaceBlockedScreenState();
}

class _WorkspaceBlockedScreenState extends ConsumerState<WorkspaceBlockedScreen> {
  bool _checking = false;
  bool _stillClosed = false;

  Future<void> _recheck() async {
    setState(() {
      _checking = true;
      _stillClosed = false;
    });
    final open = await ref.read(workspaceBlockProvider.notifier).recheck();
    if (!mounted || open) return;
    setState(() {
      _checking = false;
      _stillClosed = true;
    });
  }

  Future<void> _openBilling() async {
    try {
      await launchUrl(Uri.parse('$apiBaseUrl/tenant-admin/billing'), mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser: nothing to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = context.text;
    final r = widget.reason;
    final admin = ref.watch(currentAgentProvider).role == AgentRole.admin;

    final title = switch (r) {
      WorkspaceBlockReason.trialExpired => l.ws_title_trial,
      WorkspaceBlockReason.subscriptionExpired => l.ws_title_expired,
      WorkspaceBlockReason.subscriptionInactive => l.ws_title_inactive,
      WorkspaceBlockReason.planNotSelected => l.ws_title_no_plan,
      WorkspaceBlockReason.workspaceBlocked => l.ws_title_blocked,
      WorkspaceBlockReason.workspaceArchived => l.ws_title_archived,
    };
    final body = !r.billingFixes ? l.ws_body_support : (admin ? l.ws_body_admin : l.ws_body_member);
    final (bg, fg) = r.billingFixes ? (c.warningContainer, c.warning) : (c.errorContainer, c.error);

    return Material(
      color: c.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: AppIcon(AppIcons.lock, dp: 32, color: fg),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(title, style: t.h4, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
                  if (admin && r.billingFixes) ...[
                    AppButton(label: l.ws_choose_plan, expand: true, onPressed: _openBilling),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AppButton(
                    label: l.ws_check_again,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    loading: _checking,
                    onPressed: _checking ? null : _recheck,
                  ),
                  if (_stillClosed) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(l.ws_still_closed, style: t.bodySmall.copyWith(color: c.error), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l.account_logout,
                    variant: AppButtonVariant.text,
                    expand: true,
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
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
