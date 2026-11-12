import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Hold-to-record state machine (Chat spec §4.7.4): hold → record, slide
/// toward start > 100dp → cancel, slide up → lock, release → send (min 1s,
/// max 5 min). Records mono AAC (.m4a) to a temp file; the server turns it
/// into an MP3 voice note for the channel.
class VoiceRecorderController extends ChangeNotifier {
  VoiceRecorderController({required this.onSend, this.onPermissionDenied, this.onError});

  /// Called with the final duration and the recorded file when sent.
  final void Function(Duration duration, String path) onSend;

  /// The microphone permission was refused.
  final VoidCallback? onPermissionDenied;

  /// The recorder could not start (no microphone, busy…).
  final VoidCallback? onError;

  /// Mime of the recorded file (accepted by `POST /uploads` as audio).
  static const mime = 'audio/mp4';

  static const cancelDistance = 100.0;
  static const lockDistance = 80.0;
  static const minDuration = Duration(seconds: 1);
  static const maxDuration = Duration(minutes: 5);

  bool recording = false;
  bool locked = false;
  Duration elapsed = Duration.zero;

  /// 0–1 toward the cancel threshold (drives the hint/trash animation).
  double cancelProgress = 0;

  /// 0–1 toward the lock threshold (moves the lock pill).
  double lockProgress = 0;

  /// Recent input levels 0–1, oldest first (live meter while recording).
  final List<double> levels = [];
  static const maxLevels = 48;
  StreamSubscription<Amplitude>? _ampSub;

  /// Briefly true after a cancel, for the trash animation.
  bool cancelled = false;

  Timer? _timer;
  DateTime? _startedAt;
  final AudioRecorder _rec = AudioRecorder();
  String? _path;
  bool _starting = false;

  /// Finger still down (a release during the async start must not leave
  /// the recorder running).
  bool _held = false;

  Future<void> start() async {
    if (recording || _starting) return;
    _held = true;
    _starting = true;
    try {
      if (!await _rec.hasPermission(request: false)) {
        // First time: the system dialog takes the gesture; hold again after.
        if (!await _rec.hasPermission()) onPermissionDenied?.call();
        return;
      }
      final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _rec.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, numChannels: 1, bitRate: 64000),
        path: path,
      );
      _path = path;
      _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((a) {
        // dBFS (-50…0) → 0.06–1.
        levels.add(((a.current + 50) / 50).clamp(0.06, 1.0).toDouble());
        if (levels.length > maxLevels) levels.removeAt(0);
      });
    } catch (_) {
      onError?.call();
      return;
    } finally {
      _starting = false;
    }
    if (!_held) {
      // Released while the recorder was starting: treat as a tap.
      await _discard();
      return;
    }
    HapticFeedback.mediumImpact();
    recording = true;
    locked = false;
    cancelled = false;
    cancelProgress = 0;
    elapsed = Duration.zero;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      elapsed = DateTime.now().difference(_startedAt!);
      if (elapsed >= maxDuration) {
        unawaited(send());
        return;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// [towardStart] is the drag distance toward the start edge (positive),
  /// [up] the upward distance (positive).
  void drag({required double towardStart, required double up}) {
    if (!recording || locked) return;
    lockProgress = (up / lockDistance).clamp(0, 1);
    if (up > lockDistance) {
      HapticFeedback.mediumImpact();
      locked = true;
      cancelProgress = 0;
      lockProgress = 0;
      notifyListeners();
      return;
    }
    cancelProgress = (towardStart / cancelDistance).clamp(0, 1);
    if (towardStart > cancelDistance) {
      cancel();
      return;
    }
    notifyListeners();
  }

  /// Finger lifted: send unless locked (hands-free continues).
  void release() {
    _held = false;
    if (!recording || locked) return;
    send();
  }

  void cancel() {
    if (!recording) return;
    HapticFeedback.heavyImpact();
    _stop();
    unawaited(_discard());
    cancelled = true;
    Analytics.log('chat_voice_record', {'duration_s': elapsed.inSeconds, 'cancelled': true});
    notifyListeners();
    Timer(AppMotion.slow, () {
      cancelled = false;
      notifyListeners();
    });
  }

  Future<void> send() async {
    if (!recording) return;
    final d = DateTime.now().difference(_startedAt!);
    _stop();
    notifyListeners();
    if (d < minDuration) {
      // Too short: treat as an accidental tap.
      Analytics.log('chat_voice_record', {'duration_s': d.inSeconds, 'cancelled': true});
      await _discard();
      return;
    }
    String? path;
    try {
      path = await _rec.stop() ?? _path;
    } catch (_) {
      path = null;
    }
    _path = null;
    if (path == null || !File(path).existsSync() || File(path).lengthSync() == 0) {
      onError?.call();
      return;
    }
    Analytics.log('chat_voice_record', {'duration_s': d.inSeconds, 'cancelled': false});
    onSend(d > maxDuration ? maxDuration : d, path);
  }

  /// Stops the recorder and deletes the file.
  Future<void> _discard() async {
    final path = _path;
    _path = null;
    try {
      await _rec.stop();
    } catch (_) {}
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  }

  void _stop() {
    _timer?.cancel();
    _ampSub?.cancel();
    _ampSub = null;
    levels.clear();
    recording = false;
    locked = false;
    cancelProgress = 0;
    lockProgress = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_discard().whenComplete(_rec.dispose));
    super.dispose();
  }
}

