import 'package:flutter/widgets.dart';

import '../../../core/models/models.dart';
import 'language_detector.dart';
import 'rewrite_style.dart';

/// Where the sheet was opened from (Rewrite spec §2, analytics `entry`).
enum RewriteEntry { composer, selection, suggestion }

/// Result-card state (§6).
enum RewriteStatus { loading, streaming, success, error, rateLimited, planLimit, blocked, offline, tooLong }

/// One generated wording (§7). [editedText] is the agent's inline edit.
@immutable
class RewriteVersion {
  const RewriteVersion({
    required this.id,
    required this.text,
    required this.language,
    this.insertedName = false,
    this.factWarning = false,
    this.unchanged = false,
    this.editedText,
  });

  final String id;
  final String text;
  final String language;
  final bool insertedName;
  final bool factWarning;
  final bool unchanged;
  final String? editedText;

  bool get edited => editedText != null && editedText != text;
  String get effectiveText => editedText ?? text;

  RewriteVersion withEdit(String value) => RewriteVersion(
    id: id,
    text: text,
    language: language,
    insertedName: insertedName,
    factWarning: factWarning,
    unchanged: unchanged,
    editedText: value,
  );
}

/// Max character count per channel (§5.5 over-limit row). `null` = none.
int? channelCharLimit(Channel channel) => switch (channel) {
  Channel.sms => 160,
  Channel.whatsapp => 4096,
  Channel.telegram => 4096,
  Channel.messenger => 2000,
  Channel.instagram => 1000,
  _ => null,
};

/// Everything the sheet shows; lives only while the sheet is open (§7
/// "Session cleared on close").
@immutable
class RewriteSession {
  const RewriteSession({
    required this.source,
    required this.entry,
    required this.note,
    required this.style,
    required this.status,
    this.versions = const {},
    this.index = const {},
    this.extraStyle,
    this.teamStyles = const [],
    this.streamingText = '',
    this.retryAfter = 0,
    this.errorCode,
    this.editingOriginal = false,
    this.preferredLanguage,
    this.channelLimit,
    this.canViewPlans = false,
    this.kbAnswer = false,
  });

  static const maxVersions = 5;
  static const maxSourceChars = 2000;

  final String source;
  final RewriteEntry entry;

  /// Composer is in note mode → styles limited (§2).
  final bool note;
  final RewriteStyle style;
  final RewriteStatus status;

  /// Per style id → its versions, oldest first.
  final Map<String, List<RewriteVersion>> versions;

  /// Per style id → the version shown by the pager.
  final Map<String, int> index;

  /// A style picked from "المزيد" — a temporary 7th chip (§5.4.2).
  final RewriteStyle? extraStyle;
  final List<RewriteStyle> teamStyles;
  final String streamingText;

  /// 429 countdown, seconds.
  final int retryAfter;
  final String? errorCode;
  final bool editingOriginal;

  /// Contact profile language ("ar" / "en").
  final String? preferredLanguage;
  final int? channelLimit;

  /// Admins see "عرض الخطط" on the plan-limit card.
  final bool canViewPlans;

  /// Opened from the KB answer editor: fixed style set, no "المزيد".
  final bool kbAnswer;

  String get sourceLanguage => LanguageDetector.detect(source);
  bool get sourceIsArabic => sourceLanguage == 'ar';
  String get targetLanguage => sourceIsArabic ? 'en' : 'ar';

  /// "العميل يفضّل {language}" + dot on the translate chip (§5.4.1).
  bool get customerPrefersOther => preferredLanguage != null && preferredLanguage != sourceLanguage && !note && !kbAnswer;

  List<RewriteStyle> get chips => kbAnswer ? RewriteStyle.kbAnswerChips : [
    ...RewriteStyle.chipsFor(note: note),
    if (extraStyle != null && !RewriteStyle.chips.contains(extraStyle)) extraStyle!,
  ];

  List<RewriteVersion> versionsOf(RewriteStyle s) => versions[s.id] ?? const [];
  bool hasCached(RewriteStyle s) => versionsOf(s).isNotEmpty;

  List<RewriteVersion> get currentVersions => versionsOf(style);
  int get currentIndex => (index[style.id] ?? currentVersions.length - 1).clamp(0, currentVersions.length - 1);
  RewriteVersion? get current => currentVersions.isEmpty ? null : currentVersions[currentIndex];

  bool get busy => status == RewriteStatus.loading || status == RewriteStatus.streaming;

  /// Characters of the text that would go into the composer.
  int get resultLength => current?.effectiveText.characters.length ?? 0;
  bool get overLimit => channelLimit != null && current != null && resultLength > channelLimit!;

  bool get canUse =>
      status == RewriteStatus.success && current != null && current!.effectiveText.trim().isNotEmpty && !overLimit;

  bool get atMaxVersions => currentVersions.length >= maxVersions;
  bool get canRegenerate =>
      !busy && !atMaxVersions && status != RewriteStatus.offline && status != RewriteStatus.tooLong;

  /// Chips are disabled only offline (40%); otherwise switching cancels the
  /// in-flight request (§5.4).
  bool get chipsEnabled => status != RewriteStatus.offline;

  RewriteSession copyWith({
    String? source,
    RewriteStyle? style,
    RewriteStatus? status,
    Map<String, List<RewriteVersion>>? versions,
    Map<String, int>? index,
    RewriteStyle? extraStyle,
    List<RewriteStyle>? teamStyles,
    String? streamingText,
    int? retryAfter,
    String? errorCode,
    bool clearErrorCode = false,
    bool? editingOriginal,
    String? preferredLanguage,
  }) => RewriteSession(
    source: source ?? this.source,
    entry: entry,
    note: note,
    style: style ?? this.style,
    status: status ?? this.status,
    versions: versions ?? this.versions,
    index: index ?? this.index,
    extraStyle: extraStyle ?? this.extraStyle,
    teamStyles: teamStyles ?? this.teamStyles,
    streamingText: streamingText ?? this.streamingText,
    retryAfter: retryAfter ?? this.retryAfter,
    errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
    editingOriginal: editingOriginal ?? this.editingOriginal,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    channelLimit: channelLimit,
    canViewPlans: canViewPlans,
    kbAnswer: kbAnswer,
  );
}

/// What "استخدم هذا الرد" hands back to the composer (§2 exit).
@immutable
class RewriteOutcome {
  const RewriteOutcome({required this.text, required this.rewriteId});

  final String text;

  /// Sent with the message as `rewrite_id` (`sent_via: ai_rewrite`, §8).
  final String rewriteId;
}
