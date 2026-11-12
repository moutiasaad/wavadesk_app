import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_session.dart';
import '../../dashboard/application/presence_controller.dart';
import '../../dashboard/presentation/dash_palette.dart';
import '../../dashboard/presentation/sheets/presence_sheet.dart';
import '../../dashboard/presentation/widgets/dashboard_teal_header.dart';

/// Spec role wording (Account §4.1). The app has no owner flag: workspace
/// admins read "مسؤول".
String accountRoleLabel(AppLocalizations l, AgentRole role) => switch (role) {
  AgentRole.admin => l.acc_role_admin,
  AgentRole.supervisor => l.acc_role_lead,
  AgentRole.agent => l.acc_role_agent,
};

/// Teal header of the Account tab (Account §4.1, shares the Dashboard
/// header pieces): avatar 56 with ring + presence dot, name 17/800,
/// "{role} · {workspace}", ⋮ menu. Padding 0 / 16 / 22.
class AccountTealHeader extends ConsumerWidget {
  const AccountTealHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);
    final presence = ref.watch(presenceControllerProvider).presence;
    final workspace = '${ref.read(authRepositoryProvider).session?.workspace['name'] ?? ''}'.trim();
    final role = accountRoleLabel(l, me.role);
    final subline = workspace.isEmpty ? role : '$role · $workspace';
    final big = MediaQuery.textScalerOf(context).scale(10) >= 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: appOverlay(context, lightStatusIcons: true),
      child: Container(
        color: DashPalette.header,
        padding: EdgeInsets.fromLTRB(16, MediaQuery.viewPaddingOf(context).top + 4, 16, 22),
        child: Semantics(
          container: true,
          label: l.acc_header_a11y(me.name, role, workspace, presenceLabel(l, presence, gender: me.gender)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                TealMeAvatar(
                  name: me.name,
                  url: me.avatarUrl,
                  presence: presence,
                  size: 56,
                  dot: 12,
                  initialsSize: 20,
                  semanticLabel: l.acc_menu_edit,
                  onTap: () => context.push(Routes.profile),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.name,
                          maxLines: big ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.h5.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _MenuButton(userId: me.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Menu { edit, copyId }

/// ⋮ 40×40 on a white-14% disc, `dots.svg` 20 white. One workspace per
/// account in this app, so "تبديل مساحة العمل" never shows.
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.acc_menu,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: PopupMenuButton<_Menu>(
              tooltip: l.acc_menu,
              padding: EdgeInsets.zero,
              icon: const SizedBox.square(
                dimension: 40,
                child: Center(child: AppIcon(AppIcons.more, dp: 20, color: Colors.white)),
              ),
              color: context.colors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              onSelected: (m) async {
                switch (m) {
                  case _Menu.edit:
                    context.push(Routes.profile);
                  case _Menu.copyId:
                    await Clipboard.setData(ClipboardData(text: userId));
                    if (context.mounted) AppSnackbar.show(context, message: l.acc_id_copied, kind: SnackKind.success);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: _Menu.edit, child: Text(l.acc_menu_edit)),
                PopupMenuItem(value: _Menu.copyId, child: Text(l.acc_menu_copy_id)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
