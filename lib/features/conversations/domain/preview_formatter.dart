import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import 'conversation_summary.dart';

/// Which preview rule matched (Inbox spec §4.5.2, first match wins).
enum PreviewKind {
  typing,
  draft,
  note,
  mine,
  colleague,
  ai,
  image,
  voice,
  file,
  location,
  sticker,
  deleted,
  text,
  empty,
}

@immutable
class PreviewData {
  const PreviewData(this.kind, {this.text = '', this.delivery, this.senderFirstName, this.duration});

  final PreviewKind kind;

  /// Body text (draft text, message text, caption or file name).
  final String text;

  /// Delivery state for own messages (ticks).
  final DeliveryState? delivery;

  /// Colleague prefix "{firstName}:".
  final String? senderFirstName;

  /// Voice message length.
  final Duration? duration;
}

abstract final class PreviewFormatter {
  static String _flatten(String? s) => (s ?? '').replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();

  static PreviewData format(ConversationSummary c, {required String meId, String? draft}) {
    if (c.isTyping) return const PreviewData(PreviewKind.typing);
    if (draft != null && draft.trim().isNotEmpty) return PreviewData(PreviewKind.draft, text: _flatten(draft));

    final m = c.lastMessage;
    if (m == null) return const PreviewData(PreviewKind.empty);
    final text = _flatten(m.text);

    if (m.type == LastMessageType.deleted) return const PreviewData(PreviewKind.deleted);
    if (m.senderType == SenderType.note) return PreviewData(PreviewKind.note, text: text);

    // Media rules (the sender prefixes below apply to text messages).
    PreviewData? media() => switch (m.type) {
      LastMessageType.image => PreviewData(PreviewKind.image, text: text),
      LastMessageType.voice => PreviewData(PreviewKind.voice, duration: Duration(seconds: m.durationSec ?? 0)),
      LastMessageType.file => PreviewData(PreviewKind.file, text: m.fileName ?? text),
      LastMessageType.location => const PreviewData(PreviewKind.location),
      LastMessageType.sticker => const PreviewData(PreviewKind.sticker),
      LastMessageType.text || LastMessageType.deleted => null,
    };

    if (m.direction == MessageDirection.outgoing && m.senderType == SenderType.agent) {
      final mine = m.senderId == meId || (m.senderId == null && m.senderName == null);
      if (mine) return PreviewData(PreviewKind.mine, text: media()?.text ?? text, delivery: m.delivery);
      final first = (m.senderName ?? '').trim().split(RegExp(r'\s+')).first;
      return PreviewData(PreviewKind.colleague, text: text, senderFirstName: first);
    }
    if (m.senderType == SenderType.ai) return PreviewData(PreviewKind.ai, text: text);
    return media() ?? PreviewData(PreviewKind.text, text: text);
  }
}
