import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/l10n.dart';

/// §8.7. Two forms: a small circle on an avatar, or a chip with label.
/// Glyphs and brand colors come from [ChannelIcon] (Icon Library §7).
class ChannelBadge extends StatelessWidget {
  /// Circle on an avatar: 18dp brand fill, 11dp white glyph, 2dp ring
  /// (Icon Library §7); 16 on 40dp avatars.
  const ChannelBadge.avatar({super.key, required this.channel, this.size = 18, this.ringColor}) : chip = false;

  /// Chip: height 24, channel container bg, brand-colored glyph + label.
  const ChannelBadge.chip({super.key, required this.channel}) : chip = true, size = 24, ringColor = null;

  final Channel channel;
  final bool chip;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = channel.label(context.l10n);

    if (chip) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(color: channel.container(c), borderRadius: BorderRadius.circular(AppRadius.full)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChannelIcon(channel, size: AppIconSize.xs),
              const SizedBox(width: 5),
              Text(label, style: context.text.tagLabel),
            ],
          ),
        ),
      );
    }

    return ChannelIcon.badge(channel, dp: size, ringColor: ringColor ?? c.background);
  }
}
