import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../search/application/in_conversation_search_controller.dart';
import '../../../application/messages_controller.dart';
import '../../../domain/conversation_detail.dart';
import '../system_event_pill.dart';
import 'album_content.dart';
import 'contact_card_content.dart';
import 'delivery_status.dart';
import 'email_content.dart';
import 'file_content.dart';
import 'image_content.dart';
import 'location_content.dart';
import 'reactions_chip.dart';
import 'reply_quote.dart';
import 'text_content.dart';
import 'video_content.dart';
import 'voice_message_player.dart';

/// One chat message (Chat spec §4.4, DS §8.4). Switches by sender type
/// (bubble variant) and content kind.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.conversationId,
    required this.message,
    required this.detail,
    this.firstInGroup = true,
    this.lastInGroup = true,
    this.maxWidth = 300,
    this.onQuoteTap,
  });

  final String conversationId;
  final Message message;
  final ConversationDetail detail;
  final bool firstInGroup;

  /// Only the last bubble of a group has the tail and the status row.
  final bool lastInGroup;

  /// 80% of the list width.
  final double maxWidth;
  final void Function(String messageId)? onQuoteTap;

  /// Screen-reader summary (§11): "{sender}، {content}، {time}، {delivery}".
  static String describe(BuildContext context, Message m, ConversationDetail d) {
    final l = context.l10n;
    final sender = switch (m.type) {
      MessageBubbleType.incoming => d.contact.name,
      MessageBubbleType.outgoing => l.common_you,
      MessageBubbleType.outgoingColleague => m.senderName ?? '',
      MessageBubbleType.outgoingAi => l.chat_ai_reply_label,
      MessageBubbleType.internalNote => l.chat_note_label(m.senderName ?? ''),
      MessageBubbleType.system => '',
    };
    if (m.type == MessageBubbleType.system) return SystemEventPill.text(context, m, d.meId);
    final content = switch (m.kind) {
      MessageKind.text => m.text,
      MessageKind.image => m.type == MessageBubbleType.incoming ? l.bubble_image_from(d.contact.name) : l.media_image,
      MessageKind.album => l.bubble_album_summary(m.albumCount),
      MessageKind.video => l.bubble_video_summary(AppFormat.clock(m.mediaDuration ?? Duration.zero)),
      MessageKind.voice => l.bubble_voice_summary(m.mediaDuration?.inSeconds ?? 0),
      MessageKind.file => '${l.media_file} ${m.fileName ?? ''}',
      MessageKind.location => '${l.media_location} ${m.locationLabel ?? ''}',
      MessageKind.contact => '${l.media_contact} ${m.contactName ?? ''}',
      MessageKind.sticker => l.media_sticker,
      MessageKind.template => '${l.bubble_template_label(m.templateName ?? '')}، ${m.text}',
      MessageKind.email => '${m.emailSubject ?? ''} ${m.text}',
      MessageKind.deleted => l.chat_deleted,
      MessageKind.unsupported => l.chat_unsupported,
    };
    return [
      '$sender: $content',
      AppFormat.time(context, m.sentAt),
      if (m.isOutgoing) DeliveryStatus.label(l, m.delivery),
      if (m.edited) l.chat_edited,
    ].join('، ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final m = message;

    if (m.type == MessageBubbleType.system) return SystemEventPill(message: m, meId: detail.meId);
    // In-conversation search (Search spec §11): marks + current-match outline.
    final search = ref.watch(
      inConversationSearchProvider(conversationId).select((s) => s.active ? (s.normalized, s.currentId) : ('', null)),
    );
    final query = search.$1;
    final current = search.$2 == m.id;
    if (m.type == MessageBubbleType.internalNote) {
      return _SearchOutline(
        active: current,
        radius: BorderRadius.circular(AppRadius.lg),
        child: _NoteCard(message: m, lastInGroup: lastInGroup, searchQuery: query),
      );
    }

    final outgoing = m.isOutgoing;
    // Own messages always sit on the right, customer messages on the left,
    // in every language: in RTL the right edge is the logical start.
    final endSide = outgoing != context.isRtl;
    final (Color bg, Color fg, Border? border, List<BoxShadow>? shadow) = switch (m.type) {
      MessageBubbleType.incoming => (
        c.bubbleIncoming,
        c.textPrimary,
        c.isDark ? Border.all(color: c.divider) : null,
        c.isDark ? null : context.shadows.low,
      ),
      MessageBubbleType.outgoingAi => (c.bubbleAi, c.textPrimary, Border.all(color: c.bubbleAiBorder), null),
      _ => (c.bubbleOutgoing, c.bubbleOutgoingForeground, null, c.isDark ? null : context.shadows.low),
    };
    // Light controls (play button, ticks) only on a dark bubble.
    final onPrimary =
        (m.type == MessageBubbleType.outgoing || m.type == MessageBubbleType.outgoingColleague) &&
        bg.computeLuminance() < 0.4;

    // Bubble-less content: stickers and emoji-only text.
    final emojiOnly = m.kind == MessageKind.text && TextContent.isEmojiOnly(m.text);
    if (m.kind == MessageKind.sticker || emojiOnly) {
      return _Aligned(
        endSide: endSide,
        child: Column(
          crossAxisAlignment: endSide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            m.kind == MessageKind.sticker
                ? const _Sticker()
                : Text(m.text.trim(), style: context.text.chatMessageEmoji),
            if (lastInGroup) _StatusRow(message: m, foreground: c.textSecondary, onPrimary: false),
            if (m.reactions.isNotEmpty) ReactionsChip(reactions: m.reactions),
          ],
        ),
      );
    }

    final media = switch (m.kind) {
      MessageKind.image || MessageKind.album || MessageKind.video || MessageKind.location => true,
      _ => false,
    };
    final l = context.l10n;

    Widget content = switch (m.kind) {
      MessageKind.text || MessageKind.template => TextContent(text: m.text, color: fg, searchQuery: query),
      MessageKind.image => ImageContent(message: m, foreground: fg),
      MessageKind.album => AlbumContent(message: m, foreground: fg),
      MessageKind.video => VideoContent(message: m),
      MessageKind.voice => VoiceMessagePlayer(
        conversationId: conversationId,
        message: m,
        foreground: fg,
        onPrimary: onPrimary,
      ),
      MessageKind.file => FileContent(message: m, foreground: fg),
      MessageKind.location => LocationContent(message: m, foreground: fg),
      MessageKind.contact => ContactCardContent(message: m, foreground: fg),
      MessageKind.email => EmailContent(message: m, foreground: fg),
      MessageKind.deleted => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.block, size: AppIconSize.xs, color: c.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(l.chat_deleted, style: context.text.chatMessage.copyWith(color: c.textTertiary)),
          ),
        ],
      ),
      MessageKind.unsupported => Text(l.chat_unsupported, style: context.text.bodySmall.copyWith(color: fg)),
      MessageKind.sticker => const SizedBox.shrink(),
    };

    final label = switch (m.type) {
      MessageBubbleType.outgoingColleague when firstInGroup => Text(
        m.senderName ?? '',
        style: context.text.chatSenderLabel.copyWith(color: fg.withValues(alpha: 0.8)),
      ),
      MessageBubbleType.outgoingAi when firstInGroup => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.ai, size: AppIconSize.xs, color: c.primary),
          const SizedBox(width: 4),
          Text(l.chat_ai_reply_label, style: context.text.chatSenderLabel.copyWith(color: c.primary)),
        ],
      ),
      _ => null,
    };

    final bodyPadding = media
        ? EdgeInsets.zero
        : const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, top: AppSpacing.sm, bottom: 6);

    final bubble = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.bubble(outgoing: endSide, hasTail: lastInGroup),
        border: border,
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: bodyPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 2,
                      top: media ? 6 : 0,
                      left: media ? 10 : 0,
                      right: media ? 10 : 0,
                    ),
                    child: label,
                  ),
                if (m.kind == MessageKind.template && m.templateName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(AppIcons.templates, size: AppIconSize.xs, color: fg.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          l.bubble_template_label(m.templateName!),
                          style: context.text.chatSenderLabel.copyWith(color: fg.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                if (m.quote != null)
                  Padding(
                    padding: EdgeInsets.all(media ? 4 : 0),
                    child: ReplyQuote(
                      quote: m.quote!,
                      foreground: fg,
                      onPrimary: onPrimary,
                      onTap: m.quote!.messageId == null || onQuoteTap == null
                          ? null
                          : () => onQuoteTap!(m.quote!.messageId!),
                    ),
                  ),
                content,
                if (m.templateButtons.isNotEmpty) _TemplateButtons(buttons: m.templateButtons, foreground: fg),
              ],
            ),
          ),
          if (lastInGroup)
            Padding(
              padding: media
                  ? const EdgeInsetsDirectional.only(start: 10, end: 10, bottom: 6, top: 2)
                  : const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.md, bottom: 6),
              child: _StatusRow(message: m, foreground: fg, onPrimary: onPrimary),
            ),
        ],
      ),
    );

    final failed = m.delivery == DeliveryState.failed && outgoing;
    return _Aligned(
      endSide: endSide,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: media ? 248 : maxWidth),
        child: Column(
          crossAxisAlignment: endSide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: m.reactions.isEmpty ? 0 : 14),
                  child: Opacity(
                    opacity: failed ? 0.7 : 1,
                    child: _SearchOutline(
                      active: current,
                      radius: AppRadius.bubble(outgoing: endSide, hasTail: lastInGroup),
                      child: bubble,
                    ),
                  ),
                ),
                if (m.reactions.isNotEmpty)
                  PositionedDirectional(bottom: 0, start: 8, child: ReactionsChip(reactions: m.reactions)),
              ],
            ),
            if (failed)
              _FailedRow(
                onRetry: () => ref.read(messagesControllerProvider(conversationId).notifier).retry(m.id),
                onDiscard: () => ref.read(messagesControllerProvider(conversationId).notifier).discard(m.id),
              ),
          ],
        ),
      ),
    );
  }
}

