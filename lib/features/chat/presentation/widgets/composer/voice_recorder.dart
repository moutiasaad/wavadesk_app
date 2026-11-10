import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Hold-to-record state machine (Chat spec §4.7.4): hold → record, slide
/// toward start > 100dp → cancel, slide up → lock, release → send (min 1s,
/// max 5 min). Recording is simulated — no audio is captured in this build.
class VoiceRecorderController extends ChangeNotifier {
  VoiceRecorderController({required this.onSend});

  /// Called with the final duration when a recording is sent.
  final void Function(Duration duration) onSend;

  static const cancelDistance = 100.0;
  static const lockDistance = 80.0;
  static const minDuration = Duration(seconds: 1);
  static const maxDuration = Duration(minutes: 5);

  bool recording = false;
  bool locked = false;
  Duration elapsed = Duration.zero;

  /// 0–1 toward the cancel threshold (drives the hint/trash animation).
  double cancelProgress = 0;

  /// Briefly true after a cancel, for the trash animation.
  bool cancelled = false;

  Timer? _timer;
  DateTime? _startedAt;

  void start() {
    if (recording) return;
    HapticFeedback.mediumImpact();
    recording = true;
    locked = false;
    cancelled = false;
    cancelProgress = 0;
    elapsed = Duration.zero;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      elapsed = DateTime.now().difference(_startedAt!);
      if (elapsed >= maxDuration) {
        send();
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
    if (up > lockDistance) {
      HapticFeedback.mediumImpact();
      locked = true;
      cancelProgress = 0;
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
    if (!recording || locked) return;
    send();
  }

  void cancel() {
    if (!recording) return;
    HapticFeedback.heavyImpact();
    _stop();
    cancelled = true;
    Analytics.log('chat_voice_record', {'duration_s': elapsed.inSeconds, 'cancelled': true});
    notifyListeners();
    Timer(AppMotion.slow, () {
      cancelled = false;
      notifyListeners();
    });
  }

  void send() {
    if (!recording) return;
    final d = DateTime.now().difference(_startedAt!);
    _stop();
    if (d < minDuration) {
      // Too short: treat as an accidental tap.
      Analytics.log('chat_voice_record', {'duration_s': d.inSeconds, 'cancelled': true});
      notifyListeners();
      return;
    }
    Analytics.log('chat_voice_record', {'duration_s': d.inSeconds, 'cancelled': false});
    onSend(d > maxDuration ? maxDuration : d);
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    recording = false;
    locked = false;
    cancelProgress = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// The 44dp mic circle that starts a recording on long press.
class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton({super.key, required this.controller, required this.color});

  final VoiceRecorderController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.composer_record,
      excludeSemantics: true,
      child: GestureDetector(
        onLongPressStart: (_) {
          controller.start();
          SemanticsService.announce(l.composer_recording, Directionality.of(context));
        },
        onLongPressMoveUpdate: (d) => controller.drag(
          // Start edge is the right in RTL, the left in LTR.
          towardStart: rtl ? d.offsetFromOrigin.dx : -d.offsetFromOrigin.dx,
          up: -d.offsetFromOrigin.dy,
        ),
        onLongPressEnd: (_) => controller.release(),
        onTap: () => AppSnackbar.show(context, message: l.composer_record),
        child: SizedBox.square(
          dimension: AppSpacing.minTouch,
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(AppIcons.mic, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Replaces the text field while recording: pulsing red dot + timer +
/// "← اسحب للإلغاء"; when locked shows إيقاف / send.
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
              Icon(AppIcons.delete, size: 20, color: c.error),
              const SizedBox(width: AppSpacing.sm),
              Text(l.composer_record_cancelled, style: t.bodyMedium.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      );
    }

    final secs = rc.elapsed.inSeconds;
    final timer = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    return Semantics(
      liveRegion: true,
      label: '${l.composer_recording} $timer',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsetsDirectional.only(start: 14, end: AppSpacing.xs),
        decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Row(
          children: [
            FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(timer, style: t.bodyMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: rc.locked
                  ? Text(l.composer_record_locked, style: t.caption.copyWith(color: c.textSecondary), maxLines: 1)
                  : Opacity(
                      opacity: 1 - rc.cancelProgress * 0.6,
                      child: Transform.translate(
                        offset: Offset((context.isRtl ? 1 : -1) * rc.cancelProgress * 24, 0),
                        child: Text(
                          '← ${l.chat_record_cancel_hint}',
                          style: t.caption.copyWith(color: c.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
            ),
            if (rc.locked) ...[
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: c.textError,
                  textStyle: t.buttonSmall,
                  minimumSize: const Size(48, 40),
                ),
                onPressed: rc.cancel,
                icon: const Icon(AppIcons.stop, size: 18),
                label: Text(l.composer_record_stop),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