/// The 44dp mic circle that starts a recording on long press. While
/// recording it grows and a lock pill floats above it (slide up to lock).
class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton({super.key, required this.controller, required this.color});

  final VoiceRecorderController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final l = context.l10n;
    final c = context.colors;
    return Semantics(
      button: true,
      label: l.composer_record,
      excludeSemantics: true,
      child: GestureDetector(
        onLongPressStart: (_) {
          unawaited(controller.start());
          SemanticsService.announce(l.composer_recording, Directionality.of(context));
        },
        onLongPressMoveUpdate: (d) => controller.drag(
          // Start edge is the right in RTL, the left in LTR.
          towardStart: rtl ? d.offsetFromOrigin.dx : -d.offsetFromOrigin.dx,
          up: -d.offsetFromOrigin.dy,
        ),
        onLongPressEnd: (_) => controller.release(),
        onLongPressCancel: controller.release,
        onTap: () => AppSnackbar.show(context, message: l.composer_record),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final active = controller.recording && !controller.locked;
            return SizedBox.square(
              dimension: AppSpacing.minTouch,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (active)
                    Positioned(
                      bottom: 60 + 16 * controller.lockProgress,
                      child: _LockPill(progress: controller.lockProgress),
                    ),
                  AnimatedScale(
                    scale: active ? 1.35 : 1,
                    duration: AppMotion.fast,
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: active ? c.error : color,
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? [BoxShadow(color: c.error.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 2)]
                            : null,
                      ),
                      child: const AppIcon(AppIcons.mic, dp: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lock hint above the mic: padlock + chevron, fills as the finger slides up.
class _LockPill extends StatelessWidget {
  const _LockPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      child: Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.lock, dp: 16, color: Color.lerp(c.textSecondary, c.primary, progress)),
            const SizedBox(height: AppSpacing.xs),
            AppIcon(AppIcons.chevronUp, dp: 16, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Live input meter: one bar per level sample, newest at the end.
class _LiveLevels extends StatelessWidget {
  const _LiveLevels({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final count = (box.maxWidth / 4).floor().clamp(0, VoiceRecorderController.maxLevels);
        final shown = levels.length > count ? levels.sublist(levels.length - count) : levels;
        return SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final v in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: 2,
                    height: 3 + 21 * v,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Replaces the text field while recording. Holding: pulsing red dot +
/// timer + "‹ slide to cancel" + live meter. Locked (hands-free): delete +
/// dot + timer + live meter; the composer shows a send button.
class RecordingField extends StatefulWidget {
  const RecordingField({super.key, required this.controller});

  final VoiceRecorderController controller;

  @override
  State<RecordingField> createState() => _RecordingFieldState();
}

class _RecordingFieldState extends State<RecordingField> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: AppMotion.loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppMotion.reduced(context) ? _pulse.stop() : _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final rc = widget.controller;

    if (rc.cancelled) {
      // Trash animation after a cancel.
      return Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: AppMotion.slow,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child),
          ),
          child: Row(
            children: [
              AppIcon(AppIcons.delete, color: c.error),
              const SizedBox(width: AppSpacing.sm),
              Text(l.composer_record_cancelled, style: t.bodyMedium.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      );
    }

    final secs = rc.elapsed.inSeconds;
    final timer = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final dot = FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_pulse),
      child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.error, shape: BoxShape.circle)),
    );
    final clock = Text(
      timer,
      style: t.bodyMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()], color: c.textPrimary),
      textDirection: TextDirection.ltr,
    );

    return Semantics(
      liveRegion: true,
      label: '${l.composer_recording} $timer',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsetsDirectional.only(start: rc.locked ? AppSpacing.xxs : 14, end: 14),
        decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Row(
          children: [
            if (rc.locked)
              Semantics(
                button: true,
                label: l.composer_record_delete,
                excludeSemantics: true,
                child: IconButton(
                  onPressed: rc.cancel,
                  icon: AppIcon(AppIcons.delete, color: c.textError),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            dot,
            const SizedBox(width: AppSpacing.sm),
            clock,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: rc.locked
                  ? _LiveLevels(levels: rc.levels, color: c.primary)
                  : Opacity(
                      opacity: 1 - rc.cancelProgress * 0.6,
                      child: Transform.translate(
                        offset: Offset((context.isRtl ? 1 : -1) * rc.cancelProgress * 24, 0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '‹ ${l.chat_record_cancel_hint}',
                                style: t.caption.copyWith(color: c.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: _LiveLevels(levels: rc.levels, color: c.textTertiary)),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