/// 2dp `primary` outline on the current search match, fading in 150ms
/// (instant under reduce motion).
class _SearchOutline extends StatelessWidget {
  const _SearchOutline({required this.active, required this.radius, required this.child});

  final bool active;
  final BorderRadiusGeometry radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.fast,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: active ? c.primary : c.primary.withValues(alpha: 0), width: 2),
      ),
      child: child,
    );
  }
}

/// Logical end or start of the row (see endSide: own messages are always
/// on the physical right).
class _Aligned extends StatelessWidget {
  const _Aligned({required this.endSide, required this.child});

  final bool endSide;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: endSide ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart, child: child);
}

/// "معدّلة" + time + delivery icon, end-aligned, `chatTimestamp` at 65%.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.message, required this.foreground, required this.onPrimary});

  final Message message;
  final Color foreground;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final style = context.text.chatTimestamp.copyWith(color: foreground.withValues(alpha: 0.65));
    final m = message;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (m.edited) ...[Text(context.l10n.chat_edited, style: style), const SizedBox(width: 4)],
          Text(AppFormat.time(context, m.sentAt), style: style, textDirection: TextDirection.ltr),
          if (m.isOutgoing) ...[
            const SizedBox(width: 3),
            DeliveryStatus(state: m.delivery, foreground: foreground, onPrimary: onPrimary),
          ],
        ],
      ),
    );
  }
}

