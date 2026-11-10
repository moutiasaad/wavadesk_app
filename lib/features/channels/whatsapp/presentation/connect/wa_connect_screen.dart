import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/wa_connect_controller.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';
import '../../domain/wa_status.dart';
import '../wa_links.dart';
import 'wa_connect_success_view.dart';
import 'wa_pairing_code_view.dart';
import 'wa_phone_pairing_view.dart';
import 'wa_qr_view.dart';

/// `/settings/whatsapp/connect` (WhatsApp spec §5.1). Phone pairing is the
/// default on mobile (a QR can't be scanned by the same phone).
class WaConnectScreen extends ConsumerStatefulWidget {
  const WaConnectScreen({super.key, this.source = 'channel'});

  final String source;

  @override
  ConsumerState<WaConnectScreen> createState() => _WaConnectScreenState();
}

class _WaConnectScreenState extends ConsumerState<WaConnectScreen> {
  late final bool _wasDown;

  @override
  void initState() {
    super.initState();
    final st = ref.read(whatsAppChannelControllerProvider).channel?.status;
    _wasDown = st != null && st != WaStatus.pending && !st.isHealthy;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(waConnectControllerProvider.notifier).start(source: widget.source);
    });
  }

  void _done() {
    final s = ref.read(waConnectControllerProvider);
    // Reconnect success: "عاد الاتصال · لم تُفقد أي رسالة" when the server
    // confirmed the backlog synced (app-level messenger: survives the pop).
    if (_wasDown && s.backlogSynced) {
      AppSnackbar.show(context, message: context.l10n.wa_back_online, kind: SnackKind.success);
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(waConnectControllerProvider);
    final ctrl = ref.read(waConnectControllerProvider.notifier);
    final phone = ref.watch(whatsAppChannelControllerProvider.select((x) => x.channel?.phone));
    final success = s.step == WaConnectStep.success;
    final stepIndex = s.step == WaConnectStep.code ? 2 : 1;
    final reduced = AppMotion.reduced(context);

    final Widget body = switch (s.step) {
      WaConnectStep.enterPhone => WaPhonePairingView(initialPhone: phone),
      WaConnectStep.code => const WaPairingCodeView(),
      WaConnectStep.qr => const WaQrView(),
      WaConnectStep.success => WaConnectSuccessView(onDone: _done),
    };

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.wa_connect_title,
        background: c.backgroundMuted,
        actions: [
          if (!success && s.method == WaConnectMethod.phone)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text(l.wa_step('$stepIndex', '2'), style: t.caption.copyWith(color: c.textSecondary)),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (!success) ...[
              AppSegmented<WaConnectMethod>(
                height: 44,
                segments: [
                  AppSegment(value: WaConnectMethod.phone, label: l.wa_by_phone),
                  AppSegment(value: WaConnectMethod.qr, label: l.wa_by_qr),
                ],
                selected: s.method,
                onChanged: ctrl.selectMethod,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            AnimatedSwitcher(
              duration: reduced ? Duration.zero : AppMotion.normal,
              child: KeyedSubtree(key: ValueKey(s.step), child: body),
            ),
            if (!success) ...[
              const SizedBox(height: AppSpacing.xxl),
              Material(
                color: c.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  side: BorderSide(color: c.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: WaLinks.video,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: c.errorContainer, borderRadius: BorderRadius.circular(10)),
                          child: Icon(AppIcons.play, size: 18, color: c.textError),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(l.wa_watch_video, style: t.listTitle.copyWith(fontSize: 14))),
                        Text(WaLinks.howToVideoLength, style: t.caption.copyWith(color: c.textTertiary)),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(AppIcons.chevronEnd, size: 16, color: c.borderStrong),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
