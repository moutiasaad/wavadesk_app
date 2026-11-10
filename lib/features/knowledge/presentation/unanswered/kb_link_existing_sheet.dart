import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../domain/kb_entry.dart';
import '../widgets/kb_entry_tile.dart';

/// "ربط بإجابة موجودة" picker (spec §6.4): existing Q&A, searchable.
/// Returns the chosen entry.
Future<KbEntrySummary?> showKbLinkExistingSheet(BuildContext context) => AppBottomSheet.showExpanded<KbEntrySummary>(
      context,
      title: context.l10n.kb_pick_answer,
      builder: (_, controller) => _Picker(controller: controller),
    );

class _Picker extends ConsumerStatefulWidget {
  const _Picker({required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  late Future<List<KbEntrySummary>> _all = _fetch();

  Future<List<KbEntrySummary>> _fetch() => ref
      .read(kbApiProvider)
      .list(type: KbType.qa, sort: KbSort.usage, limit: 50)
      .then((p) => p.items.where((e) => e.status != KbStatus.draft).toList());
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: AppSearchField(hint: l.kb_pick_search, showCancel: false, onChanged: (v) => setState(() => _q = v)),
        ),
        Expanded(
          child: FutureBuilder<List<KbEntrySummary>>(
            future: _all,
            builder: (context, snap) {
              if (snap.hasError) {
                return EmptyState(
                  icon: AppIcons.error,
                  title: l.kb_error,
                  actionLabel: l.kb_retry,
                  onAction: () => setState(() => _all = _fetch()),
                );
              }
              if (!snap.hasData) return const Center(child: AppSpinner(delayed: false));
              final nq = ArabicNormalizer.normalize(_q.trim());
              final rows = nq.isEmpty ? snap.data! : snap.data!.where((e) => ArabicNormalizer.matches(e.title, nq)).toList();
              if (rows.isEmpty) return EmptyState(icon: AppIcons.search, title: l.kb_none_found);
              return ListView.separated(
                controller: widget.controller,
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                itemCount: rows.length,
                separatorBuilder: (_, _) => Divider(height: 1, indent: 60, color: c.divider),
                itemBuilder: (_, i) => KbEntryTile(entry: rows[i], onTap: () => Navigator.of(context).pop(rows[i])),
              );
            },
          ),
        ),
      ],
    );
  }
}
