import 'conversation_detail.dart';

/// Which single widget fills the bottom slot (Chat spec §3, §15 resolver).
enum BottomSlot {
  readOnlyPast,
  readOnlyBlocked,
  readOnlyResolved,
  readOnlyAi,
  claim,
  composer,
  readOnlyColleague,

  /// Unassigned but the agent may not claim it (not in the team).
  readOnlyTeam,
}

extension BottomSlotX on BottomSlot {
  bool get isReadOnly => this != BottomSlot.claim && this != BottomSlot.composer;

  /// Colleague / AI read-only bars still allow internal notes (§4.10).
  /// Claim state too: "إضافة ملاحظة داخلية" from ⋮ (Claim spec §5.3).
  bool get allowsNotes =>
      this == BottomSlot.readOnlyColleague || this == BottomSlot.readOnlyAi || this == BottomSlot.claim;
}

abstract final class BottomSlotResolver {
  static BottomSlot resolve(ConversationDetail d, {required bool readOnlyRoute}) {
    if (readOnlyRoute) return BottomSlot.readOnlyPast;
    if (d.blocked) return BottomSlot.readOnlyBlocked;
    if (d.isClosed) return BottomSlot.readOnlyResolved;
    if (d.assignee == null && d.handledByAi && d.aiAutoMode) return BottomSlot.readOnlyAi;
    if (d.assignee == null || d.isUnassigned) {
      return d.permissions.canClaim ? BottomSlot.claim : BottomSlot.readOnlyTeam;
    }
    if (d.isMine) return BottomSlot.composer;
    return BottomSlot.readOnlyColleague;
  }
}
