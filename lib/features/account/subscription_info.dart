import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wd_api_provider.dart';
import '../../core/state/load_state.dart';
import '../auth/application/auth_session.dart';

/// `GET /mobile/v1/subscription` (admins).
@immutable
class SubscriptionInfo {
  const SubscriptionInfo({
    this.planName,
    this.priceAmount,
    this.priceCurrency,
    this.onTrial = false,
    this.endsAt,
    this.renewsAt,
    this.seatsUsed = 0,
    this.seatsLimit,
    this.aiUsed = 0,
    this.aiLimit,
    this.manageUrl,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'] is Map ? Map<String, dynamic>.from(j['plan'] as Map) : null;
    final price = plan?['price_monthly'] is Map ? Map<String, dynamic>.from(plan!['price_monthly'] as Map) : null;
    final seats = j['seats'] is Map ? Map<String, dynamic>.from(j['seats'] as Map) : const <String, dynamic>{};
    final ai = j['ai_quota'] is Map ? Map<String, dynamic>.from(j['ai_quota'] as Map) : const <String, dynamic>{};
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
    int? n(Object? v) => v is num ? v.toInt() : null;
    return SubscriptionInfo(
      planName: plan?['name'] as String?,
      priceAmount: price?['amount'] as String?,
      priceCurrency: price?['currency'] as String?,
      onTrial: j['on_trial'] == true,
      endsAt: date(j['ends_at']),
      renewsAt: date(j['renews_at']),
      seatsUsed: n(seats['used']) ?? 0,
      seatsLimit: n(seats['limit']),
      aiUsed: n(ai['used']) ?? 0,
      aiLimit: n(ai['limit']),
      manageUrl: j['manage_url'] as String?,
    );
  }

  final String? planName;
  final String? priceAmount;
  final String? priceCurrency;
  final bool onTrial;
  final DateTime? endsAt;

  /// Paid plans only (a trial just ends).
  final DateTime? renewsAt;
  final int seatsUsed;

  /// null = unlimited.
  final int? seatsLimit;
  final int aiUsed;

  /// null = unlimited, 0 = no AI in the plan.
  final int? aiLimit;
  final String? manageUrl;
}

/// Kept 10 min after the screen closes so reopening is instant; the screen
/// refreshes it quietly on open.
final subscriptionInfoProvider = FutureProvider.autoDispose<SubscriptionInfo>((ref) async {
  ref.watch(authProvider);
  ref.cacheFor(const Duration(minutes: 10));
  final api = ref.watch(wdApiRequiredProvider);
  return SubscriptionInfo.fromJson((await api.get('subscription')).map);
});
