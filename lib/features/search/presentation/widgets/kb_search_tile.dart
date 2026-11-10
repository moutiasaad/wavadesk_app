import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/search_query.dart';
import 'highlighted_text.dart';

/// KB hit: tinted 34 tile, highlighted title, usage or answer snippet,
/// chevron (Search spec §6.4). [onInsert] only when opened from a chat.
class KbSearchTile extends StatelessWidget {
  const KbSearchTile({super.key, required this.hit, required this.query, required this.onTap, this.onInsert});

  final KbHit hit;
  final String query;
  final VoidCallback onTap;
  final VoidCallback? onInsert;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final (Color bg, Color fg, IconData icon) = switch (hit.type) {
      KbHitType.qa => (c.primaryContainer, c.primary, AppIcons.help),
      KbHitType.file => (c.infoContainer, c.info, AppIcons.file),
      KbHitType.link => (c.warningContainer, c.warning, AppIcons.link),
    };
    final subStyle = t.bodySmall.copyWith(color: c.textSecondary);

    final tile = MergeSemantics(
      child: InkWell(
        onTap: onTap,
        onLongPress: onInsert,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenH, end: AppSpacing.md, top: 10, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    hit.titleHighlight != null
                        ? HighlightedText(markup: hit.titleHighlight, style: t.listTitle.copyWith(fontSize: 14.5))
                        : HighlightedText(text: hit.title, query: query, style: t.listTitle.copyWith(fontSize: 14.5)),
                    const SizedBox(height: 2),
                    hit.snippet != null
                        ? HighlightedText(markup: hit.snippet, style: subStyle, maxLines: 2)
                        : Text(l.search_kb_usage(hit.usageMonth), style: subStyle, maxLines: 1),
                  ],
                ),
              ),
              if (onInsert != null)
                IconButton(
                  tooltip: l.search_insert_reply,
                  onPressed: onInsert,
                  icon: Icon(AppIcons.reply, size: 18, color: c.primary),
                ),
              Icon(AppIcons.chevronEnd, size: 16, color: c.borderStrong),
            ],
          ),
        ),
      ),
    );
    return tile;
  }
}
