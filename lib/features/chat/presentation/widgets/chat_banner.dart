import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/conversation_detail.dart';

enum _BannerKind { offline, connecting, windowClosed, windowSoon, channelDown, snoozed }

/// Banner slot under the context strip — at most one, in priority order
/// (Chat spec §4.11).
class ChatBanner extends StatelessWidget {
  const ChatBanner({
    super.key,
    required this.detail,
    required this.network,
    required this.now,
    required this.onChooseTemplate,
    required this.onReconnect,
    required this.onUnsnooze,
  });

  final ConversationDetail detail;
  final NetworkState network;
  final DateTime now;
  final VoidCallback onChooseTemplate;
  final VoidCallback onReconnect;
  final VoidCallback onUnsnooze;

  _BannerKind? _kind() {
    if (network == NetworkState.offline) return _BannerKind.offline;
    if (network == NetworkState.connecting) return _BannerKind.connecting;
    if (detail.isOpen || detail.status == ConversationStatus.snoozed) {
      if (detail.windowClosed(now)) return _BannerKind.windowClosed;
      final exp = detail.waWindowExpiresAt;
      if (exp != null && exp.difference(now) < const Duration(hours: 2)) return _BannerKind.windowSoon;
    }
    if (!detail.conversation.channelConnected) return _BannerKind.channelDown;
    if (detail.status == ConversationStatus.snoozed && detail.conversation.snoozedUntil != null) {
      return _BannerKind.snoozed;
    }
    return null;
  }

  String _snoozeTime(BuildContext context, DateTime t) {
    final locale = context.localeName;
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    return sameDay
        ? intl.DateFormat.jm(locale).format(t)
        : '${intl.DateFormat.E(locale).format(t)} ${intl.DateFormat.jm(locale).format(t)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final kind = _kind();

    Widget? content;
    if (kind != null) {
      final (
        Color bg,
        Color fg,
        IconData icon,
        String text,
        String? action,
        VoidCallback? onAction,
        double h,
      ) = switch (kind) {
        _BannerKind.offline => (c.errorContainer, c.textError, AppIcons.wifiOff, l.chat_banner_offline, null, null, 32),
        _BannerKind.connecting => (
          c.warningContainer,
          c.textWarning,
          AppIcons.wifiOff,
          l.banner_connecting,
          null,
          null,
          32,
        ),
        _BannerKind.windowClosed => (
          c.warningContainer,
          c.textWarning,
          AppIcons.clock,
          l.chat_banner_window_closed,
          l.chat_choose_template,
          onChooseTemplate,
          44,
        ),
        _BannerKind.windowSoon => () {
          final left = detail.waWindowExpiresAt!.difference(now);
          final hm = '${left.inHours}:${(left.inMinutes % 60).toString().padLeft(2, '0')}';
          return (c.infoContainer, c.textInfo, AppIcons.hourglass, l.chat_banner_window_soon(hm), null, null, 32.0);
        }(),
        _BannerKind.channelDown => (
          c.errorContainer,
          c.textError,
          AppIcons.alert,
          l.chat_banner_channel_down,
          l.chat_reconnect,
          onReconnect,
          44,
        ),
        _BannerKind.snoozed => (
          c.statusSnoozedContainer,
          c.statusSnoozed,
          AppIcons.moon,
          l.chat_snoozed_until(_snoozeTime(context, detail.conversation.snoozedUntil!)),
          l.chat_unsnooze,
          onUnsnooze,
          32,
        ),
      };
      content = Semantics(
        key: ValueKey(kind),
        liveRegion: true,
        container: true,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: h),
          color: bg,
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg, end: AppSpacing.xs),
          child: Row(
            children: [
              if (kind == _BannerKind.connecting)
                AppSpinner(size: 14, color: fg, delayed: false)
              else
                Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(text, style: t.caption.copyWith(color: fg)),
                ),
              ),
              if (action != null && onAction != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: fg,
                    textStyle: t.buttonSmall,
                    minimumSize: const Size(48, 36),
                  ),
                  onPressed: onAction,
                  child: Text(action),
                ),
            ],
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        child: content ?? const SizedBox(key: ValueKey('none'), width: double.infinity),
      ),
    );
  }
}
