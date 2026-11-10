import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/wa_channel.dart';
import '../../domain/wa_status.dart';
import '../sheets/wa_connection_details_sheet.dart';
import '../sheets/wa_connection_log_sheet.dart';
import '../sheets/wa_quality_sheet.dart';
import 'wa_status_pill.dart';

/// 52 circle WhatsApp tile (§4.2; dark §11).
class WaGlyphTile extends StatelessWidget {
  const WaGlyphTile({super.key, this.size = 52, this.iconSize = 24});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.isDark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? const Color(0x2625D366) : const Color(0xFFE8F9EF),
        shape: BoxShape.circle,
      ),
      child: Icon(AppIcons.whatsapp, size: iconSize, color: dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
    );
  }
}

String waQualityLabel(AppLocalizations l, WaQualityRating? r) => switch (r) {
      WaQualityRating.high => l.wa_q_high,
      WaQualityRating.medium => l.wa_q_med,
      WaQualityRating.low => l.wa_q_low,
      null => '—',
    };

Color waQualityColor(BuildContext context, WaQualityRating? r) {
  final c = context.colors;
  return switch (r) {
    WaQualityRating.high => c.textSuccess,
    WaQualityRating.medium => c.textWarning,
    WaQualityRating.low => c.textError,
    null => c.textSecondary,
  };
}

/// Connection card (WhatsApp spec §4.2): tile + name/number + status pill,
/// then 3 stats. Tap → connection details sheet. The border flashes in the
/// status color for 300 ms when the status changes (§12).
class WaConnectionCard extends StatefulWidget {
  const WaConnectionCard({super.key, required this.channel, required this.flashTick, this.offline = false});

  final WaChannel channel;
  final int flashTick;
  final bool offline;

  @override
  State<WaConnectionCard> createState() => _WaConnectionCardState();
}

class _WaConnectionCardState extends State<WaConnectionCard> {
  bool _flash = false;

  @override
  void didUpdateWidget(WaConnectionCard old) {
    super.didUpdateWidget(old);
    if (old.flashTick != widget.flashTick && !AppMotion.reduced(context)) {
      setState(() => _flash = true);
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flash = false);
      });
    }
  }

  void _copyNumber() {
    final p = widget.channel.phone;
    if (p == null) return;
    Clipboard.setData(ClipboardData(text: p));
    HapticFeedback.selectionClick();
    AppSnackbar.show(context, message: context.l10n.wa_copied);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ch = widget.channel;
    final pill = waPillColors(context, waPillTone(ch.status));
    final phone = formatWaPhone(ch.phone);
    final name = ch.displayName ?? (ch.isPending ? l.wa_alert_pending : l.wa_title);
    // Disconnected: last known values dimmed (§7).
    final dimStats = ch.status == WaStatus.disconnected || ch.status == WaStatus.restricted;
    final qualityText = ch.isCloud
        ? waQualityLabel(l, ch.quality.rating)
        : (ch.quality.stable == null ? '—' : (ch.quality.stable! ? l.wa_stable : l.wa_unstable));
    final qualityColor = ch.isCloud
        ? waQualityColor(context, ch.quality.rating)
        : (ch.quality.stable == false ? c.textWarning : (ch.quality.stable == true ? c.textSuccess : c.textSecondary));
    final days = ch.linkedDays;

    final a11y = l.wa_card_a11y(
      name,
      phone,
      waStatusLabel(l, ch.status),
      '${ch.statsToday.messages}',
      qualityText,
      '${days ?? 0}',
    );

    return Semantics(
      container: true,
      button: true,
      label: a11y,
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: _flash ? pill.dot : c.border, width: _flash ? 1.5 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => showWaConnectionDetailsSheet(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const WaGlyphTile(),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: t.h5.copyWith(fontWeight: FontWeight.w800, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (phone.isNotEmpty)
                                GestureDetector(
                                  onLongPress: _copyNumber,
                                  child: Text(
                                    phone,
                                    textDirection: TextDirection.ltr,
                                    style: t.bodyMedium.copyWith(color: c.textSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        WaStatusPill(status: ch.status),
                      ],
                    ),
                    if (!ch.isPending) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Divider(height: 1, thickness: 1, color: c.divider),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedOpacity(
                        opacity: dimStats ? 0.5 : 1,
                        duration: AppMotion.normal,
                        child: _Stats(
                          items: [
                            (
                              '${ch.statsToday.messages}',
                              l.wa_msgs_today,
                              c.textPrimary,
                              () => context.go(Routes.dashboard),
                            ),
                            (
                              qualityText,
                              l.wa_quality,
                              qualityColor,
                              () => ch.isCloud ? showWaQualitySheet(context, ch) : showWaConnectionLogSheet(context),
                            ),
                            (days == null ? '—' : l.wa_days('$days'), l.wa_linked_since, c.textPrimary, null),
                          ],
                        ),
                      ),
                    ],
                    if (widget.offline && ch.fetchedAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l.wa_last_updated(AppFormat.relative(context, ch.fetchedAt!)),
                        style: t.caption.copyWith(color: c.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3 centered stat columns with inline borders; vertical list at 200% text.
class _Stats extends StatelessWidget {
  const _Stats({required this.items});

  final List<(String, String, Color, VoidCallback?)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final big = MediaQuery.textScalerOf(context).scale(10) >= 18;

    Widget cell((String, String, Color, VoidCallback?) s, {bool vertical = false}) {
      final (value, label, color, onTap) = s;
      final body = vertical
          ? Row(
              children: [
                Expanded(child: Text(label, style: t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.textSecondary))),
                Text(value, style: t.h4.copyWith(fontWeight: FontWeight.w800, color: color)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: t.h4.copyWith(fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  label,
                  style: t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            );
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs), child: body),
      );
    }

    if (big) {
      return Column(children: [for (final s in items) cell(s, vertical: true)]);
    }
    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.divider),
            Expanded(child: cell(items[i])),
          ],
        ],
      ),
    );
  }
}
