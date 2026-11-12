import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api_provider.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';

/// Open conversations assigned to me (`conversations/count?segment=mine`);
/// 0 when the count can't be read.
Future<int> myOpenChatsCount(WidgetRef ref) async {
  try {
    final r = await ref.read(wdApiRequiredProvider).get('conversations/count', query: {'segment': 'mine'});
    return (r.map['count'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
}

/// "إعادتها لغير المُسندة": unassign my open chats (first 50) in one bulk call.
void unawaitedRelease(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  () async {
    try {
      final api = ref.read(wdApiRequiredProvider);
      final r = await api.get('conversations', query: {'segment': 'mine', 'limit': 50});
      final ids = [for (final row in r.list) '${row['id']}'];
      if (ids.isEmpty) return;
      await api.post('conversations/bulk', body: {'action': 'unassign', 'ids': ids});
      if (context.mounted) AppSnackbar.show(context, message: l.acc_released(ids.length), kind: SnackKind.success);
    } catch (_) {
      if (context.mounted) AppSnackbar.show(context, message: l.acc_presence_failed, kind: SnackKind.error);
    }
  }();
}
