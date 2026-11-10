import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../../domain/ai_agent_config.dart';
import '../../domain/hours_validator.dart';
import '../ai_config_gate.dart';
import '../ai_save_feedback.dart';
import 'time_range_picker_sheet.dart';

String aiDayLabel(AppLocalizations l, String day) => switch (day) {
      'sat' => l.ai_day_sat,
      'sun' => l.ai_day_sun,
      'mon' => l.ai_day_mon,
      'tue' => l.ai_day_tue,
      'wed' => l.ai_day_wed,
      'thu' => l.ai_day_thu,
      'fri' => l.ai_day_fri,
      _ => day,
    };

/// "الرياض (GMT+3)" for known zones, else the IANA id.
String aiTimezoneLabel(BuildContext context, String tz) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  const known = {
    'Asia/Riyadh': ('الرياض', 'Riyadh', '+3'),
    'Asia/Dubai': ('دبي', 'Dubai', '+4'),
    'Asia/Kuwait': ('الكويت', 'Kuwait', '+3'),
    'Asia/Qatar': ('الدوحة', 'Doha', '+3'),
    'Asia/Bahrain': ('المنامة', 'Manama', '+3'),
    'Africa/Cairo': ('القاهرة', 'Cairo', '+2'),
    'Africa/Tunis': ('تونس', 'Tunis', '+1'),
    'Africa/Algiers': ('الجزائر', 'Algiers', '+1'),
    'Africa/Casablanca': ('الدار البيضاء', 'Casablanca', '+1'),
  };
  final k = known[tz];
  if (k == null) return tz;
  return '${ar ? k.$1 : k.$2} (GMT${k.$3})';
}

/// Working hours editor (AI Agent spec §5.1). Edits a local draft; **حفظ**
/// saves the whole `hours` object.
class WorkingHoursScreen extends StatelessWidget {
  const WorkingHoursScreen({super.key});

  // The draft is seeded from the loaded config, so wait for it.
  @override
  Widget build(BuildContext context) => AiConfigGate(title: context.l10n.ai_hours, builder: (_) => const _WorkingHoursEditor());
}

class _WorkingHoursEditor extends ConsumerStatefulWidget {
  const _WorkingHoursEditor();

  @override
  ConsumerState<_WorkingHoursEditor> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends ConsumerState<_WorkingHoursEditor> {
  late WorkingHours _saved;
  late WorkingHours _draft;
  List<Holiday> _presets = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = ref.read(aiAgentControllerProvider).config?.hours ?? const WorkingHours();
    _saved = _normalized(h);
    _draft = _saved;
    _loadHolidays();
  }

  /// All 7 days present, in display order.
  static WorkingHours _normalized(WorkingHours h) => h.copyWith(week: [for (final d in weekDays) h.day(d)]);

  Future<void> _loadHolidays() async {
    try {
      final list = await ref.read(aiAgentApiProvider).holidays(year: DateTime.now().year);
      if (mounted) setState(() => _presets = list);
    } catch (_) {}
  }

