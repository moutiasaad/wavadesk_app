import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';

String kbSortLabel(AppLocalizations l, KbSort s) => switch (s) {
      KbSort.usage => l.kb_sort_usage,
      KbSort.updatedDesc => l.kb_sort_recent,
      KbSort.updatedAsc => l.kb_sort_stale,
      KbSort.alpha => l.kb_sort_alpha,
      KbSort.usageAsc => l.kb_sort_least,
    };

/// "{sortLabel} ▾" + optional "الوسوم ▾" (spec §4.5).
class KbSortHeader extends StatelessWidget {
  const KbSortHeader({
    super.key,
    required this.sort,
    required this.onSort,
    required this.selectedTags,
    required this.loadTags,
    required this.onTags,
  });

  final KbSort sort;
  final ValueChanged<KbSort> onSort;
  final Set<String> selectedTags;
  final Future<List<KbTag>> Function() loadTags;
  final ValueChanged<Set<String>> onTags;

  Future<void> _pickSort(BuildContext context) async {
    final l = context.l10n;
    final picked = await AppBottomSheet.show<KbSort>(
      context,
      title: l.kb_sort_by,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in KbSort.values)
            AppRadioRow(
              label: kbSortLabel(l, s),
              selected: s == sort,
              onTap: () => Navigator.of(ctx).pop(s),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
    if (picked != null && picked != sort) {
      Analytics.log('kb_sort', {'value': picked.wire});
      onSort(picked);
    }
  }

  Future<void> _pickTags(BuildContext context) async {
    final result = await AppBottomSheet.show<Set<String>>(
      context,
      title: context.l10n.kb_tags,
      builder: (ctx) => _TagsSheet(load: loadTags, initial: selectedTags),
    );
    if (result != null) {
      Analytics.log('kb_tag_filter', {'value': result.length});
      onTags(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final style = t.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary);

    Widget dropdown(String label, VoidCallback onTap, {bool active = false}) => InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: active ? style.copyWith(color: c.primary) : style),
                  const SizedBox(width: 2),
                  AppIcon(AppIcons.chevronDown, size: AppIconSize.xs, color: active ? c.primary : c.textSecondary),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 22, 16, 6),
      child: Row(
        children: [
          Semantics(button: true, child: dropdown(kbSortLabel(l, sort), () => _pickSort(context))),
          const Spacer(),
          Semantics(
            button: true,
            child: dropdown(
              selectedTags.isEmpty ? l.kb_tags : '${l.kb_tags} · ${selectedTags.length}',
              () => _pickTags(context),
              active: selectedTags.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsSheet extends StatefulWidget {
  const _TagsSheet({required this.load, required this.initial});

  final Future<List<KbTag>> Function() load;
  final Set<String> initial;

  @override
  State<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends State<_TagsSheet> {
  late final Set<String> _sel = {...widget.initial};
  late final Future<List<KbTag>> _tags = widget.load();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return FutureBuilder<List<KbTag>>(
      future: _tags,
      builder: (context, snap) {
        if (!snap.hasData && !snap.hasError) {
          return const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: Center(child: AppSpinner(delayed: false)));
        }
        final tags = snap.data ?? const <KbTag>[];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(l.kb_tags_none, style: context.text.bodySmall.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              ),
            for (final tag in tags)
              InkWell(
                onTap: () => setState(() => _sel.contains(tag.id) ? _sel.remove(tag.id) : _sel.add(tag.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      AppCheckbox(value: _sel.contains(tag.id)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(tag.name, style: context.text.bodyLarge)),
                      if (tag.count > 0) Text('${tag.count}', style: context.text.caption.copyWith(color: c.textTertiary)),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l.kb_tags_all,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(<String>{}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppButton(label: l.kb_tags_apply, onPressed: () => Navigator.of(context).pop(_sel))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
