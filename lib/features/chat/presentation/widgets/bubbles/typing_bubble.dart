import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// Customer typing (Chat spec §4.3, §13): incoming bubble with three 6dp
/// dots, 1.2s loop staggered 150ms. Static "…" under reduce motion.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: AppMotion.loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.reduced(context) ? _ctrl.stop() : _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        liveRegion: true,
        label: context.l10n.chatlist_typing,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.bubbleIncoming,
            borderRadius: AppRadius.bubble(outgoing: false, hasTail: true),
            boxShadow: context.shadows.low,
            border: c.isDark ? Border.all(color: c.divider) : null,
          ),
          child: reduced
              ? Text('…', style: context.text.chatMessage.copyWith(color: c.textSecondary, height: 1))
              : AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[if (i > 0) const SizedBox(width: 4), _dot(c, i)],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _dot(AppColors c, int i) {
    // 150ms stagger within the 1.2s loop.
    final phase = (_ctrl.value - i * 0.125) % 1.0;
    final lift = math.max(0.0, math.sin(phase * 2 * math.pi));
    return Transform.translate(
      offset: Offset(0, -3 * lift),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: c.textTertiary.withValues(alpha: 0.5 + 0.5 * lift),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
