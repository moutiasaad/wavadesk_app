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
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(inConversationSearchProvider(widget.conversationId));
    final n = s.matches.length;
    final i = n == 0 ? 0 : s.index + 1;

    // Same brand header as the chat header it replaces while searching.
    return BrandStatusBarBleed(
      child: BrandHeader(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.sm, AppSpacing.xs, AppSpacing.xs, AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              AppIconButton(
                icon: AppIcons.back,
                iconSize: 22,
                variant: AppIconButtonVariant.filled,
                semanticLabel: l.search_in_conv_close,
                onPressed: _ctrl.close,
              ),
              const SizedBox(width: AppSpacing.sm),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    l.search_in_conv_count(i, n),
                    style: t.caption.copyWith(
                      color: Colors.white.withValues(alpha: n == 0 ? 0.7 : 1),
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
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
      ),
    );
  }
}
