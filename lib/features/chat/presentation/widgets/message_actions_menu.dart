import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../customer/application/contact_notes_controller.dart';
import '../../../customer/data/contacts_repository.dart';
import '../../application/chat_controller.dart';
import '../../application/messages_controller.dart';
import 'bubbles/delivery_status.dart';
import 'bubbles/message_bubble.dart';

const _quickReactions = ['👍', '❤️', '😂', '😮', '🙏'];
const _allReactions = [
  '👍', '❤️', '😂', '😮', '🙏', '😢', '😡', '🎉', '👏', '🔥', '✅', '🙌', //
  '😊', '😍', '🤔', '👀', '💯', '🤝', '😅', '🥲', '🌹', '☕', '📦', '🚚',
];

/// Long-press menu (Chat spec §4.5): dimmed background (30%), the bubble
/// lifted (scale 1.02 + medium shadow) and a menu card above or below it,
/// fading/scaling in from 0.95 over 180ms.
Future<void> showMessageActionsMenu(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
  required Message message,
  required Rect bubbleRect,
  required void Function(Message m) onReply,
  bool readOnly = false,
  bool allowTranscribe = false,
}) {
  HapticFeedback.mediumImpact();
  final c = context.colors;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.l10n.common_close,
    barrierColor: c.secondary.withValues(alpha: c.isDark ? 0.5 : 0.3),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, _) => _MenuOverlay(
      conversationId: conversationId,
      message: message,
      bubbleRect: bubbleRect,
      onReply: onReply,
      readOnly: readOnly,
      allowTranscribe: allowTranscribe,
      hostContext: context,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: AppMotion.standard);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curve), child: child),
      );
    },
  );
}

class _MenuOverlay extends ConsumerWidget {
  const _MenuOverlay({
    required this.conversationId,
    required this.message,
    required this.bubbleRect,
    required this.onReply,
    required this.readOnly,
    this.allowTranscribe = false,
    required this.hostContext,
  });

  final String conversationId;
  final Message message;
  final Rect bubbleRect;
  final void Function(Message m) onReply;
  final bool readOnly;
  final bool allowTranscribe;

  /// Screen context for snackbars / navigation after the menu closes.
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final detail = ref.watch(chatDetailProvider(conversationId));
    if (detail == null) return const SizedBox.shrink();
    final m = message;
    final messages = ref.read(messagesControllerProvider(conversationId).notifier);

    final reactable =
        !readOnly &&
        m.type != MessageBubbleType.internalNote &&
        m.kind != MessageKind.deleted &&
        const {Channel.whatsapp, Channel.messenger, Channel.instagram}.contains(detail.channel);
    final own =
        m.type == MessageBubbleType.outgoing || (m.type == MessageBubbleType.internalNote && m.senderId == detail.meId);
    final canDelete = !readOnly && own && detail.permissions.canDeleteMessages && m.kind != MessageKind.deleted;
    final hasText = m.text.trim().isNotEmpty;

    void close() => Navigator.of(context).pop();

