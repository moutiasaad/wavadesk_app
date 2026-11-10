import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/wa_connect_controller.dart';
import '../wa_links.dart';
import 'wa_phone_pairing_view.dart' show waConnectErrorText;

/// Step 2 of phone pairing: the 8-char code in mono boxes (4-4), copy,
/// countdown, numbered instructions, **فتح واتساب**; listens for the link
/// (WhatsApp spec §5.1).
class WaPairingCodeView extends ConsumerWidget {
  const WaPairingCodeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(waConnectControllerProvider);
    final ctrl = ref.read(waConnectControllerProvider.notifier);
    final raw = (s.session?.code ?? '').replaceAll('-', '').toUpperCase();
    final chars = raw.split('');
    final reduced = AppMotion.reduced(context);
    final expired = s.expired;
    final steps = l.wa_steps_pair.split(RegExp(r'\s*[←→]\s*'));

    Widget box(int i) {
      final ch = i < chars.length ? chars[i] : '';
      final tile = Container(
        width: 34,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: expired ? c.border : c.primaryContainerBorder, width: 1.5),
        ),
        child: Text(
          ch,
          style: t.h2.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 4,
            color: expired ? c.textDisabled : c.textPrimary,
            height: 1,
          ),
        ),
      );
      if (reduced) return tile;
      return TweenAnimationBuilder<double>(
        key: ValueKey('${s.session?.sessionId}-$i'),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 150 + i * 30),
        builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 6), child: child)),
        child: tile,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: chars.join(' '),
          excludeSemantics: true,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: box(i)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–', style: t.h3.copyWith(color: c.textTertiary)),
                  ),
                  for (var i = 4; i < 8; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: box(i)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!expired)
              AppButton(
                label: l.wa_copy,
                icon: AppIcons.copy,
                size: AppButtonSize.small,
                variant: AppButtonVariant.tonal,
                semanticLabel: '${l.wa_copy} ${chars.join(' ')}',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: s.session?.code ?? raw));
                  HapticFeedback.selectionClick();
                  AppSnackbar.show(context, message: l.wa_copied);
                },
              ),
            const SizedBox(width: AppSpacing.md),
            Text(
              expired ? l.wa_code_expired : l.wa_expires_in(AppFormat.clock(s.remaining)),
              style: t.bodySmall.copyWith(color: expired ? c.textError : c.textSecondary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (expired || (s.errorCode != null && s.errorCode != 'code_expired')) ...[
          const SizedBox(height: AppSpacing.md),
          if (s.errorCode != null && s.errorCode != 'code_expired')
            Text(waConnectErrorText(l, s.errorCode!), style: t.bodySmall.copyWith(color: c.textError), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: AppButton(
              label: l.wa_new_code,
              icon: AppIcons.regenerate,
              onPressed: ctrl.editPhone,
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: c.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.wa_open_app,
            icon: AppIcons.whatsapp,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: WaLinks.openWhatsApp,
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppSpinner(size: 14, delayed: false),
                const SizedBox(width: AppSpacing.sm),
                Text(l.wa_waiting_link, style: t.bodySmall.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Center(child: AppButton(label: l.wa_change_number, variant: AppButtonVariant.text, size: AppButtonSize.small, onPressed: ctrl.editPhone)),
      ],
    );
  }
}
