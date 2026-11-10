/// "قديم" badge: an entry not updated for more than 180 days
/// (Knowledge Base spec §4.6).
abstract final class StaleRule {
  static const threshold = Duration(days: 180);

  static bool isStale(DateTime updatedAt, {DateTime? now}) => (now ?? DateTime.now()).difference(updatedAt) > threshold;
}
