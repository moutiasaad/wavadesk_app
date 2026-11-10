import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/waiting_duration_formatter.dart';

/// Live waiting tag (Claim spec §4.2.2): compact badge h20 radius 6, clock
/// 13 + duration. Amber under SLA, red from SLA on (300ms cross-fade).
/// Ticks every 10s under 2 minutes, then every minute. Hidden when nothing
/// is unanswered.
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
    final info = WaitingDurationFormatter.format(
      widget.since,
      DateTime.now(),
      context.l10n,
      slaSeconds: widget.slaSeconds,
    );
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
    final info = WaitingDurationFormatter.format(
      widget.since,
      DateTime.now(),
      context.l10n,
      slaSeconds: widget.slaSeconds,
    );
    if (info == null) return const SizedBox.shrink();
    final over = info.level == WaitingLevel.overSla;
    final fg = over ? c.statusWaiting : c.statusPending;
    final bg = over ? c.statusWaitingContainer : c.statusPendingContainer;
    return Semantics(
      label: info.a11yLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.slow,
        constraints: const BoxConstraints(minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.xs)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.slow,
              child: Icon(AppIcons.clock, key: ValueKey(over), size: 13, color: fg),
            ),
            const SizedBox(width: AppSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: AppMotion.slow,
              style: context.text.tagLabel.copyWith(color: fg),
              child: Text(info.label),
            ),
          ],
        ),
      ),
    );
  }
}
