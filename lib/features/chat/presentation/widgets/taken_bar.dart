import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/span_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/conversation_detail.dart';
import 'claim_bar.dart';

/// Taken bar (Claim v2 §4.6): the conversation is with a colleague. Same
/// panel as the Claim bar: assignee avatar 32 + "مع {name}" (14/800) and
/// "استلمها منذ {t}"; "طلب الاستلام" (outline 46) notifies the assignee;
/// leads/admins also get "إعادة إسناد"; everyone can add an internal note.
class TakenBar extends StatelessWidget {
  const TakenBar({
    super.key,
    required this.detail,
    required this.onRequest,
    this.onReassign,
    this.onNote,
  });

  final ConversationDetail detail;
  final VoidCallback onRequest;

  /// Leads / admins only.
  final VoidCallback? onReassign;
  final VoidCallback? onNote;

  /// When the current owner took it: the newest claimed / assigned event.
  DateTime? _since() {
    final msgs = detail.conversation.messages;
    for (var i = msgs.length - 1; i >= 0; i--) {
      final k = msgs[i].systemEvent?.kind;
      if (k == SystemEventKind.claimed || k == SystemEventKind.assigned) return msgs[i].sentAt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final who = detail.assignee;
    final name = who?.name ?? '';
    final since = _since();
    final ago = since == null ? null : SpanFormat.compact(DateTime.now().difference(since).inSeconds.clamp(60, 1 << 31), l);

    return Semantics(
      container: true,
      liveRegion: true,
      child: ClaimPanel(
        bottomInset: MediaQuery.viewPaddingOf(context).bottom,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppAvatar(name: name, id: who?.id ?? '', imageUrl: who?.avatarUrl, size: AppAvatarSize.sm),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.claim_sub_with(name),
                        style: t.h6.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ago != null)
                        Text(l.taken_since(ago), style: t.caption.copyWith(fontSize: 12, color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClaimBarButton(
              primary: false,
              height: 46,
              icon: AppIcons.claim,
              iconSize: 16,
              label: l.taken_request,
              onPressed: onRequest,
            ),
            if (onReassign != null) ...[
              const SizedBox(height: 10),
              ClaimBarButton(
                primary: false,
                height: 46,
                icon: AppIcons.team,
                iconSize: 16,
                label: l.taken_reassign,
                onPressed: onReassign,
              ),
            ],
            if (onNote != null) ...[
              const SizedBox(height: 2),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    textStyle: t.buttonSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    minimumSize: const Size(48, 36),
                  ),
                  onPressed: onNote,
                  child: Text(l.readonly_add_note),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
