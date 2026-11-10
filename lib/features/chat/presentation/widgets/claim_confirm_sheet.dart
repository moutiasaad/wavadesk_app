import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

enum ClaimConfirmKind { away, capacity }

/// Away / soft-capacity confirm (Claim spec §8). Returns true to claim.
Future<bool> showClaimConfirmSheet(BuildContext context, {required ClaimConfirmKind kind, int open = 0}) async {
  final ok = await AppBottomSheet.show<bool>(
    context,
    showClose: false,
    builder: (ctx) {
      final c = ctx.colors;
      final t = ctx.text;
      final l = ctx.l10n;
      final away = kind == ClaimConfirmKind.away;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.warningContainer, shape: BoxShape.circle),
              child: Icon(AppIcons.clock, size: 28, color: c.textWarning),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                away ? l.claim_away_title : l.claim_capacity_title(open),
                style: t.h3,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              away ? l.claim_away_body : l.claim_capacity_body,
              style: t.bodyMedium.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: away ? l.claim_away_confirm : l.claim_capacity_confirm,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: l.claim_cancel,
              variant: AppButtonVariant.text,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    },
  );
  if (kind == ClaimConfirmKind.away) Analytics.log('claim_away_confirm', {'confirmed': ok ?? false});
  return ok ?? false;
}
