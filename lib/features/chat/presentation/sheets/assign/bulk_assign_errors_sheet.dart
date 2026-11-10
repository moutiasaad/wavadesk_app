import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/assignee.dart';

/// "عرض الأخطاء" after a partial bulk assign (Assign spec §9).
Future<void> showBulkAssignErrorsSheet(BuildContext context, WidgetRef ref, List<BulkAssignFailure> failures) {
  final l = context.l10n;
  final inbox = ref.read(inboxProvider.notifier);
  String reason(String code) => switch (code) {
    'same_assignee' => l.as_err_same,
    'resolved' => l.as_err_resolved,
    'state_changed' => l.as_err_state,
    'forbidden' => l.as_forbidden,
    'capacity_reached' => l.as_badge_capacity,
    _ => l.as_err_generic,
  };
  return AppBottomSheet.show<void>(
    context,
    title: l.as_errors_title(failures.length),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in failures)
          () {
            final conv = inbox.byId(f.conversationId);
            final name = conv?.customer.name ?? f.conversationId;
            return ListTile(
              minTileHeight: 56,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              leading: conv == null
                  ? null
                  : AppAvatar(name: name, id: conv.customer.id, channel: conv.channel, size: AppAvatarSize.sm),
              title: Text(name, style: ctx.text.listTitle),
              subtitle: Text(reason(f.code), style: ctx.text.bodySmall.copyWith(color: ctx.colors.textError)),
            );
          }(),
      ],
    ),
  );
}
