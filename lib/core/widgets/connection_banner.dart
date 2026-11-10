import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'app_spinner.dart';

/// §8.15 connection banner: 32dp bar under the app bar. "جارٍ الاتصال…" on
/// the warning container, "غير متصل" on the error container.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.state, this.offlineLabel});

  final NetworkState state;

  /// Overrides the default "غير متصل" text.
  final String? offlineLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      child: state == NetworkState.online
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 32),
                color: state == NetworkState.offline ? c.errorContainer : c.warningContainer,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state == NetworkState.connecting)
                      AppSpinner(size: 14, color: c.textWarning, delayed: false)
                    else
                      AppIcon(AppIcons.offline, size: AppIconSize.sm, color: c.textError),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      state == NetworkState.offline ? (offlineLabel ?? l.network_offline) : l.network_connecting,
                      style: context.text.caption.copyWith(
                        color: state == NetworkState.offline ? c.textError : c.textWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
