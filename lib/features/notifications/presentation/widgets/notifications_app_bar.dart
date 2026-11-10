import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/notification_type.dart';

/// App bar (Notifications spec §4.1, design frame 09): 40dp outlined back ·
/// title · قراءة الكل · filter menu (filters, settings, delete read).
class NotificationsAppBar extends StatelessWidget {
  const NotificationsAppBar({
    super.key,
    required this.canReadAll,
    required this.onReadAll,
    required this.onSettings,
    required this.onDeleteRead,
    required this.filter,
    required this.onFilter,
  });

  final bool canReadAll;
  final VoidCallback onReadAll;
  final VoidCallback onSettings;
  final VoidCallback onDeleteRead;

  /// The design has no chip row: the filter lives in the ⋮ menu instead.
  final NotificationFilter filter;
  final ValueChanged<NotificationFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 12, 12),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.back,
            size: 40,
            iconSize: 18,
            variant: AppIconButtonVariant.outlined,
            background: c.surface,
            semanticLabel: l.common_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l.ntf_title, style: t.h4.copyWith(fontWeight: FontWeight.w800), maxLines: 1),
            ),
          ),
          TextButton(
            onPressed: canReadAll ? onReadAll : null,
            style: TextButton.styleFrom(
              foregroundColor: c.primary,
              disabledForegroundColor: c.textTertiary,
              textStyle: t.buttonMedium,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(l.ntf_read_all),
          ),
          PopupMenuButton<String>(
            tooltip: l.ntf_more,
            icon: Badge(
              isLabelVisible: filter != NotificationFilter.all,
              smallSize: 7,
              backgroundColor: c.primary,
              child: Icon(AppIcons.filter, size: 20, color: c.textSecondary),
            ),
            color: c.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            onSelected: (v) => switch (v) {
              'settings' => onSettings(),
              'delete_read' => onDeleteRead(),
              _ => onFilter(NotificationFilter.parse(v)),
            },
            itemBuilder: (context) => [
              for (final f in NotificationFilter.values)
                CheckedPopupMenuItem(value: f.name, checked: f == filter, child: Text(f.label(l), style: t.bodyMedium)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'settings', child: Text(l.ntf_settings, style: t.bodyMedium)),
              PopupMenuItem(value: 'delete_read', child: Text(l.ntf_delete_read, style: t.bodyMedium.copyWith(color: c.textError))),
            ],
          ),
        ],
      ),
    );
  }
}
