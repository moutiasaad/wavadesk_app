import 'ai_agent_config.dart';

/// Readiness checklist (AI Agent spec §4.3). Only what the web panel has:
/// a knowledge base, and a test (recommended).
enum ReadinessItem { kb, tested }

class Readiness {
  const Readiness(this.facts, {required this.hoursSet, required this.handoffSet});

  /// From the config: local edits count before the server echoes them.
  factory Readiness.of(AiAgentConfig c) => Readiness(c.readiness, hoursSet: c.hours.isSet, handoffSet: c.handoff.anyRule);

  final AiReadinessFacts facts;
  final bool hoursSet;
  final bool handoffSet;

  bool done(ReadinessItem i) => switch (i) {
        ReadinessItem.kb => facts.kbEntries >= facts.kbMin,
        ReadinessItem.tested => facts.tested,
      };

  bool get kbReady => done(ReadinessItem.kb);

  /// Auto-reply needs the knowledge base, as on the web; testing is recommended.
  bool get autoReplyAllowed => done(ReadinessItem.kb);

  bool get complete => ReadinessItem.values.every(done);

  List<ReadinessItem> get missing => [for (final i in ReadinessItem.values) if (!done(i)) i];
}
