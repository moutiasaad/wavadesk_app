import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/messages_controller.dart';
import '../../../application/voice_player_controller.dart';

/// Voice message (Chat spec §4.4): 32 play circle (`primary`; white circle
/// with primary icon on outgoing) · 36-bar waveform (2dp bars, 2dp gaps,
/// played part primary / white) · duration · speed chip after first play ·
/// one plays at a time · "تحويل لنص" under incoming voice.
class VoiceMessagePlayer extends ConsumerStatefulWidget {
  const VoiceMessagePlayer({
    super.key,
    required this.conversationId,
    required this.message,
    required this.foreground,
    required this.onPrimary,
  });

  final String conversationId;
  final Message message;
  final Color foreground;
  final bool onPrimary;

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  static const _bars = 36;
  bool _transcribing = false;

  /// Deterministic bar heights from the message id (no audio decoding).
  List<double> get _heights {
    var h = 0;
    for (final u in widget.message.id.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return [
      for (var i = 0; i < _bars; i++)
        () {
          h = (h * 1103515245 + 12345) & 0x7fffffff;
          return 4 + (h % 17).toDouble(); // 4–20dp
        }(),
    ];
  }

  Future<void> _transcribe() async {
    setState(() => _transcribing = true);
    await ref.read(messagesControllerProvider(widget.conversationId).notifier).transcribe(widget.message.id);
    if (mounted) setState(() => _transcribing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final m = widget.message;
    final duration = m.mediaDuration ?? const Duration(seconds: 1);
    final player = ref.watch(voicePlayerProvider);
    final ctrl = ref.read(voicePlayerProvider.notifier);
    final active = player.isActive(m.id);
    final playing = active && player.playing;
    final progress = player.progressOf(m.id);
    final played = widget.onPrimary ? Colors.white : c.primary;
    final unplayed = widget.onPrimary ? Colors.white.withValues(alpha: 0.4) : c.borderStrong;
    final shown = active && player.position > Duration.zero ? player.position : duration;
    final heights = _heights;

    final playButton = Semantics(
      button: true,
      label: playing ? l.bubble_pause : l.bubble_play,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => ctrl.toggle(m.id, duration),
        radius: 24,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: widget.onPrimary ? Colors.white : c.primary, shape: BoxShape.circle),
              child: Icon(
                playing ? AppIcons.pause : AppIcons.play,
                size: 16,
                color: widget.onPrimary ? c.primary : c.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );

    final waveform = LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final w = _bars * 4.0 - 2;
          var x = d.localPosition.dx / w;
          if (Directionality.of(context) == TextDirection.rtl) x = 1 - x;
          ctrl.seek(m.id, duration, x);
        },
        child: SizedBox(
          height: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _bars; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Container(
                  width: 2,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: (i + 0.5) / _bars <= progress ? played : unplayed,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [playButton, const SizedBox(width: 6), waveform]),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 46, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppFormat.clock(shown),
                style: t.chatTimestamp.copyWith(color: widget.foreground.withValues(alpha: 0.65)),
                textDirection: TextDirection.ltr,
              ),
              if (player.played.contains(m.id)) ...[
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: l.bubble_speed(_speed(player.speed)),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: ctrl.cycleSpeed,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: widget.foreground.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _speed(player.speed),
                        style: t.chatTimestamp.copyWith(color: widget.foreground),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (m.type == MessageBubbleType.incoming) ...[
          if (m.transcript != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(m.transcript!, style: t.bodySmall.copyWith(color: widget.foreground)),
              ),
            )
          else if (_transcribing)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSpinner(size: 14, delayed: false, color: c.primary),
                  const SizedBox(width: 6),
                  Text(l.bubble_transcribing, style: t.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            )
          else
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                textStyle: t.buttonSmall,
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: _transcribe,
              child: Text(l.chat_transcribe),
            ),
        ],
      ],
    );
  }

  static String _speed(double s) => s == 1 ? '1×' : (s == 2 ? '2×' : '1.5×');
}
