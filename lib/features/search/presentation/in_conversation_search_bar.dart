import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/in_conversation_search_controller.dart';

/// Replaces the chat app bar in "بحث في المحادثة" (Search spec §11):
/// back · field · "{i} من {n}" · ▲ older / ▼ newer.
class InConversationSearchBar extends ConsumerStatefulWidget {
  const InConversationSearchBar({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<InConversationSearchBar> createState() => _InConversationSearchBarState();
}

class _InConversationSearchBarState extends ConsumerState<InConversationSearchBar> {
  late final TextEditingController _text = TextEditingController(
    text: ref.read(inConversationSearchProvider(widget.conversationId)).query,
  );

  InConversationSearchController get _ctrl => ref.read(inConversationSearchProvider(widget.conversationId).notifier);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(inConversationSearchProvider(widget.conversationId));
    final n = s.matches.length;
    final i = n == 0 ? 0 : s.index + 1;

    return Material(
      color: c.background,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs, end: AppSpacing.xs),
        child: Row(
          children: [
            AppIconButton(
              icon: AppIcons.back,
              iconSize: 24,
              semanticLabel: l.search_in_conv_close,
              onPressed: _ctrl.close,
            ),
            Expanded(
              child: SizedBox(
                height: 44,
                child: AppSearchField(
                  hint: l.search_in_conv_placeholder,
                  controller: _text,
                  autofocus: true,
                  showCancel: false,
                  onChanged: _ctrl.setQuery,
                  onSubmitted: (_) => _ctrl.previous(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                l.search_in_conv_count(i, n),
                style: t.caption.copyWith(color: n == 0 ? c.textTertiary : c.textSecondary),
              ),
            ),
            AppIconButton(
              icon: AppIcons.chevronUp,
              semanticLabel: l.search_in_conv_prev,
              onPressed: s.hasPrevious ? _ctrl.previous : null,
            ),
            AppIconButton(
              icon: AppIcons.chevronDown,
              semanticLabel: l.search_in_conv_next,
              onPressed: s.hasNext ? _ctrl.next : null,
            ),
          ],
        ),
      ),
    );
  }
}
