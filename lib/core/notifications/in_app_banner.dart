import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/notifications/application/unread_badge_controller.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/notifications/domain/notification.dart';
import '../../features/notifications/domain/notification_type.dart';
import '../../features/notifications/presentation/widgets/notification_icon.dart';
import '../../features/notifications/presentation/widgets/notification_inline_actions.dart' show isTabRoute;
import '../data/app_controllers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/analytics.dart';
import '../utils/l10n.dart';
import 'push_router.dart';

/// Foreground in-app banner (Notifications spec §9.2): top of the screen,
/// auto-hides after 4 s, swipe up to dismiss, tap navigates. Max one visible;
/// the rest queue. Not shown when the user is already on the target (the
/// chat / list updates in place).
class InAppBannerHost extends ConsumerStatefulWidget {
  const InAppBannerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InAppBannerHost> createState() => _InAppBannerHostState();
}

class _InAppBannerHostState extends ConsumerState<InAppBannerHost> {
  final _queue = Queue<NotificationItem>();
  StreamSubscription<NotificationItem>? _sub;
  NotificationItem? _current;
  bool _visible = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(unreadBadgeProvider.notifier).arrivals.listen(_onArrival);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  String get _location {
    try {
      return ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
    } catch (_) {
      return '';
    }
  }

  void _onArrival(NotificationItem n) {
    if (!n.type.pushWorthy && n.type != NotificationType.unknown) return;
    if (ref.read(notificationsRepositoryProvider).mutedTypes.contains(n.rawType)) return;
    final location = _location;
    if (Uri.parse(location).path == Routes.notifications) return; // list inserts it
    final dest = PushRouter.forNotification(n);
    if (dest != null && PushRouter.isOnTarget(dest, location)) return;
    _queue.add(n);
    if (_current == null) _next();
  }

  void _next() {
    if (!mounted) return;
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    final n = _queue.removeFirst();
    setState(() {
      _current = n;
      _visible = true;
    });
    final l = context.l10n;
    SemanticsService.announce(NotificationTemplates.title(l, n), Directionality.of(context), assertiveness: Assertiveness.polite);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _hide?.cancel();
    if (!mounted || _current == null) return;
    setState(() => _visible = false);
    Future<void>.delayed(AppMotion.fast, _next);
  }

  Future<void> _open(NotificationItem n) async {
    _dismiss();
    Analytics.log('ntf_open', {
      'type': n.rawType,
      'age_seconds': DateTime.now().difference(n.createdAt).inSeconds,
      'source': 'banner',
    });
    final repo = ref.read(notificationsRepositoryProvider);
    unawaited(repo.api.markRead(n.id).then((_) => ref.read(unreadBadgeProvider.notifier).adjust(-1)).catchError((_) {}));
    final router = ref.read(routerProvider);
    final dest = PushRouter.forNotification(n);
    if (dest == null) {
      unawaited(router.push(Routes.notifications));
    } else if (dest.route != null) {
      isTabRoute(dest.route!) ? router.go(dest.route!) : unawaited(router.push(dest.route!));
    } else if (dest.billing && !ref.read(currentAgentProvider).isAdmin) {
      unawaited(router.push(Routes.notifications));
    } else if (dest.external != null) {
      await launchUrl(dest.external!, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _current;
    final reduced = AppMotion.reduced(context);
    return Stack(
      children: [
        widget.child,
        if (n != null)
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: AnimatedSlide(
              offset: _visible || reduced ? Offset.zero : const Offset(0, -0.25),
              duration: _visible ? AppMotion.normal : AppMotion.fast,
              curve: AppMotion.standard,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _visible ? AppMotion.normal : AppMotion.fast,
                child: _Banner(
                  key: ValueKey(n.id),
                  item: n,
                  onTap: () => _open(n),
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.item, required this.onTap, required this.onDismiss});

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final title = NotificationTemplates.title(l, item);
    final body = NotificationTemplates.body(l, item);
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < 0) onDismiss();
      },
      child: Semantics(
        container: true,
        liveRegion: true,
        button: true,
        label: '$title، $body',
        excludeSemantics: true,
        child: Material(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl - 2),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl - 2),
                boxShadow: context.shadows.high,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
              child: Row(
                children: [
                  NotificationIcon(item: item),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.listTitle.copyWith(fontSize: 14.5)),
                        if (body.isNotEmpty)
                          Text(
                            body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(fontSize: 12.5, color: c.textSecondary),
                          ),
                      ],
                    ),
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
