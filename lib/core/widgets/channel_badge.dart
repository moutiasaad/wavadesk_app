import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/l10n.dart';

/// §8.7. Two forms: a small circle on an avatar, or a chip with label.
/// Brand colors are used only here — never for buttons or text (§3.8).
class ChannelBadge extends StatelessWidget {
  /// Circle on an avatar: 19 (avatar 50) / 16 (avatar 40), white glyph,
  /// 2dp `background` ring.
  const ChannelBadge.avatar({super.key, required this.channel, this.size = 19, this.ringColor}) : chip = false;

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
              Icon(channel.glyph, size: 12, color: channel.brand(c)),
              const SizedBox(width: 5),
              Text(label, style: context.text.tagLabel),
            ],
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: channel.brand(c),
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? c.background, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(channel.glyph, size: size <= 16 ? 8 : 10, color: Colors.white),
    );
  }
}
