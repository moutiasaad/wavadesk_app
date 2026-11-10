import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import '../../domain/hours_validator.dart';

/// "9:00 ص" / "9:00 AM", Latin digits.
String formatAiTime(BuildContext context, int minutes) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final m = minutes.clamp(0, 24 * 60);
  final h = (m ~/ 60) % 24;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final suffix = h < 12 ? (ar ? 'ص' : 'AM') : (ar ? 'م' : 'PM');
  return '$h12:${(m % 60).toString().padLeft(2, '0')} $suffix';
}

/// Two wheels (from / to), 15-min steps (AI Agent spec §5.1).
Future<TimeRange?> showTimeRangePicker(BuildContext context, {required TimeRange initial}) {
  return AppBottomSheet.show<TimeRange>(context, title: context.l10n.ai_hours, builder: (_) => _RangePicker(initial: initial));
}

class _RangePicker extends StatefulWidget {
  const _RangePicker({required this.initial});

  final TimeRange initial;

  @override
  State<_RangePicker> createState() => _RangePickerState();
}

class _RangePickerState extends State<_RangePicker> {
  static const _step = HoursValidator.step;
  // 00:00 … 24:00 (end of day allowed as an end).
  static final _slots = [for (var m = 0; m <= 24 * 60; m += _step) m];

  late int _start = _snap(widget.initial.start);
  late int _end = _snap(widget.initial.end);

  static int _snap(int m) => ((m / _step).round() * _step).clamp(0, 24 * 60);

  Widget _wheel(String label, int value, ValueChanged<int> onChanged) {
    final t = context.text;
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: t.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
          SizedBox(
            height: 180,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: _slots.indexOf(value).clamp(0, _slots.length - 1)),
              onSelectedItemChanged: (i) => onChanged(_slots[i]),
              children: [
                for (final s in _slots)
                  Center(
                    child: Text(
                      formatAiTime(context, s),
                      style: t.bodyLarge.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = context.text;
    final valid = _end > _start;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _wheel(l.ai_hours_start, _start, (v) => setState(() => _start = v)),
              const SizedBox(width: AppSpacing.md),
              _wheel(l.ai_hours_end, _end, (v) => setState(() => _end = v)),
            ],
          ),
          if (!valid)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(l.ai_hours_err_order, style: t.caption.copyWith(color: c.textError)),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.ai_save,
            expand: true,
            onPressed: valid ? () => Navigator.of(context).pop(TimeRange(_start, _end)) : null,
          ),
        ],
      ),
    );
  }
}
