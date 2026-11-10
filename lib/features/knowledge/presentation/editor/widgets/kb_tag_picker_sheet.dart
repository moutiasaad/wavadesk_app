import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/kb_entry.dart';

/// Tag picker in KB-tag mode (Add Answer spec §6.1): the Profile tag editor
/// layout (search / create, selected chips with ✕, checkbox suggestions,
/// "تم"). The first selected tag is the primary one. Returns the new list,
/// or null when dismissed.
Future<List<KbTag>?> showKbTagPickerSheet(
  BuildContext context, {
  required List<KbTag> selected,
  required Future<List<KbTag>> Function() load,
}) {
  return AppBottomSheet.showExpanded<List<KbTag>>(
    context,
    title: context.l10n.kbe_tags_title,
    initialSize: 0.6,
    builder: (ctx, controller) => _KbTagPicker(selected: selected, load: load, controller: controller),
  );
}

class _KbTagPicker extends StatefulWidget {
  const _KbTagPicker({required this.selected, required this.load, required this.controller});

  final List<KbTag> selected;
  final Future<List<KbTag>> Function() load;
  final ScrollController controller;

  @override
  State<_KbTagPicker> createState() => _KbTagPickerState();
}

class _KbTagPickerState extends State<_KbTagPicker> {
  late final List<KbTag> _selected = [...widget.selected];
  List<KbTag> _all = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.load().then((tags) {
      if (mounted) setState(() => (_all = tags, _loading = false));
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  bool _isSelected(KbTag t) => _selected.any((s) => s.name == t.name);

  void _toggle(KbTag t) => setState(() {
        _isSelected(t) ? _selected.removeWhere((s) => s.name == t.name) : _selected.add(t);
      });

  void _create() {
    final name = _query.trim();
    if (name.isEmpty || _selected.any((s) => s.name == name)) return;
    setState(() => _selected.add(KbTag(id: name, name: name)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final q = _query.trim().toLowerCase();
    final suggestions = [for (final tag in _all) if (q.isEmpty || tag.name.toLowerCase().contains(q)) tag];
    final exact = q.isNotEmpty && ([..._all, ..._selected].any((s) => s.name.toLowerCase() == q));

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              AppSearchField(
                hint: l.kbe_tags_search,
                showCancel: false,
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) => _create(),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var i = 0; i < _selected.length; i++)
                      Semantics(
                        button: true,
                        label: i == 0 ? '${l.kbe_tags_primary}: ${_selected[i].name}' : _selected[i].name,
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => _toggle(_selected[i]),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 32),
                            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: i == 0 ? c.primary : c.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: i == 0 ? c.primary : c.primaryContainerBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selected[i].name,
                                  style: t.chipLabel.copyWith(color: i == 0 ? c.onPrimary : c.onPrimaryContainer),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(AppIcons.close, size: 14, color: i == 0 ? c.onPrimary : c.onPrimaryContainer),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('${l.kbe_tags_primary}: ${_selected.first.name}', style: t.caption.copyWith(color: c.textTertiary)),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (q.isNotEmpty && !exact) SheetActionRow(icon: AppIcons.plus, label: l.kbe_tags_create(_query.trim()), onTap: _create),
              if (_loading)
                const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: AppSpinner()))
              else
                for (final tag in suggestions)
                  Semantics(
                    checked: _isSelected(tag),
                    label: tag.name,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => _toggle(tag),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Row(
                          children: [
                            AppCheckbox(value: _isSelected(tag)),
                            const SizedBox(width: AppSpacing.md),
                            Icon(AppIcons.tag, size: 14, color: c.textTertiary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tag.name, style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600))),
                            if (tag.count > 0) Text('${tag.count}', style: t.caption.copyWith(color: c.textTertiary)),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          child: AppButton(
            label: l.kbe_done,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    );
  }
}
