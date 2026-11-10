import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../data/messages_repository.dart';
import '../domain/rewrite_session.dart';

enum ComposerMode { reply, note }

/// A picked file/photo uploading before send (§4.7 attachments preview).
@immutable
class PendingAttachment {
  const PendingAttachment({required this.id, required this.kind, required this.name, this.progress = 0, this.uploadId});

  final String id;
  final MessageKind kind;
  final String name;
  final double progress;
  final String? uploadId;

  bool get ready => uploadId != null;

  PendingAttachment copyWith({double? progress, String? uploadId}) => PendingAttachment(
    id: id,
    kind: kind,
    name: name,
    progress: progress ?? this.progress,
    uploadId: uploadId ?? this.uploadId,
  );
}

@immutable
class ComposerState {
  const ComposerState({
    this.mode = ComposerMode.reply,
    this.showModeToggle = false,
    this.replyTo,
    this.attachments = const [],
    this.hasText = false,
  });

  final ComposerMode mode;

  /// Toggle appears after "ملاحظة", `compose=note`, or a leading `@` (§4.7.1).
  final bool showModeToggle;
  final Message? replyTo;
  final List<PendingAttachment> attachments;
  final bool hasText;

  bool get canSend => hasText || attachments.any((a) => a.ready);

  ComposerState copyWith({
    ComposerMode? mode,
    bool? showModeToggle,
    Message? replyTo,
    bool clearReply = false,
    List<PendingAttachment>? attachments,
    bool? hasText,
  }) => ComposerState(
    mode: mode ?? this.mode,
    showModeToggle: showModeToggle ?? this.showModeToggle,
    replyTo: clearReply ? null : (replyTo ?? this.replyTo),
    attachments: attachments ?? this.attachments,
    hasText: hasText ?? this.hasText,
  );
}

final composerControllerProvider = NotifierProvider.autoDispose.family<ComposerController, ComposerState, String>(
  ComposerController.new,
);

/// Draft, mode, reply-quote and attachments (Chat spec §4.7). Owns the
/// field's [TextEditingController]; drafts are saved locally on every change
/// (debounced 500ms), on exit, and synced to the server.
class ComposerController extends AutoDisposeFamilyNotifier<ComposerState, String> {
  late final TextEditingController text;
  Timer? _debounce;

  /// How the current text got there, for `sent_via` (§8).
  String _origin = 'manual';
  String? _aiText;
  String? _rewriteId;

  /// Text came from the AI suggestion card's "تعديل" (rewrite `entry`).
  bool get fromSuggestion => _origin == 'ai_edited';

  String get _draftKey => 'draft_$arg';

  @override
  ComposerState build(String id) {
    final prefs = ref.read(sharedPrefsProvider);
    final saved = ref.read(draftsProvider)[id] ?? prefs.getString(_draftKey) ?? '';
    text = TextEditingController(text: saved);
    text.addListener(_onText);
    ref.onDispose(() {
      _debounce?.cancel();
      _persist(); // save on exit
      text.removeListener(_onText);
      text.dispose();
    });
    return ComposerState(hasText: saved.trim().isNotEmpty);
  }

  void _onText() {
    final has = text.text.trim().isNotEmpty;
    // Cleared by hand → whatever comes next is typed, not AI.
    if (!has && _origin != 'manual') {
      _origin = 'manual';
      _aiText = null;
      _rewriteId = null;
    }
    if (has != state.hasText) state = state.copyWith(hasText: has);
    // A leading "@" switches to note mode (mentions).
    if (text.text.startsWith('@') && state.mode != ComposerMode.note) {
      state = state.copyWith(mode: ComposerMode.note, showModeToggle: true);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persist);
  }

  void _persist() {
    final t = text.text;
    ref.read(draftsProvider.notifier).set(arg, t);
    final prefs = ref.read(sharedPrefsProvider);
    t.trim().isEmpty ? prefs.remove(_draftKey) : prefs.setString(_draftKey, t);
    unawaited(ref.read(messagesRepositoryProvider).saveDraft(arg, t));
  }

  void setMode(ComposerMode mode) => state = state.copyWith(mode: mode, showModeToggle: true);

  /// "ملاحظة" in the attach sheet / `compose=note` / profile quick action.
  void enterNoteMode() => setMode(ComposerMode.note);

  void hideModeToggle() => state = state.copyWith(mode: ComposerMode.reply, showModeToggle: false);

  void setReply(Message? m) => state = m == null ? state.copyWith(clearReply: true) : state.copyWith(replyTo: m);

