import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../conversations/application/conversation_filters_controller.dart';
import '../../conversations/domain/conversation_filters.dart';

/// Where dashboard taps lead (spec §4: "the dashboard is a launcher").
abstract final class DashboardLinks {
  /// Inbox tab with a segment + quick chip applied, even when the inbox
  /// screen is already alive with the same query parameters.
  static void inbox(BuildContext context, WidgetRef ref, {required InboxSegment segment, QuickChip chip = QuickChip.all}) {
    ref.read(conversationFiltersProvider.notifier)
      ..setSegment(segment)
      ..setChip(chip);
    context.go(Routes.conversations);
  }

  /// Web dashboard (owner / admin only, §4.9).
  static Future<void> webReports() async {
    final origin = apiBaseUrl.isNotEmpty ? apiBaseUrl : 'https://app.wavadesk.com';
    await launchUrl(Uri.parse('$origin/tenant-admin/dashboard'), mode: LaunchMode.externalApplication);
  }
}
