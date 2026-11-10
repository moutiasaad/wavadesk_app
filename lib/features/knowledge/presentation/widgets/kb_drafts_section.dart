import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';
import 'kb_entry_tile.dart';

/// "مقترحات بانتظار المراجعة · {n}" (admins, spec §4.7). Tap → Add Answer
/// prefilled with اعتماد / رفض (spec 13 draft mode).
class KbDraftsSection extends StatelessWidget {
  const KbDraftsSection({super.key, required this.drafts, required this.onOpen});

  final List<KbEntrySummary> drafts;
  final ValueChanged<KbEntrySummary> onOpen;

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SettingsGroup(
        title: context.l10n.kb_drafts(drafts.length),
        children: [for (final d in drafts) KbEntryTile(entry: d, onTap: () => onOpen(d))],
      ),
    );
  }
}
