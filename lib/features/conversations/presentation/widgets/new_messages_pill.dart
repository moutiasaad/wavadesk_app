import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// "{n} رسائل جديدة ↑" (Inbox v2 §5.2): teal pill, h34, radius full,
/// white Cairo 13/700, under the filter bar. Slides down + fades 200ms.
class NewMessagesPill extends StatelessWidget {
  const NewMessagesPill({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visible = count > 0;
    final reduced = AppMotion.reduced(context);
    final text = context.l10n.inbox_new_msgs(count);
    final pill = Semantics(
      button: true,
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF0F7E7A),
        shape: const StadiumBorder(),
        elevation: 4,
        shadowColor: const Color(0x660F172A),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, style: context.text.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 6),
                  const AppIcon(AppIcons.arrowUp, dp: 14, color: Colors.white),
                ],
              ),
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
          offset: visible || reduced ? Offset.zero : const Offset(0, -0.35),
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          child: pill,
        ),
      ),
    );
  }
}
