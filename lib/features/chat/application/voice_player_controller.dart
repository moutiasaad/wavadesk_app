import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class VoicePlayerState {
  const VoicePlayerState({
    this.messageId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.speed = 1.0,
    this.played = const {},
  });

  /// Message currently loaded in the single shared player.
  final String? messageId;
  final Duration position;
  final Duration duration;
  final bool playing;

  /// 1×, 1.5×, 2×.
  final double speed;

  /// Messages that were played at least once (speed chip shows after first play).
  final Set<String> played;

  bool isActive(String id) => messageId == id;
  double progressOf(String id) =>
      !isActive(id) || duration == Duration.zero ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
}

/// One voice message plays at a time (Chat spec §4.4 Voice). Playback is
/// simulated (no audio files in sample data); the clock honours the speed.
final voicePlayerProvider = NotifierProvider<VoicePlayerController, VoicePlayerState>(VoicePlayerController.new);

class VoicePlayerController extends Notifier<VoicePlayerState> {
  Timer? _ticker;
  static const _tick = Duration(milliseconds: 100);

  @override
  VoicePlayerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const VoicePlayerState();
  }

  void toggle(String messageId, Duration duration) {
    if (state.isActive(messageId) && state.playing) {
      pause();
    } else {
      play(messageId, duration);
    }
  }

  void play(String messageId, Duration duration) {
    final resume = state.isActive(messageId) && state.position < state.duration;
    state = VoicePlayerState(
      messageId: messageId,
      duration: duration,
      position: resume ? state.position : Duration.zero,
      playing: true,
      speed: state.speed,
      played: {...state.played, messageId},
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) {
      final next = state.position + _tick * state.speed;
      if (next >= state.duration) {
        _ticker?.cancel();
        state = VoicePlayerState(
          messageId: state.messageId,
          duration: state.duration,
          position: Duration.zero,
          speed: state.speed,
          played: state.played,
        );
      } else {
        state = VoicePlayerState(
          messageId: state.messageId,
          duration: state.duration,
          position: next,
          playing: true,
          speed: state.speed,
          played: state.played,
        );
      }
    });
  }

  void pause() {
    _ticker?.cancel();
    state = VoicePlayerState(
      messageId: state.messageId,
      duration: state.duration,
      position: state.position,
      speed: state.speed,
      played: state.played,
    );
  }

  /// Seek by tapping the waveform (0–1).
  void seek(String messageId, Duration duration, double fraction) {
    if (!state.isActive(messageId)) play(messageId, duration);
    state = VoicePlayerState(
      messageId: messageId,
      duration: duration,
      position: duration * fraction.clamp(0, 1),
      playing: state.playing,
      speed: state.speed,
      played: state.played,
    );
  }

  void cycleSpeed() {
    final next = switch (state.speed) {
      1.0 => 1.5,
      1.5 => 2.0,
      _ => 1.0,
    };
    state = VoicePlayerState(
      messageId: state.messageId,
      duration: state.duration,
      position: state.position,
      playing: state.playing,
      speed: next,
      played: state.played,
    );
  }
}
