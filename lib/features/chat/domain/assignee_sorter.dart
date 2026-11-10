import '../../../core/models/models.dart';
import 'assignee.dart';

/// §5.6 ordering: Available (fewest open first) → Busy → Away (most
/// recently seen first). "أنا" is placed above by the caller.
abstract final class AssigneeSorter {
  static int _rank(Presence p) => switch (p) {
    Presence.online => 0,
    Presence.busy => 1,
    Presence.away => 2,
  };

  static int compare(AgentAssignee a, AgentAssignee b) {
    final r = _rank(a.presence).compareTo(_rank(b.presence));
    if (r != 0) return r;
    if (a.presence == Presence.away) {
      final at = a.lastSeenAt?.millisecondsSinceEpoch ?? 0;
      final bt = b.lastSeenAt?.millisecondsSinceEpoch ?? 0;
      if (at != bt) return bt.compareTo(at);
    } else {
      final o = a.openConversations.compareTo(b.openConversations);
      if (o != 0) return o;
    }
    return a.name.compareTo(b.name);
  }

  static List<AgentAssignee> sort(Iterable<AgentAssignee> agents) => [...agents]..sort(compare);
}