    final actions = <(IconData, String, VoidCallback, bool)>[
      if (!readOnly && m.type != MessageBubbleType.internalNote && m.kind != MessageKind.deleted)
        (
          AppIcons.reply,
          l.msgaction_reply,
          () {
            close();
            onReply(m);
          },
          false,
        ),
      if (hasText)
        (
          AppIcons.copy,
          l.msgaction_copy,
          () {
            Clipboard.setData(ClipboardData(text: m.text));
            close();
            AppSnackbar.show(hostContext, message: l.msgaction_copied);
          },
          false,
        ),
      if (!readOnly && hasText && m.type != MessageBubbleType.internalNote)
        (
          AppIcons.saveToKb,
          l.msgaction_save_kb,
          () {
            close();
            hostContext.push(_knowledgeRoute(detail.conversation.messages, m));
          },
          false,
        ),
      // Promote a conversation note to a contact-level profile note
      // (Profile spec §7.3).
      if (m.type == MessageBubbleType.internalNote && hasText && detail.hasProfile)
        (
          AppIcons.customer,
          l.msgaction_add_to_profile,
          () async {
            close();
            await ref.read(contactsRepositoryProvider).fetch(detail.contact.id);
            await ref.read(contactNotesProvider(detail.contact.id)).add(m.text, mentions: m.mentions);
            if (hostContext.mounted) {
              AppSnackbar.show(hostContext, message: l.msgaction_added_to_profile, kind: SnackKind.success);
            }
          },
          false,
        ),
      if ((!readOnly || allowTranscribe) &&
          m.type == MessageBubbleType.incoming &&
          m.kind == MessageKind.voice &&
          m.transcript == null)
        (
          AppIcons.voice,
          l.chat_transcribe,
          () {
            close();
            messages.transcribe(m.id);
          },
          false,
        ),
      (
        AppIcons.info,
        l.msgaction_info,
        () {
          close();
          _showInfo(hostContext, m, detail.channel);
        },
        false,
      ),
      if (canDelete)
        (
          AppIcons.delete,
          l.chat_delete,
          () async {
            close();
            final ok = await AppDialog.confirm(
              hostContext,
              title: l.msgaction_delete_title,
              body: l.msgaction_delete_body,
              confirmLabel: l.chat_delete,
              icon: AppIcons.delete,
            );
            if (ok) messages.delete(m.id);
          },
          true,
        ),
    ];

    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    const menuWidth = 240.0;
    final estimatedHeight =
        52.0 * actions.length +
        (reactable ? 60 : 0) +
        (m.type == MessageBubbleType.outgoingAi && !readOnly ? 52 : 0) +
        16;
    final spaceBelow = screen.height - padding.bottom - bubbleRect.bottom;
    final below = spaceBelow > estimatedHeight + 12 || bubbleRect.top - padding.top < estimatedHeight + 12;
    final outgoing = m.isOutgoing;
    // Align the menu with the bubble's side (own messages are on the right).
    final alignRight = outgoing;
    final left = (alignRight ? bubbleRect.right - menuWidth : bubbleRect.left).clamp(
      12.0,
      screen.width - menuWidth - 12,
    );
    final top = below
        ? (bubbleRect.bottom + 8).clamp(padding.top + 8, screen.height - estimatedHeight - padding.bottom - 8)
        : (bubbleRect.top - estimatedHeight - 8).clamp(padding.top + 8, screen.height);
    final lifted = bubbleRect.height < screen.height * 0.6;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(onTap: close, behavior: HitTestBehavior.opaque),
        ),
        if (lifted)
          Positioned(
            left: 0,
            right: 0,
            top: bubbleRect.top,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1.02,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: DecoratedBox(
                    decoration: BoxDecoration(boxShadow: context.shadows.medium),
                    child: MessageBubble(
                      conversationId: conversationId,
                      message: m,
                      detail: detail,
                      maxWidth: bubbleRect.width,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: left,
          top: top,
          width: menuWidth,
          child: Material(
            color: c.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: context.shadows.medium,
                border: c.isDark ? Border.all(color: c.border) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (reactable) _ReactionRow(message: m, conversationId: conversationId, onDone: close),
                  if (m.type == MessageBubbleType.outgoingAi && !readOnly)
                    _RateRow(message: m, conversationId: conversationId, hostContext: hostContext, onDone: close),
                  for (final (icon, label, onTap, destructive) in actions)
                    _MenuRow(icon: icon, label: label, onTap: onTap, destructive: destructive),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "حفظ في قاعدة المعرفة" → Add Answer from this message (spec 13 §2).
  /// Customer message: question = it, answer = the agent/AI reply after it.
  /// Agent/AI reply: question = the last customer message before it. The
  /// texts are hints for the sample API; the real one reads kb-prefill.
  static String _knowledgeRoute(List<Message> all, Message m) {
    final i = all.indexWhere((x) => x.id == m.id);
    if (m.type == MessageBubbleType.incoming) {
      String? answer;
      for (var j = (i < 0 ? all.length : i + 1); j < all.length; j++) {
        if (all[j].type == MessageBubbleType.internalNote) continue;
        if (all[j].isOutgoing && all[j].text.trim().isNotEmpty) {
          answer = all[j].text;
          break;
        }
        if (all[j].type == MessageBubbleType.incoming) break;
      }
      return Routes.knowledgeFromMessage(m.id, question: m.text, answer: answer);
    }
    var question = '';
    for (var j = (i < 0 ? all.length : i) - 1; j >= 0; j--) {
      if (all[j].type == MessageBubbleType.incoming && all[j].text.trim().isNotEmpty) {
        question = all[j].text;
        break;
      }
    }
    return Routes.knowledgeFromMessage(m.id, question: question, answer: m.text);
  }

  static void _showInfo(BuildContext context, Message m, Channel channel) {
    final l = context.l10n;
    final via = switch (m.sentVia) {
      'ai_suggestion' => l.msgaction_via_ai_suggestion,
      'ai_edited' => l.msgaction_via_ai_edited,
      'quick_reply' => l.msgaction_via_quick_reply,
      'template' => l.msgaction_via_template,
      'manual' => l.msgaction_via_manual,
      _ => null,
    };
    AppBottomSheet.show<void>(
      context,
      title: l.msgaction_info_title,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            SettingsTile(
              icon: AppIcons.clock,
              title: l.msgaction_info_sent,
              value: '${AppFormat.date(ctx, m.sentAt)} ${AppFormat.time(ctx, m.sentAt)}',
              showChevron: false,
            ),
            if (m.isOutgoing)
              SettingsTile(
                icon: AppIcons.read,
                title: l.msgaction_info_status,
                value: DeliveryStatus.label(l, m.delivery),
                showChevron: false,
              ),
            SettingsTile(
              icon: channel.glyph,
              title: l.msgaction_info_channel,
              value: channel.label(l),
              showChevron: false,
            ),
            if (via != null)
              SettingsTile(icon: AppIcons.send, title: l.msgaction_info_via, value: via, showChevron: false),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = destructive ? c.textError : c.textPrimary;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              AppIcon(icon, color: destructive ? c.textError : c.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionRow extends ConsumerWidget {
  const _ReactionRow({required this.message, required this.conversationId, required this.onDone});

  final Message message;
  final String conversationId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    final mine = {
      for (final r in message.reactions)
        if (!r.byContact) r.emoji,
    };

    void react(String e) {
      HapticFeedback.lightImpact();
      ref.read(messagesControllerProvider(conversationId).notifier).react(message.id, e);
      onDone();
    }

    Widget cell(String emoji) => Semantics(
      button: true,
      selected: mine.contains(emoji),
      label: l.msgaction_react(emoji),
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => react(emoji),
        radius: 22,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mine.contains(emoji) ? c.primaryContainer : Colors.transparent,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final e in _quickReactions) cell(e),
          AppIconButton(
            icon: AppIcons.addReaction,
            size: 36,
            semanticLabel: l.msgaction_more_reactions,
            onPressed: () async {
              final picked = await AppBottomSheet.show<String>(
                context,
                title: l.msgaction_pick_reaction,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final e in _allReactions)
                        Semantics(
                          button: true,
                          label: l.msgaction_react(e),
                          excludeSemantics: true,
                          child: InkResponse(
                            onTap: () => Navigator.pop(ctx, e),
                            child: SizedBox.square(
                              dimension: 52,
                              child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
              if (picked != null) react(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _RateRow extends ConsumerWidget {
  const _RateRow({
    required this.message,
    required this.conversationId,
    required this.hostContext,
    required this.onDone,
  });

  final Message message;
  final String conversationId;
  final BuildContext hostContext;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = context.l10n;
    void rate(String r) {
      ref.read(messagesControllerProvider(conversationId).notifier).feedback(message.id, r);
      onDone();
      AppSnackbar.show(hostContext, message: l.msgaction_rated, kind: SnackKind.success);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg, end: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.ai, color: c.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(l.msgaction_rate, style: context.text.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ),
          AppIconButton(
            icon: AppIcons.thumbsUp,
            semanticLabel: l.msgaction_rate_up,
            iconColor: message.aiFeedback == 'up' ? c.primary : c.textSecondary,
            onPressed: () => rate('up'),
          ),
          AppIconButton(
            icon: AppIcons.thumbsDown,
            semanticLabel: l.msgaction_rate_down,
            iconColor: message.aiFeedback == 'down' ? c.error : c.textSecondary,
            onPressed: () => rate('down'),
          ),
        ],
      ),
    );
  }
}
