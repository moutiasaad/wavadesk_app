import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';
import '../../domain/kb_subtitle_formatter.dart';

enum _More { ignore, conversations }

Channel kbChannel(String wire) => switch (wire) {
      'whatsapp' || 'wacloud' => Channel.whatsapp,
      'web' || 'webchat' => Channel.web,
      'messenger' => Channel.messenger,
      'instagram' => Channel.instagram,
      'email' => Channel.email,
      'telegram' => Channel.telegram,
      'sms' => Channel.sms,
      _ => Channel.other,
    };

/// One grouped unanswered question (Knowledge Base spec §6.4).
class KbUnansweredCard extends StatefulWidget {
  const KbUnansweredCard({
    super.key,
    required this.item,
    required this.canEdit,
    required this.onAdd,
    required this.onLink,
    required this.onIgnore,
    required this.onViewConversations,
  });

  final KbUnanswered item;
  final bool canEdit;

  /// "أضف إجابة" (or "اقترح إجابة" without edit permission).
  final VoidCallback onAdd;
  final VoidCallback onLink;
  final VoidCallback onIgnore;
  final VoidCallback onViewConversations;

  @override
  State<KbUnansweredCard> createState() => _KbUnansweredCardState();
}

class _KbUnansweredCardState extends State<KbUnansweredCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final u = widget.item;
    final channels = {for (final ch in u.channels) kbChannel(ch)};

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(u.question, style: t.listTitle.copyWith(fontSize: 15))),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<_More>(
                  padding: EdgeInsets.zero,
                  icon: Icon(AppIcons.more, size: 18, color: c.textSecondary),
                  tooltip: l.common_more,
                  onSelected: (m) => m == _More.ignore ? widget.onIgnore() : widget.onViewConversations(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _More.ignore, child: Text(l.kb_ignore)),
                    PopupMenuItem(value: _More.conversations, child: Text(l.kb_view_convs)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  l.kb_asked_n(u.count, KbSubtitleFormatter.span(l, u.lastAskedAt)),
                  style: t.caption.copyWith(color: c.textSecondary),
                ),
              ),
              for (final ch in channels) ...[const SizedBox(width: 6), ChannelBadge.avatar(channel: ch, size: 16)],
            ],
          ),
          if (u.variants.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_expanded ? l.kb_show_less : l.kb_similar(u.variants.length), style: t.caption.copyWith(color: c.primary)),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppMotion.fast,
                      child: Icon(AppIcons.chevronDown, size: 12, color: c.primary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.fast,
              alignment: AlignmentDirectional.topStart,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final v in u.variants)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• $v', style: t.bodySmall.copyWith(color: c.textSecondary)),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
          if (u.draftAnswer != null && u.draftAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: c.primaryContainerBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.sparkle, size: 12, color: c.primary),
                      const SizedBox(width: 4),
                      Text(l.kb_ai_draft, style: t.caption.copyWith(color: c.onPrimaryContainer, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(u.draftAnswer!, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: widget.canEdit ? l.kb_add_answer : l.kb_suggest_answer,
                size: AppButtonSize.small,
                icon: AppIcons.plus,
                onPressed: widget.onAdd,
              ),
              if (widget.canEdit)
                AppButton(
                  label: l.kb_link_existing,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.secondary,
                  icon: AppIcons.link,
                  onPressed: widget.onLink,
                ),
            ],
          ),
        ],
      ),
    );

    final onAction = c.isDark ? c.background : Colors.white;
    // Swipe toward the start edge → تجاهل (with Undo by the caller).
    return Semantics(
      customSemanticsActions: {CustomSemanticsAction(label: l.kb_ignore): widget.onIgnore},
      child: Slidable(
        key: ValueKey('unq-${u.id}'),
        groupTag: 'kb-unanswered',
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          dismissible: DismissiblePane(
            dismissThreshold: 0.5,
            resizeDuration: AppMotion.normal,
            onDismissed: widget.onIgnore,
          ),
          children: [
            CustomSlidableAction(
              backgroundColor: c.textSecondary,
              foregroundColor: onAction,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onPressed: (_) => widget.onIgnore(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.archive, size: 20, color: onAction),
                  const SizedBox(height: 4),
                  Text(l.kb_ignore, style: t.caption.copyWith(color: onAction)),
                ],
              ),
            ),
          ],
        ),
        child: card,
      ),
    );
  }
}
