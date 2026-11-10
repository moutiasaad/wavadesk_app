import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../data/whatsapp_api.dart';
import '../../domain/wa_channel.dart';

/// Disconnect (WhatsApp spec §6.2): typed last-4 check; on success the
/// snackbar offers **إعادة الربط** (no undo).
Future<void> showWaDisconnectDialog(BuildContext context, WaChannel channel) async {
  final done = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (_) => _DisconnectDialog(channel: channel),
  );
  if (done != true || !context.mounted) return;
  HapticFeedback.mediumImpact();
  AppSnackbar.show(
    context,
    message: context.l10n.wa_disc_done,
    actionLabel: context.l10n.wa_reconnect,
    onAction: () => context.push(Routes.whatsappConnect(source: 'disconnect')),
  );
}

class _DisconnectDialog extends ConsumerStatefulWidget {
  const _DisconnectDialog({required this.channel});

  final WaChannel channel;

  @override
  ConsumerState<_DisconnectDialog> createState() => _DisconnectDialogState();
}

class _DisconnectDialogState extends ConsumerState<_DisconnectDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _matches => _ctrl.text == widget.channel.last4 && widget.channel.last4.length == 4;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    Analytics.log('wa_disconnect', {'open_conversations': widget.channel.openConversations});
    try {
      await ref.read(whatsAppChannelControllerProvider.notifier).disconnect(_ctrl.text);
      if (mounted) Navigator.of(context).pop(true);
    } on WaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'confirmation_mismatch' ? l.wa_disc_mismatch : (e.isNetwork ? l.wa_offline : l.wa_disc_failed);
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Dialog(
      backgroundColor: c.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.errorContainer, shape: BoxShape.circle),
                child: AppIcon(AppIcons.error, size: AppIconSize.lg, color: c.textError),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.wa_disc_title, style: t.h4.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(l.wa_disc_body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
            if (widget.channel.openConversations > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: c.textError, shape: BoxShape.circle)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(l.wa_disc_open('${widget.channel.openConversations}'), style: t.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l.wa_disc_confirm_label,
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLength: 4,
              autofocus: true,
              enabled: !_busy,
              error: _error,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _matches && !_busy ? _confirm() : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.wa_disconnect,
              variant: AppButtonVariant.destructiveFilled,
              expand: true,
              loading: _busy,
              onPressed: _matches && !_busy ? _confirm : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l.wa_cancel,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
