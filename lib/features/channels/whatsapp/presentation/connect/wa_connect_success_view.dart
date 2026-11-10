import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_status.dart';

/// Success (WhatsApp spec §5.1): check draw 400 ms + scale (static with
/// reduce motion), number, "syncing recent chats" progress, **العودة**.
class WaConnectSuccessView extends ConsumerStatefulWidget {
  const WaConnectSuccessView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<WaConnectSuccessView> createState() => _WaConnectSuccessViewState();
}

class _WaConnectSuccessViewState extends ConsumerState<WaConnectSuccessView> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _anim.value = 1;
      } else {
        _anim.forward();
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ch = ref.watch(whatsAppChannelControllerProvider).channel;
    final phone = formatWaPhone(ch?.phone);

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => Transform.scale(
                scale: 0.8 + 0.2 * Curves.easeOutBack.transform(_anim.value),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: c.successContainer, shape: BoxShape.circle),
                  child: CustomPaint(painter: _CheckPainter(progress: _anim.value, color: c.textSuccess)),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.wa_linked_ok, style: t.h3, textAlign: TextAlign.center),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(phone, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: t.bodyMedium.copyWith(color: c.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(l.wa_syncing_recent, style: t.bodySmall.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(minHeight: 4, color: c.primary, backgroundColor: c.surfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: l.wa_back, size: AppButtonSize.large, expand: true, onPressed: widget.onDone),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.71, size.height * 0.38);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in p.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}
