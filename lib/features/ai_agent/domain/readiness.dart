import 'ai_agent_config.dart';

/// Readiness checklist (AI Agent spec §4.3).
enum ReadinessItem { kb, hours, handoff, tested }

class Readiness {
  const Readiness(this.facts, {required this.hoursSet, required this.handoffSet});

  /// From the config: local edits count before the server echoes them.
  factory Readiness.of(AiAgentConfig c) => Readiness(c.readiness, hoursSet: c.hours.isSet, handoffSet: c.handoff.anyRule);

  final AiReadinessFacts facts;
  final bool hoursSet;
  final bool handoffSet;

  bool done(ReadinessItem i) => switch (i) {
        ReadinessItem.kb => facts.kbEntries >= facts.kbMin,
        ReadinessItem.hours => hoursSet,
        ReadinessItem.handoff => handoffSet,
        ReadinessItem.tested => facts.tested,
      };

  bool get kbReady => done(ReadinessItem.kb);

  /// Auto-reply needs the first three; testing is recommended (§4.3).
  bool get autoReplyAllowed => done(ReadinessItem.kb) && done(ReadinessItem.hours) && done(ReadinessItem.handoff);

  bool get complete => ReadinessItem.values.every(done);

  List<ReadinessItem> get missing => [for (final i in ReadinessItem.values) if (!done(i)) i];
}
