import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/notification_type.dart';

/// App bar (Notifications spec §4.1) on the brand header: glassy back ·
/// white title · قراءة الكل pill · filter menu (filters, settings, delete read).
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
    return _StatusBarBleed(
      child: BrandHeader(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.back,
            size: 40,
            iconSize: 20,
            variant: AppIconButtonVariant.filled,
            semanticLabel: l.common_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l.ntf_title, style: t.h4.copyWith(fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1),
            ),
          ),
          // Light pill on the brand header.
          AppBarTextAction(label: l.ntf_read_all, onPressed: canReadAll ? onReadAll : null),
          PopupMenuButton<String>(
            tooltip: l.ntf_more,
            icon: Badge(
              isLabelVisible: filter != NotificationFilter.all,
              smallSize: 7,
              backgroundColor: Colors.white,
              child: const AppIcon(AppIcons.filter, color: Colors.white),
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
      ),
    );
  }
}

/// The screen puts this header inside a top SafeArea, so the status-bar
/// strip above it would keep the page color: paint the brand gradient there
/// too (outside the header's own bounds; nothing else is drawn there).
class _StatusBarBleed extends StatelessWidget {
  const _StatusBarBleed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).top;
    // Not under a SafeArea (BrandHeader pads itself) or no status bar.
    if (inset == 0 || MediaQuery.paddingOf(context).top > 0) return child;
    final colors = BrandHeader.colorsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -inset,
          left: 0,
          right: 0,
          height: inset + 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [colors.first, Color.lerp(colors.first, colors.last, 0.5)!],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
