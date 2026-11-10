import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';

/// Body of a WhatsApp sub-screen before the channel has loaded: a spinner,
/// or the load error with retry (never an endless spinner).
class WaLoadingBody extends ConsumerWidget {
  const WaLoadingBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(whatsAppChannelControllerProvider);
    if (s.error != null && !s.loading) {
      final l = context.l10n;
      return EmptyState(
        icon: s.offline ? AppIcons.offline : AppIcons.error,
        title: l.wa_load_error,
        actionLabel: l.wa_retry,
        onAction: ref.read(whatsAppChannelControllerProvider.notifier).load,
      );
    }
    return const Center(child: AppSpinner());
  }
}
