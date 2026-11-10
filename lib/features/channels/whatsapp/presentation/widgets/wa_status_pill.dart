import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../domain/wa_status.dart';

String waStatusLabel(AppLocalizations l, WaStatus s) => switch (s) {
      WaStatus.connected => l.wa_connected,
      WaStatus.connecting => l.wa_connecting,
      WaStatus.syncing => l.wa_syncing,
      WaStatus.phoneOffline => l.wa_phone_offline,
      WaStatus.disconnected => l.wa_disconnected,
      WaStatus.restricted => l.wa_restricted,
      WaStatus.pending => l.wa_pending,
    };

/// (background, border, text, dot) for a pill tone (WhatsApp spec §4.2, §11).
({Color bg, Color border, Color fg, Color dot}) waPillColors(BuildContext context, WaPillTone tone) {
  final c = context.colors;
  final dark = c.isDark;
  return switch (tone) {
    WaPillTone.success => dark
        ? (bg: const Color(0xFF0F2A1A), border: const Color(0xFF1E4D30), fg: const Color(0xFF4ADE80), dot: const Color(0xFF4ADE80))
        : (bg: const Color(0xFFE9F9EF), border: const Color(0xFFC7EFD6), fg: const Color(0xFF15803D), dot: const Color(0xFF22C55E)),
    WaPillTone.info => (bg: c.infoContainer, border: c.infoContainer, fg: c.textInfo, dot: c.info),
    WaPillTone.warning => (bg: c.warningContainer, border: c.warningContainer, fg: c.textWarning, dot: c.warning),
    WaPillTone.error => dark
        ? (bg: c.errorContainer, border: c.errorContainer, fg: c.textError, dot: c.error)
        : (bg: const Color(0xFFFFF1F2), border: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C), dot: const Color(0xFFE11D48)),
    WaPillTone.neutral => (bg: c.surfaceVariant, border: c.surfaceVariant, fg: c.textSecondary, dot: c.textTertiary),
  };
}

/// h28 pill: dot 7 (spinner 10 while connecting/syncing) + caption 700.
/// Cross-fades 200 ms on change (§12).
class WaStatusPill extends StatelessWidget {
  const WaStatusPill({super.key, required this.status});

  final WaStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final col = waPillColors(context, waPillTone(status));
    final reduced = AppMotion.reduced(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(status),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: col.bg,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: col.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.isBusy)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.6, color: col.fg),
              )
            else
              Container(width: 7, height: 7, decoration: BoxDecoration(color: col.dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(waStatusLabel(l, status), style: context.text.caption.copyWith(color: col.fg, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
