import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/wa_connect_controller.dart';
import 'wa_phone_pairing_view.dart' show waConnectErrorText;

/// QR method (WhatsApp spec §5.1): 240×240 on a card that stays white in
/// dark mode, auto-refresh every 20 s with a ring countdown.
class WaQrView extends ConsumerWidget {
  const WaQrView({super.key});

  static const _refreshEvery = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(waConnectControllerProvider);
    final payload = s.session?.qrPayload;
    final reduced = AppMotion.reduced(context);
    final secs = s.remaining.inSeconds.clamp(0, 999);
    final steps = l.wa_qr_steps.split(RegExp(r'\s*[←→]\s*'));

    Widget qr;
    if (payload == null || payload.isEmpty) {
      qr = const SizedBox(width: 240, height: 240, child: Center(child: AppSpinner(color: Colors.black54, delayed: false)));
    } else if (s.session!.qrIsImage) {
      final comma = payload.indexOf(',');
      final bytes = base64Decode(comma < 0 ? payload : payload.substring(comma + 1));
      qr = Image.memory(bytes, width: 240, height: 240, gaplessPlayback: true, filterQuality: FilterQuality.none);
    } else {
      qr = QrImageView(
        data: payload,
        size: 240,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            image: true,
            label: l.wa_qr_alt,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: c.border),
              ),
              child: AnimatedSwitcher(
                duration: reduced ? Duration.zero : AppMotion.fast,
                child: KeyedSubtree(key: ValueKey(s.qrVersion), child: qr),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (s.errorCode != null)
          Column(
            children: [
              Text(waConnectErrorText(l, s.errorCode!), style: t.bodySmall.copyWith(color: c.textError), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l.wa_retry,
                icon: AppIcons.regenerate,
                size: AppButtonSize.small,
                onPressed: ref.read(waConnectControllerProvider.notifier).requestQr,
              ),
            ],
          )
        else if (payload != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: reduced ? null : (secs / _refreshEvery).clamp(0.0, 1.0),
                  strokeWidth: 2.4,
                  color: c.primary,
                  backgroundColor: c.surfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l.wa_qr_refresh_in('$secs'), style: t.bodySmall.copyWith(color: c.textSecondary)),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: c.border)),
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: t.caption.copyWith(color: c.onPrimaryContainer, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(steps[i], style: t.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
