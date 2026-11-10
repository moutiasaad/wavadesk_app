import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import 'app_icon.dart';
import 'app_icons.dart';

/// Channel logos (Icon Library §7): Simple Icons for brands, Lucide for
/// email / web / SMS. Official brand colors only — never recolored to
/// `primary`, never mirrored, never outlined.
class ChannelIcon extends StatelessWidget {
  /// Bare logo in its brand color (chips, rows).
  const ChannelIcon(this.channel, {super.key, this.size = AppIconSize.sm, this.dp})
      : _kind = _Kind.glyph,
        ringColor = null;

  /// Logo on its light brand tile (34dp settings-style tile by default).
  const ChannelIcon.tile(this.channel, {super.key, double this.dp = 34})
      : _kind = _Kind.tile,
        size = AppIconSize.md,
        ringColor = null;

  /// Avatar badge: brand-filled circle (18dp), white glyph (11dp), 2dp ring.
  const ChannelIcon.badge(this.channel, {super.key, double this.dp = 18, this.ringColor})
      : _kind = _Kind.badge,
        size = AppIconSize.xs;

  final Channel channel;
  final AppIconSize size;

  /// Glyph size (bare), tile size (tile) or circle size (badge).
  final double? dp;
  final Color? ringColor;
  final _Kind _kind;

  static IconData glyphOf(Channel ch) => switch (ch) {
        Channel.whatsapp => AppIcons.whatsapp,
        Channel.web => AppIcons.webChat,
        Channel.messenger => AppIcons.messenger,
        Channel.instagram => AppIcons.instagram,
        Channel.email => AppIcons.email,
        Channel.telegram => AppIcons.telegram,
        Channel.sms => AppIcons.sms,
        Channel.other => AppIcons.otherChannel,
      };

  static Color brandOf(Channel ch, AppColors c) => switch (ch) {
        Channel.whatsapp => c.channelWhatsapp,
        Channel.web => c.channelWeb,
        Channel.messenger => c.channelMessenger,
        Channel.instagram => c.channelInstagram,
        Channel.email => c.channelEmail,
        Channel.telegram => c.channelTelegram,
        Channel.sms => c.channelSms,
        Channel.other => c.channelOther,
      };

  static Color tileOf(Channel ch, AppColors c) => switch (ch) {
        Channel.whatsapp => c.channelWhatsappContainer,
        Channel.web => c.channelWebContainer,
        Channel.messenger => c.channelMessengerContainer,
        Channel.instagram => c.channelInstagramContainer,
        Channel.email => c.channelEmailContainer,
        Channel.telegram => c.channelTelegramContainer,
        Channel.sms => c.channelSmsContainer,
        Channel.other => c.channelOtherContainer,
      };

  /// Glyph color on a light surface / tile: WhatsApp's #25D366 is too light
  /// there, so §7 uses #15803D; dark mode keeps the brand color.
  static Color glyphColorOf(Channel ch, AppColors c) =>
      ch == Channel.whatsapp && !c.isDark ? const Color(0xFF15803D) : brandOf(ch, c);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final glyph = glyphOf(channel);
    switch (_kind) {
      case _Kind.glyph:
        return AppIcon(glyph, size: size, dp: dp, color: glyphColorOf(channel, c));
      case _Kind.tile:
        final d = dp!;
        return Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: tileOf(channel, c), borderRadius: BorderRadius.circular(d * 10 / 34)),
          alignment: Alignment.center,
          child: AppIcon(glyph, dp: d * 18 / 34, color: glyphColorOf(channel, c)),
        );
      case _Kind.badge:
        final d = dp!;
        return Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: brandOf(channel, c),
            shape: BoxShape.circle,
            border: Border.all(color: ringColor ?? c.surface, width: 2),
          ),
          alignment: Alignment.center,
          // 11dp on the 18dp badge; scaled for the other avatar sizes.
          child: AppIcon(glyph, dp: d * 11 / 18, color: Colors.white),
        );
    }
  }
}

enum _Kind { glyph, tile, badge }