class _TemplateButtons extends StatelessWidget {
  const _TemplateButtons({required this.buttons, required this.foreground});

  final List<String> buttons;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final divider = Container(height: 1, color: foreground.withValues(alpha: 0.15));
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final b in buttons) ...[
            divider,
            ExcludeSemantics(
              excluding: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  b,
                  textAlign: TextAlign.center,
                  style: context.text.buttonSmall.copyWith(color: foreground),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FailedRow extends StatelessWidget {
  const _FailedRow({required this.onRetry, required this.onDiscard});

  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final style = context.text.caption.copyWith(color: c.textError);
    Widget link(String text, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              text,
              style: style.copyWith(fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
            ),
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(AppIcons.error, size: AppIconSize.xs, color: c.error),
        const SizedBox(width: 4),
        Text(l.chat_failed, style: style),
        Text(' · ', style: style),
        link(l.chat_retry, onRetry),
        Text(' · ', style: style),
        link(l.chat_delete, onDiscard),
      ],
    );
  }
}

/// Internal note (DS §8.4): full width, amber, dashed border, radius 14,
/// label note icon + "ملاحظة داخلية · {name}", @mentions bold `textWarning`.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.message, required this.lastInGroup, this.searchQuery = ''});

  final Message message;
  final bool lastInGroup;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return CustomPaint(
      painter: _DashedBorderPainter(color: c.noteBorder, radius: AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 8),
        decoration: BoxDecoration(color: c.noteBackground, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(AppIcons.note, size: AppIconSize.xs, color: c.noteForeground),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.l10n.chat_note_label(message.senderName ?? ''),
                    style: t.chatSenderLabel.copyWith(color: c.noteForeground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextContent(
              text: message.text,
              color: c.noteForeground,
              mentions: message.mentions,
              searchQuery: searchQuery,
            ),
            if (lastInGroup)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  AppFormat.time(context, message.sentAt),
                  style: t.chatTimestamp.copyWith(color: c.noteForeground.withValues(alpha: 0.65)),
                  textDirection: TextDirection.ltr,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}

/// 120×120 sticker without a bubble (sample data has no sticker images).
class _Sticker extends StatelessWidget {
  const _Sticker();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 120,
    child: FittedBox(child: Text('🐱', style: context.text.chatMessageEmoji.copyWith(fontSize: 96))),
  );
}
