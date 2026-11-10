import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// `@` teammate list in note mode (Chat spec §4.7.1): avatar + presence.
class MentionPanel extends StatelessWidget {
  const MentionPanel({super.key, required this.agents, required this.query, required this.onPick});

  final List<Agent> agents;

  /// Text typed after the last "@".
  final String query;
  final ValueChanged<Agent> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final q = query.trim().toLowerCase();
    final items = [
      for (final a in agents)
        if (q.isEmpty || a.name.toLowerCase().contains(q)) a,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: context.shadows.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 14, top: 6, bottom: 2),
              child: Text(l.composer_mention_title, style: t.caption.copyWith(color: c.textSecondary)),
            ),
            for (final a in items)
              InkWell(
                onTap: () => onPick(a),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: a.name,
                        id: a.id,
                        presence: a.presence,
                        size: AppAvatarSize.sm,
                        ringColor: c.surfaceElevated,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(a.name, style: t.listTitle.copyWith(fontSize: 14))),
                      Text(a.presence.label(l), style: t.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
