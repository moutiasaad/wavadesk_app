import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/waiting_duration_formatter.dart';

/// Wait chip (Claim v2 §4.3.1): h20, padding 0 7, radius 6, clock 12 +
/// Cairo 11/700. Amber under the SLA, red from the SLA on (300ms colour
/// transition). Ticks on every minute boundary. Hidden when nothing is
/// unanswered.
class ClaimWaitingTag extends StatefulWidget {
  const ClaimWaitingTag({super.key, required this.since, this.slaSeconds = 300});

  final DateTime? since;
  final int slaSeconds;

  @override
  State<ClaimWaitingTag> createState() => _ClaimWaitingTagState();
}

class _ClaimWaitingTagState extends State<ClaimWaitingTag> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(ClaimWaitingTag old) {
    super.didUpdateWidget(old);
    if (old.since != widget.since) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final info = WaitingDurationFormatter.format(widget.since, DateTime.now(), context.l10n, slaSeconds: widget.slaSeconds);
    if (info == null) return;
    _timer = Timer(info.refresh, () {
      if (!mounted) return;
      setState(() {});
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final info = WaitingDurationFormatter.format(widget.since, DateTime.now(), context.l10n, slaSeconds: widget.slaSeconds);
    if (info == null) return const SizedBox.shrink();
    final over = info.level == WaitingLevel.overSla;
    final dark = c.isDark;
    final fg = over
        ? (dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))
        : (dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309));
    final bg = over
        ? (dark ? const Color(0xFF2A1218) : const Color(0xFFFFF1F2))
        : (dark ? const Color(0xFF2A2010) : const Color(0xFFFEF3E2));
    return Semantics(
      label: info.a11yLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.slow,
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.clock, dp: 12, color: fg),
            const SizedBox(width: 3),
            AnimatedDefaultTextStyle(
              duration: AppMotion.slow,
              style: context.text.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2, color: fg),
              child: Text(info.label),
            ),
          ],
        ),
      ),
    );
  }
}
