import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/wa_channel.dart';
import '../sheets/wa_disconnect_dialog.dart';

/// Red outline **فصل الرقم**, h48 full width (WhatsApp spec §4.8).
/// Owner/admin only — the screen hides it otherwise.
class WaDisconnectButton extends StatelessWidget {
  const WaDisconnectButton({super.key, required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppButton(
          label: context.l10n.wa_disconnect,
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.large,
          height: 48,
          expand: true,
          onPressed: () => showWaDisconnectDialog(context, channel),
        ),
      );
}