  /// "تعديل" on the AI card: text goes into the field, not sent.
  void fillFromAi(String suggestion) {
    _origin = 'ai_edited';
    _aiText = suggestion;
    _set(suggestion);
  }

  /// AI Rewrite sheet "استخدم هذا الرد" (Rewrite spec §2): replaces the
  /// whole text, or only [range] when opened from a selection. Caret goes
  /// to the end of the inserted wording. Never sends.
  void applyRewrite(RewriteOutcome o, {TextRange? range}) {
    _origin = 'ai_rewrite';
    _aiText = o.text;
    _rewriteId = o.rewriteId;
    final current = text.text;
    if (range == null || !range.isValid || range.end > current.length) {
      _set(o.text);
      return;
    }
    final next = range.textBefore(current) + o.text + range.textAfter(current);
    text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: range.start + o.text.length),
    );
  }

  /// Search → KB hit → "إدراج في الرد" (Search spec §6.4): appended to the
  /// draft, never sent.
  void insertKbAnswer(String answer) {
    final cur = text.text.trimRight();
    _origin = 'kb';
    _set(cur.isEmpty ? answer : '$cur\n$answer');
  }

  /// `/` quick reply: variables like `{name}` filled from the contact.
  void insertQuickReply(QuickReply r, {required String contactName}) {
    _origin = 'quick_reply';
    _set(r.text.replaceAll('{name}', contactName.split(' ').first));
  }

  /// `@` mention in note mode: replaces the trailing "@query".
  void insertMention(String name) {
    final t = text.text;
    final at = t.lastIndexOf('@');
    final next = '${at < 0 ? t : t.substring(0, at)}@$name ';
    _set(next);
  }

  void _set(String value) {
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  // ---- Attachments ------------------------------------------------------------------

  /// [bytes]/[mime]: the picked file. Without bytes (no picker plugin yet)
  /// the real API rejects the upload and the chip is removed.
  void addAttachment(MessageKind kind, String name, {List<int> bytes = const [], String? mime}) {
    final a = PendingAttachment(id: 'att-${DateTime.now().microsecondsSinceEpoch}', kind: kind, name: name);
    state = state.copyWith(attachments: [...state.attachments, a]);
    ref
        .read(messagesRepositoryProvider)
        .uploads
        .upload(
          fileName: name,
          bytes: bytes,
          mime: mime ?? (kind == MessageKind.image ? 'image/jpeg' : 'application/pdf'),
        )
        .listen((p) {
          state = state.copyWith(
            attachments: [
              for (final x in state.attachments)
                x.id == a.id ? x.copyWith(progress: p.progress, uploadId: p.uploadId) : x,
            ],
          );
        }, onError: (_) => removeAttachment(a.id));
  }

  void removeAttachment(String id) => state = state.copyWith(
    attachments: [
      for (final a in state.attachments)
        if (a.id != id) a,
    ],
  );

  // ---- Send -----------------------------------------------------------------------------

  /// Builds the outgoing messages (attachments first, then text), then
  /// clears the composer but keeps focus (§4.7.6).
  List<OutgoingMessage> takeOutgoing({required List<String> mentionNames}) {
    final note = state.mode == ComposerMode.note;
    final body = text.text.trim();
    final quote = state.replyTo == null
        ? null
        : QuotedMessage(
            sender: state.replyTo!.senderName ?? '',
            text: state.replyTo!.text,
            messageId: state.replyTo!.id,
          );
    final sentVia = _origin == 'ai_edited' && body == _aiText?.trim() ? 'ai_suggestion' : _origin;
    final rewriteId = _origin == 'ai_rewrite' ? _rewriteId : null;
    final out = <OutgoingMessage>[
      for (final a in state.attachments)
        if (a.ready)
          OutgoingMessage(
            text: '',
            kind: a.kind,
            fileName: a.kind == MessageKind.file ? a.name : null,
            fileSize: a.kind == MessageKind.file ? '240 KB' : null,
            uploadId: a.uploadId,
            isNote: note,
          ),
      if (body.isNotEmpty)
        OutgoingMessage(
          text: body,
          quote: quote,
          sentVia: sentVia,
          rewriteId: rewriteId,
          isNote: note,
          mentions: note
              ? [
                  for (final n in mentionNames)
                    if (body.contains('@$n')) n,
                ]
              : const [],
        ),
    ];
    text.clear();
    _origin = 'manual';
    _aiText = null;
    _rewriteId = null;
    state = state.copyWith(clearReply: true, attachments: const [], hasText: false);
    _persist();
    return out;
  }
}
