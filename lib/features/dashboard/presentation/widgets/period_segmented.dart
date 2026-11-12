import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/dashboard_snapshot.dart';
import '../dash_palette.dart';

/// Period switch on the teal header (Dashboard v2 §4.1.2): white 12% track,
/// 3 equal 30dp segments, the active one a white pill with teal text.
class PeriodSegmented extends StatelessWidget {
  const PeriodSegmented({super.key, required this.value, required this.onChanged});

  final DashboardRange value;
  final ValueChanged<DashboardRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.text;
    final options = [
      (DashboardRange.today, l.dash_range_today),
      (DashboardRange.last7, l.dash_period_7d),
      (DashboardRange.last30, l.dash_period_30d),
    ];
    final reduced = AppMotion.reduced(context);
    return Semantics(
      label: l.dash_range_title,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: options[i].$1 == value,
                  button: true,
                  label: options[i].$2,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(options[i].$1),
                    child: AnimatedContainer(
                      duration: reduced ? Duration.zero : AppMotion.fast,
                      constraints: const BoxConstraints(minHeight: 30),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: options[i].$1 == value ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        options[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: options[i].$1 == value ? DashPalette.header : Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
