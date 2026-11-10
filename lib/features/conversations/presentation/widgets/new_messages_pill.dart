import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// "▲ {n} محادثات جديدة" (Inbox spec §5): ink pill, h36, radius full, top
/// center below the chips. Slides down 12dp + fades in 200ms.
class NewMessagesPill extends StatelessWidget {
  const NewMessagesPill({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = count > 0;
    final reduced = AppMotion.reduced(context);
    final pill = Semantics(
      button: true,
      liveRegion: true,
      label: context.l10n.inbox_new_pill(count),
      excludeSemantics: true,
      child: Material(
        color: c.secondary,
        shape: const StadiumBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: context.shadows.medium,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.arrowUp, size: 16, color: c.onSecondary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.inbox_new_pill(count),
                  style: context.text.buttonSmall.copyWith(color: c.onSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.normal,
        child: AnimatedSlide(
          offset: visible || reduced ? Offset.zero : const Offset(0, -12 / 36),
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          child: pill,
        ),
      ),
    );
  }
}
