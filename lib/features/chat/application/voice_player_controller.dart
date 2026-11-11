import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/chat_api.dart';

@immutable
class VoicePlayerState {
  const VoicePlayerState({
    this.messageId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.speed = 1.0,
    this.played = const {},
    this.failed = const {},
  });

  /// Message currently loaded in the single shared player.
  final String? messageId;
  final Duration position;
  final Duration duration;
  final bool playing;

  /// Fetching the signed URL / buffering.
  final bool loading;

  /// 1×, 1.5×, 2×.
  final double speed;

  /// Messages that were played at least once (speed chip shows after first play).
  final Set<String> played;

  /// Messages whose audio could not be loaded.
  final Set<String> failed;

  bool isActive(String id) => messageId == id;
  double progressOf(String id) =>
      !isActive(id) || duration == Duration.zero ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);

  VoicePlayerState copyWith({
    String? messageId,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    double? speed,
    Set<String>? played,
    Set<String>? failed,
  }) =>
      VoicePlayerState(
        messageId: messageId ?? this.messageId,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        playing: playing ?? this.playing,
        loading: loading ?? this.loading,
        speed: speed ?? this.speed,
        played: played ?? this.played,
        failed: failed ?? this.failed,
      );
}

/// One voice message plays at a time (Chat spec §4.4 Voice). Audio is
/// streamed from the 5-minute signed link of `GET media/{msg_…}/url`.
final voicePlayerProvider = NotifierProvider<VoicePlayerController, VoicePlayerState>(VoicePlayerController.new);

class VoicePlayerController extends Notifier<VoicePlayerState> {
  AudioPlayer? _player;
  final List<StreamSubscription<Object?>> _subs = [];

  /// Message whose source is loaded in [_player].
  String? _loadedId;

  @override
  VoicePlayerState build() {
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _player?.dispose();
    });
    return const VoicePlayerState();
  }

  AudioPlayer get _p => _player ??= _create();

  AudioPlayer _create() {
    final p = AudioPlayer();
    _subs
      ..add(p.positionStream.listen((pos) {
        if (_loadedId != null && state.isActive(_loadedId!)) state = state.copyWith(position: pos);
      }))
      ..add(p.playerStateStream.listen((s) {
        if (_loadedId == null || !state.isActive(_loadedId!)) return;
        if (s.processingState == ProcessingState.completed) {
          // Back to the start, ready to play again.
          unawaited(p.pause().then((_) => p.seek(Duration.zero)));
          state = state.copyWith(playing: false, position: Duration.zero, loading: false);
          return;
        }
        state = state.copyWith(
          playing: s.playing,
          loading: s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering,
        );
      }));
    return p;
  }

  /// Only messages the server knows (`msg_…`) have audio to fetch; a voice
  /// note still uploading has none yet.
  static bool canPlay(String messageId) => messageId.startsWith('msg_');

  void toggle(String messageId, Duration duration) {
    if (state.isActive(messageId) && state.playing) {
      pause();
    } else {
      unawaited(play(messageId, duration));
    }
  }

  Future<void> play(String messageId, Duration duration) async {
    if (!canPlay(messageId)) return;
    if (_loadedId == messageId) {
      state = state.copyWith(played: {...state.played, messageId});
      unawaited(_p.play());
      return;
    }
    _loadedId = null;
    state = VoicePlayerState(
      messageId: messageId,
      duration: duration,
      loading: true,
      speed: state.speed,
      played: {...state.played, messageId},
      failed: {...state.failed}..remove(messageId),
    );
    try {
      await _p.stop();
      final url = await ref.read(chatApiProvider).mediaUrl(messageId);
      if (!state.isActive(messageId)) return; // another message was tapped meanwhile
      final real = await _p.setUrl(url);
      await _p.setSpeed(state.speed);
      _loadedId = messageId;
      state = state.copyWith(duration: real ?? duration, loading: false);
      unawaited(_p.play());
    } catch (_) {
      if (state.isActive(messageId)) {
        state = state.copyWith(loading: false, playing: false, failed: {...state.failed, messageId});
      }
    }
  }

  void pause() {
    unawaited(_player?.pause());
    state = state.copyWith(playing: false);
  }

  /// Seek by tapping the waveform (0–1).
  Future<void> seek(String messageId, Duration duration, double fraction) async {
    if (!state.isActive(messageId) || _loadedId != messageId) {
      await play(messageId, duration);
    }
    if (_loadedId != messageId) return;
    final to = state.duration * fraction.clamp(0, 1);
    state = state.copyWith(position: to);
    await _p.seek(to);
  }

  void cycleSpeed() {
    final next = switch (state.speed) {
      1.0 => 1.5,
      1.5 => 2.0,
      _ => 1.0,
    };
    unawaited(_player?.setSpeed(next));
    state = state.copyWith(speed: next);
  }
}
