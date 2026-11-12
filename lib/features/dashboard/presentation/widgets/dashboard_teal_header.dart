import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/application/auth_session.dart';
import '../../../conversations/application/relative_time_ticker.dart';
import '../../../notifications/application/unread_badge_controller.dart';
import '../../application/presence_controller.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/greeting.dart';
import '../dash_palette.dart';
import '../sheets/presence_sheet.dart';
import 'period_segmented.dart';

/// The dashboard's own teal header (Dashboard v2 §4.1): solid `#0F7E7A`,
/// square corners, light status bar; identity row + period segmented. It
/// scrolls with the content. Renders from the session before any data.
class DashboardTealHeader extends ConsumerWidget {
  const DashboardTealHeader({super.key, required this.range, required this.onRange});

  final DashboardRange range;
  final ValueChanged<DashboardRange> onRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);
    final now = ref.watch(inboxClockProvider);
    final presence = ref.watch(presenceControllerProvider).presence;
    final unread = ref.watch(notificationsUnreadCountProvider);
    final workspace = '${ref.read(authRepositoryProvider).session?.workspace['name'] ?? ''}'.trim();

    final name = Greeting.firstName(me.name);
    final greeting = switch (Greeting.partOf(now)) {
      GreetingPart.morning => l.dash_morning(name),
      GreetingPart.afternoon => l.dash_afternoon(name),
      GreetingPart.evening => l.dash_evening(name),
    };
    final status = presenceLabel(l, presence, gender: me.gender);
    final subline = workspace.isEmpty ? status : '$workspace · $status';
    final big = MediaQuery.textScalerOf(context).scale(10) >= 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        color: DashPalette.header,
        padding: EdgeInsets.fromLTRB(16, MediaQuery.viewPaddingOf(context).top, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  TealMeAvatar(
                    name: me.name,
                    url: me.avatarUrl,
                    presence: presence,
                    onTap: () => context.go(Routes.account),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            greeting,
                            maxLines: big ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.h5.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: l.dash_a11y_presence(status),
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => showPresenceSheet(context, gender: me.gender),
                            child: Text(
                              subline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.caption.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DashBellButton(unread: unread, onBrand: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PeriodSegmented(value: range, onChanged: onRange),
          ],
        ),
      ),
    );
  }
}

/// My avatar on the teal header (Dashboard 40 / Account 56): 2dp white-35%
/// ring, initials in white, presence dot ringed in the header teal at the
/// bottom on the leading side. Colors cross-fade 200ms on a status change.
class TealMeAvatar extends StatelessWidget {
  const TealMeAvatar({
    super.key,
    required this.name,
    required this.url,
    required this.presence,
    required this.onTap,
    this.size = 40,
    this.dot = 10,
    this.initialsSize = 15,
    this.semanticLabel,
  });

  final String name;
  final String? url;
  final Presence presence;
  final VoidCallback onTap;
  final double size;

  /// Dot diameter without its 2dp ring.
  final double dot;
  final double initialsSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p.characters.first).join();
    final dot = switch (presence) {
      Presence.online => DashPalette.online,
      Presence.busy => DashPalette.busy,
      Presence.away => DashPalette.away,
    };
    return Semantics(
      button: true,
      label: semanticLabel ?? name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                  image: url == null || url!.isEmpty
                      ? null
                      : DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover),
                ),
                alignment: Alignment.center,
                child: url == null || url!.isEmpty
                    ? Text(
                        initials,
                        style: context.text.bodyMedium.copyWith(
                          fontSize: initialsSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      )
                    : null,
              ),
              PositionedDirectional(
                bottom: -1,
                end: -1,
                child: AnimatedContainer(
                  duration: AppMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 200),
                  width: this.dot + 4,
                  height: this.dot + 4,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(color: DashPalette.header, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bell: 40 visual / 48 hit, `bell.svg` 20; on the teal header a white-14%
/// disc with a white glyph, in the collapsed bar a dark glyph. 9dp unread
/// dot `#FB7185` ringed in the background, top corner on the leading side.
class DashBellButton extends StatelessWidget {
  const DashBellButton({super.key, required this.unread, required this.onBrand});

  final int unread;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ring = onBrand ? DashPalette.header : c.surface;
    return Semantics(
      button: true,
      label: context.l10n.dash_bell_a11y('$unread'),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Material(
            color: onBrand ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(Routes.notifications),
              child: SizedBox.square(
                dimension: 40,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AppIcon(AppIcons.bell, dp: 20, color: onBrand ? Colors.white : c.textPrimary),
                    if (unread > 0)
                      PositionedDirectional(
                        top: 7,
                        start: 8,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: DashPalette.unreadDot,
                            shape: BoxShape.circle,
                            border: Border.all(color: ring, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White 52dp bar shown once the teal header has scrolled away (§4.1.4):
/// centered title + dark bell, 1dp bottom border, dark status-bar icons.
class DashboardCollapsedBar extends ConsumerWidget {
  const DashboardCollapsedBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsUnreadCountProvider);
    return TealCollapsedBar(
      title: context.l10n.dash_title,
      trailing: DashBellButton(unread: unread, onBrand: false),
    );
  }
}

/// Shared compact bar for the teal-header tabs (Dashboard, Account): white,
/// 52dp, centered title Cairo 16/800, optional end action, 1dp bottom
/// border, dark status-bar icons.
class TealCollapsedBar extends StatelessWidget {
  const TealCollapsedBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: DashPalette.of(context).cardBorder)),
        ),
        child: SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.text.h5.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary),
                ),
              ),
              if (trailing != null) PositionedDirectional(end: 4, child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}
