import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../domain/rewrite_session.dart';

/// Rows under the result text, gap 8, `caption` (Rewrite spec §5.5):
/// no-change ✓, name added, fact-check warning, length delta, over limit.
class RewriteResultIndicators extends StatelessWidget {
  const RewriteResultIndicators({
    super.key,
    required this.version,
    required this.sourceLength,
    required this.resultLength,
    required this.overLimit,
  });

  final RewriteVersion version;
  final int sourceLength;
  final int resultLength;
  final bool overLimit;

  /// "−35%" / "+12%" / "0%" (true minus sign, isolated LTR).
  static String deltaLabel(int source, int result) {
    if (source == 0) return '0%';
    final pct = ((result - source) * 100 / source).round();
    final s = pct < 0 ? '${String.fromCharCode(0x2212)}${-pct}%' : (pct > 0 ? '+$pct%' : '0%');
    return String.fromCharCode(0x2066) + s + String.fromCharCode(0x2069); // LTR isolate
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text.caption;
    final l = context.l10n;

    Widget row(IconData? icon, String text, Color color) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AppIcon(icon, size: AppIconSize.xs, color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(text, style: t.copyWith(color: color)),
          ),
        ],
      ),
    );

    final rows = <Widget>[
      if (version.unchanged && !version.edited) row(AppIcons.resolve, l.rw_no_change, c.textSuccess),
      if (version.insertedName) row(AppIcons.customer, l.rw_name_added, c.textSecondary),
      if (version.factWarning) row(AppIcons.warning, l.rw_fact_warning, c.textWarning),
      if (!version.unchanged || version.edited)
        row(null, l.rw_chars(resultLength, deltaLabel(sourceLength, resultLength)), c.textTertiary),
      if (overLimit) row(AppIcons.error, l.rw_over_limit, c.textError),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