  /// Server presets merged with saved choices (saved wins on `enabled`).
  List<Holiday> get _holidays {
    final byId = {for (final h in _presets) h.id: h};
    for (final h in _draft.holidays) {
      byId[h.id] = h;
    }
    final list = byId.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  bool get _dirty => jsonLike(_draft) != jsonLike(_saved);

  static String jsonLike(WorkingHours h) => h.toJson().toString();

  void _setDay(String day, DayHours Function(DayHours d) edit) =>
      setState(() => _draft = _draft.copyWith(week: [for (final d in _draft.week) d.day == day ? edit(d) : d]));

  Future<void> _pickRange(String day, int index) async {
    final d = _draft.day(day);
    final initial = index < d.ranges.length ? d.ranges[index] : const TimeRange(9 * 60, 17 * 60);
    final r = await showTimeRangePicker(context, initial: initial);
    if (r == null) return;
    _setDay(day, (d) {
      final ranges = [...d.ranges];
      index < ranges.length ? ranges[index] = r : ranges.add(r);
      return d.copyWith(ranges: ranges);
    });
  }

  void _addRange(String day) {
    final d = _draft.day(day);
    if (d.ranges.length >= HoursValidator.maxRanges) return;
    final last = d.ranges.isEmpty ? null : d.ranges.last;
    final start = last == null ? 9 * 60 : (last.end + 60).clamp(0, 23 * 60);
    final end = (start + 4 * 60).clamp(start + HoursValidator.step, 24 * 60);
    _setDay(day, (d) => d.copyWith(ranges: [...d.ranges, TimeRange(start, end)]));
  }

  void _copyToAll(String from) {
    final src = _draft.day(from);
    setState(() => _draft = _draft.copyWith(week: [for (final d in _draft.week) d.copyWith(open: src.open, ranges: src.ranges)]));
  }

  void _toggleHoliday(Holiday h, bool on) {
    final rest = [for (final x in _draft.holidays) if (x.id != h.id) x];
    setState(() => _draft = _draft.copyWith(holidays: [...rest, h.copyWith(enabled: on)]));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final draft = _draft.copyWith(holidays: _holidays);
    Analytics.log('ai_hours_save', {'is_24h': draft.is24h, 'days_open': draft.week.where((d) => d.open).length});
    final nav = Navigator.of(context);
    final r = await saveAiChange(context, ref, (c) => c.copyWith(hours: draft));
    if (!mounted) return;
    setState(() => _saving = false);
    if (r == AiSaveResult.saved) {
      _saved = draft;
      nav.pop();
    }
  }

  Future<bool> _confirmDiscard() {
    final l = context.l10n;
    return AppDialog.confirm(
      context,
      title: l.ai_hours_discard,
      body: l.ai_hours_discard_body,
      confirmLabel: l.ai_hours_discard_confirm,
      severity: DialogSeverity.warning,
    );
  }

  String? _errorText(AppLocalizations l, HoursError? e) => switch (e) {
        HoursError.endBeforeStart => l.ai_hours_err_order,
        HoursError.overlap => l.ai_hours_err_overlap,
        HoursError.tooManyRanges => l.ai_hours_err_max,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final canEdit = ref.watch(aiAgentControllerProvider.select((s) => s.config?.canEdit ?? false));
    final errors = HoursValidator.validate(_draft);
    final canSave = canEdit && _dirty && errors.isEmpty && !_saving;

    Widget row({required Widget child}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: child,
        );

    return PopScope(
      canPop: !_dirty || !canEdit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmDiscard()) {
          setState(() => _draft = _saved);
          nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(
          title: l.ai_hours,
          actions: [if (canEdit) AppBarTextAction(label: l.ai_save, onPressed: canSave ? _save : null)],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xxl),
            children: [
              SettingsGroup(
                children: [
                  _SwitchRow(
                    title: l.ai_hours_247,
                    value: _draft.is24h,
                    onChanged: canEdit ? (v) => setState(() => _draft = _draft.copyWith(is24h: v)) : null,
                  ),
                ],
              ),
              if (!_draft.is24h) ...[
                const SizedBox(height: AppSpacing.md),
                SettingsGroup(
                  children: [
                    for (final day in weekDays)
                      _DayRow(
                        label: aiDayLabel(l, day),
                        day: _draft.day(day),
                        error: _errorText(l, errors[day]),
                        enabled: canEdit,
                        onOpen: (v) => _setDay(day, (d) => d.copyWith(
                              open: v,
                              ranges: v && d.ranges.isEmpty ? const [TimeRange(9 * 60, 17 * 60)] : d.ranges,
                            )),
                        onEditRange: (i) => _pickRange(day, i),
                        onRemoveRange: (i) => _setDay(day, (d) => d.copyWith(ranges: [...d.ranges]..removeAt(i))),
                        onAddRange: () => _addRange(day),
                        onCopyToAll: () => _copyToAll(day),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SettingsGroup(
                children: [
                  SettingsTile(
                    title: l.ai_hours_timezone,
                    icon: AppIcons.globe,
                    value: aiTimezoneLabel(context, _draft.timezone),
                    showChevron: false,
                  ),
                ],
              ),
              if (_holidays.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SettingsGroup(
                  title: l.ai_hours_holidays,
                  children: [
                    for (final h in _holidays)
                      _SwitchRow(
                        title: h.name,
                        subtitle: h.date,
                        value: h.enabled,
                        onChanged: canEdit ? (v) => _toggleHoliday(h, v) : null,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (!canEdit)
                row(child: Text(l.ai_readonly, style: t.caption.copyWith(color: c.textTertiary))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: t.listTitle),
                      if (subtitle != null) Text(subtitle!, style: t.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                AppSwitch(value: value, semanticLabel: title, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.day,
    required this.error,
    required this.enabled,
    required this.onOpen,
    required this.onEditRange,
    required this.onRemoveRange,
    required this.onAddRange,
    required this.onCopyToAll,
  });

  final String label;
  final DayHours day;
  final String? error;
  final bool enabled;
  final ValueChanged<bool> onOpen;
  final ValueChanged<int> onEditRange;
  final ValueChanged<int> onRemoveRange;
  final VoidCallback onAddRange;
  final VoidCallback onCopyToAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: enabled ? () => onOpen(!day.open) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: t.listTitle)),
                    if (!day.open) Text(l.ai_hours_closed, style: t.bodySmall.copyWith(color: c.textTertiary)),
                    const SizedBox(width: AppSpacing.sm),
                    AppSwitch(value: day.open, semanticLabel: label, onChanged: enabled ? onOpen : null),
                  ],
                ),
              ),
            ),
          ),
          if (day.open) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < day.ranges.length; i++)
                  InputChip(
                    label: Text(
                      '${formatAiTime(context, day.ranges[i].start)} – ${formatAiTime(context, day.ranges[i].end)}',
                      style: t.chipLabel,
                    ),
                    onPressed: enabled ? () => onEditRange(i) : null,
                    onDeleted: enabled && day.ranges.length > 1 ? () => onRemoveRange(i) : null,
                    isEnabled: enabled,
                  ),
                if (enabled && day.ranges.length < HoursValidator.maxRanges)
                  TextButton(onPressed: onAddRange, child: Text(l.ai_hours_add_range, style: t.buttonSmall.copyWith(color: c.primary))),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(error!, style: t.caption.copyWith(color: c.textError)),
              ),
            if (enabled)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onCopyToAll,
                  child: Text(l.ai_hours_copy_all, style: t.buttonSmall.copyWith(color: c.textSecondary)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
