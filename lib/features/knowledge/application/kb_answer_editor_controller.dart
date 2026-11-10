import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../data/kb_editor_api.dart';
import '../domain/kb_editor_validation.dart';
import '../domain/kb_entry.dart';
import '../domain/phrasing_normalizer.dart';
import 'knowledge_controller.dart';
import 'unanswered_controller.dart';

/// Add Answer spec §2 modes.
enum KbeMode { create, fromUnanswered, fromMessage, draftReview, edit }

/// Route arguments. [id] = entry id (edit), question id, message id or
/// draft id depending on [mode].
@immutable
class KbeArgs {
  const KbeArgs({required this.mode, this.id, this.hintQuestion, this.hintAnswer, this.appendAlt});

  final KbeMode mode;
  final String? id;
  final String? hintQuestion;
  final String? hintAnswer;

  /// Edit mode, "دمج كصيغة أخرى" from another editor: add this phrasing.
  final String? appendAlt;

  String get storageKey => 'kbe_draft_${mode.name}_${id ?? 'new'}';

  @override
  bool operator ==(Object other) =>
      other is KbeArgs && other.mode == mode && other.id == id && other.hintQuestion == hintQuestion && other.hintAnswer == hintAnswer && other.appendAlt == appendAlt;

  @override
  int get hashCode => Object.hash(mode, id, hintQuestion, hintAnswer, appendAlt);
}

enum KbePhase { loading, ready, saving, loadError, deleted }

/// Result of a save / review action, for the screen to close + snackbar.
enum KbeOutcomeKind { created, edited, fromUnanswered, fromChat, proposed, approved, rejected, deleted }

@immutable
class KbeOutcome {
  const KbeOutcome(this.kind, {this.entryId, this.waiting = 0});

  final KbeOutcomeKind kind;
  final String? entryId;
  final int waiting;
}

/// A save that failed; [conflict] set on 409.
@immutable
class KbeSaveFailure {
  const KbeSaveFailure({this.conflict, this.updatedBy, this.message, this.forbidden = false});

  final KbQa? conflict;
  final String? updatedBy;
  final String? message;
  final bool forbidden;

  bool get isConflict => conflict != null;
}

/// The editable fields — also the autosave payload.
@immutable
class KbeFields {
  const KbeFields({
    this.question = '',
    this.answer = '',
    this.alts = const [],
    this.tags = const [],
    this.enabled = true,
    this.channels,
    this.expiresAt,
    this.verbatim = false,
    this.handoffAfter = false,
    this.internalNotes = '',
  });

  factory KbeFields.fromQa(KbQa e) => KbeFields(
        question: e.question,
        answer: e.answer,
        alts: e.altPhrasings,
        tags: e.tags,
        enabled: e.enabled,
        channels: e.channels,
        expiresAt: e.expiresAt,
        verbatim: e.verbatim,
        handoffAfter: e.handoffAfter,
        internalNotes: e.internalNotes ?? '',
      );

  factory KbeFields.fromJson(Map<String, dynamic> j) => KbeFields(
        question: '${j['question'] ?? ''}',
        answer: '${j['answer'] ?? ''}',
        alts: [for (final s in (j['alts'] as List? ?? const [])) '$s'],
        tags: [for (final t in (j['tags'] as List? ?? const [])) KbTag.fromJson(t)],
        enabled: j['enabled'] != false,
        channels: j['channels'] is List ? [for (final s in j['channels'] as List) '$s'] : null,
        expiresAt: j['expires_at'] is String ? DateTime.tryParse(j['expires_at'] as String) : null,
        verbatim: j['verbatim'] == true,
        handoffAfter: j['handoff_after'] == true,
        internalNotes: '${j['internal_notes'] ?? ''}',
      );

  final String question;
  final String answer;
  final List<String> alts;
  final List<KbTag> tags;
  final bool enabled;

  /// null = all channels.
  final List<String>? channels;
  final DateTime? expiresAt;
  final bool verbatim;
  final bool handoffAfter;
  final String internalNotes;

  Map<String, Object?> toJson() => {
        'question': question,
        'answer': answer,
        'alts': alts,
        'tags': [for (final t in tags) t.toJson()],
        'enabled': enabled,
        'channels': channels,
        'expires_at': expiresAt?.toIso8601String(),
        'verbatim': verbatim,
        'handoff_after': handoffAfter,
        'internal_notes': internalNotes,
      };

  /// Wire body of `POST kb` / `PATCH kb/{id}` (§8).
  Map<String, Object?> toWriteJson() => {
        'question': question.trim(),
        'alt_phrasings': alts,
        'answer': answer.trim(),
        'tag_ids': [for (final t in tags) t.id],
        'enabled': enabled,
        'channels': channels,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'verbatim': verbatim,
        'handoff_after': handoffAfter,
        'internal_notes': internalNotes.trim().isEmpty ? null : internalNotes.trim(),
      };

  bool sameAs(KbeFields o) => jsonEncode(toJson()) == jsonEncode(o.toJson());

  bool get isEmpty => question.trim().isEmpty && answer.trim().isEmpty && alts.isEmpty;

  KbeFields copyWith({
    String? question,
    String? answer,
    List<String>? alts,
    List<KbTag>? tags,
    bool? enabled,
    List<String>? Function()? channels,
    DateTime? Function()? expiresAt,
    bool? verbatim,
    bool? handoffAfter,
    String? internalNotes,
  }) =>
      KbeFields(
        question: question ?? this.question,
        answer: answer ?? this.answer,
        alts: alts ?? this.alts,
        tags: tags ?? this.tags,
        enabled: enabled ?? this.enabled,
        channels: channels != null ? channels() : this.channels,
        expiresAt: expiresAt != null ? expiresAt() : this.expiresAt,
        verbatim: verbatim ?? this.verbatim,
        handoffAfter: handoffAfter ?? this.handoffAfter,
        internalNotes: internalNotes ?? this.internalNotes,
      );
}

@immutable
class KbeState {
  const KbeState({
    required this.phase,
    this.fields = const KbeFields(),
    this.initial = const KbeFields(),
    this.textRevision = 0,
    this.base,
    this.unanswered,
    this.messagePrefill,
    this.aiDraft = false,
    this.ghosts = const [],
    this.similar,
    this.conflict,
    this.warningDismissed = false,
    this.preview,
    this.previewLoading = false,
    this.previewError = false,
    this.testQuestion,
    this.showQuestionError = false,
    this.showAnswerError = false,
    this.showDateError = false,
    this.canEdit = true,
    this.offline = false,
    this.restorable,
    this.shakeTick = 0,
    this.aiAvailable = true,
  });

  final KbePhase phase;
  final KbeFields fields;

  /// What was loaded / prefilled — "dirty" compares against it.
  final KbeFields initial;

  /// Bumped when the controller replaces the question/answer text (load,
  /// restore, rewrite, conflict) so the screen re-syncs its text controllers.
  final int textRevision;

  /// Loaded entry (edit) or draft (review).
  final KbQa? base;
  final KbUnanswered? unanswered;
  final KbMessagePrefill? messagePrefill;

  /// Answer prefilled from the AI draft (§7) — tag above the field.
  final bool aiDraft;

  /// AI-suggested phrasings not yet accepted (§4.4).
  final List<String> ghosts;
  final KbSimilar? similar;
  final KbConflict? conflict;
  final bool warningDismissed;
  final KbPreview? preview;
  final bool previewLoading;
  final bool previewError;

  /// Test question picked by the user (tap bubble / try another).
  final String? testQuestion;
  final bool showQuestionError;
  final bool showAnswerError;
  final bool showDateError;

  /// `kb.edit` — false = propose mode (إرسال للمراجعة).
  final bool canEdit;
  final bool offline;

  /// Unsaved local draft found on open (§5 autosave).
  final KbeFields? restorable;

  /// Duplicate phrasing → chip shake.
  final int shakeTick;
  final bool aiAvailable;

  bool get saving => phase == KbePhase.saving;
  bool get dirty => !fields.sameAs(initial);
  bool get valid => KbEditorValidation.canSave(
        question: fields.question,
        answer: fields.answer,
        expiresAt: fields.expiresAt,
        now: DateTime.now(),
      );

  KbeFieldError? get questionError => showQuestionError ? KbEditorValidation.question(fields.question) : null;
  KbeFieldError? get answerError => showAnswerError ? KbEditorValidation.answer(fields.answer) : null;
  KbeFieldError? get dateError => showDateError ? KbEditorValidation.expiry(fields.expiresAt, DateTime.now()) : null;

  KbeState copyWith({
    KbePhase? phase,
    KbeFields? fields,
    KbeFields? initial,
    int? textRevision,
    KbQa? base,
    KbUnanswered? unanswered,
    KbMessagePrefill? messagePrefill,
    bool? aiDraft,
    List<String>? ghosts,
    KbSimilar? Function()? similar,
    KbConflict? Function()? conflict,
    bool? warningDismissed,
    KbPreview? Function()? preview,
    bool? previewLoading,
    bool? previewError,
    String? Function()? testQuestion,
    bool? showQuestionError,
    bool? showAnswerError,
    bool? showDateError,
    bool? canEdit,
    bool? offline,
    KbeFields? Function()? restorable,
    int? shakeTick,
    bool? aiAvailable,
  }) =>
      KbeState(
        phase: phase ?? this.phase,
        fields: fields ?? this.fields,
        initial: initial ?? this.initial,
        textRevision: textRevision ?? this.textRevision,
        base: base ?? this.base,
        unanswered: unanswered ?? this.unanswered,
        messagePrefill: messagePrefill ?? this.messagePrefill,
        aiDraft: aiDraft ?? this.aiDraft,
        ghosts: ghosts ?? this.ghosts,
        similar: similar != null ? similar() : this.similar,
        conflict: conflict != null ? conflict() : this.conflict,
        warningDismissed: warningDismissed ?? this.warningDismissed,
        preview: preview != null ? preview() : this.preview,
        previewLoading: previewLoading ?? this.previewLoading,
        previewError: previewError ?? this.previewError,
        testQuestion: testQuestion != null ? testQuestion() : this.testQuestion,
        showQuestionError: showQuestionError ?? this.showQuestionError,
        showAnswerError: showAnswerError ?? this.showAnswerError,
        showDateError: showDateError ?? this.showDateError,
        canEdit: canEdit ?? this.canEdit,
        offline: offline ?? this.offline,
        restorable: restorable != null ? restorable() : this.restorable,
        shakeTick: shakeTick ?? this.shakeTick,
        aiAvailable: aiAvailable ?? this.aiAvailable,
      );
}

final kbAnswerEditorControllerProvider =
    NotifierProvider.autoDispose.family<KbAnswerEditorController, KbeState, KbeArgs>(KbAnswerEditorController.new);

/// Modes, validation, debounced AI calls, local autosave and 409 handling
/// (Add Answer spec §4–§7).
class KbAnswerEditorController extends AutoDisposeFamilyNotifier<KbeState, KbeArgs> {
  static const _storage = FlutterSecureStorage();

  KbEditorApi get _api => ref.read(kbEditorApiProvider);

  Timer? _suggestTimer;
  Timer? _dupTimer;
  Timer? _previewTimer;
  Timer? _autosaveTimer;
  int _previewSeq = 0;
  int _dupSeq = 0;
  String _lastSuggestKey = '';
  final _dismissedGhosts = <String>{};
  final _idempotencyKey = WdApi.newIdempotencyKey();
  final _opened = DateTime.now();
  bool _disposed = false;
  int _testCursor = 0;

  @override
  KbeState build(KbeArgs args) {
    ref.onDispose(() {
      _disposed = true;
      for (final t in [_suggestTimer, _dupTimer, _previewTimer, _autosaveTimer]) {
        t?.cancel();
      }
    });
    final offline = ref.read(inboxProvider).network == NetworkState.offline;
    ref.listen(inboxProvider.select((s) => s.network), (_, n) {
      final off = n == NetworkState.offline;
      if (off != state.offline) {
        state = state.copyWith(offline: off);
        if (!off) _schedulePreview(immediate: true);
      }
    });
    Analytics.log('kbe_open', {'mode': args.mode.name, 'source': args.mode == KbeMode.create ? 'button' : args.mode.name});
    // `kb.edit` from the list's meta when it has loaded (agents may edit when
    // the workspace allows it), else by role. A 403 on save also flips it.
    final list = ref.read(knowledgeControllerProvider);
    final canEdit = list.loaded ? list.permissions.canEdit : ref.read(currentAgentProvider).isAdmin;
    scheduleMicrotask(_load);
    final needsLoad = args.mode != KbeMode.create;
    return KbeState(phase: needsLoad ? KbePhase.loading : KbePhase.ready, canEdit: canEdit, offline: offline);
  }

  void _set(KbeState s) {
    if (!_disposed) state = s;
  }

  // ---- Load / prefill --------------------------------------------------------------

  Future<void> load() => _load();

  Future<void> _load() async {
    final a = arg;
    try {
      var fields = KbeFields(question: a.hintQuestion ?? '', answer: a.hintAnswer ?? '');
      KbQa? base;
      KbUnanswered? unanswered;
      KbMessagePrefill? msg;
      var aiDraft = false;
      switch (a.mode) {
        case KbeMode.create:
          break;
        case KbeMode.edit:
          base = await _api.fetch(a.id!);
          fields = KbeFields.fromQa(base);
        case KbeMode.draftReview:
          base = await _api.fetchDraft(a.id!);
          fields = KbeFields.fromQa(base);
        case KbeMode.fromUnanswered:
          unanswered = await _api.fetchUnanswered(a.id!);
          aiDraft = (unanswered.draftAnswer ?? '').trim().isNotEmpty;
          fields = KbeFields(
            question: unanswered.question,
            alts: PhrasingNormalizer.dedupe(unanswered.variants, question: unanswered.question)
                .take(KbEditorValidation.maxPhrasings)
                .toList(),
            answer: unanswered.draftAnswer ?? '',
          );
        case KbeMode.fromMessage:
          msg = await _api.messagePrefill(a.id!, hintQuestion: a.hintQuestion, hintAnswer: a.hintAnswer);
          fields = KbeFields(question: msg.question, answer: msg.answer);
      }
      final restored = await _readLocalDraft();
      final initial = fields;
      final merge = a.appendAlt?.trim() ?? '';
      if (merge.isNotEmpty && fields.alts.length < KbEditorValidation.maxPhrasings &&
          !PhrasingNormalizer.isDuplicate(merge, fields.alts, question: fields.question)) {
        fields = fields.copyWith(alts: [...fields.alts, merge]);
        Analytics.log('kbe_merge_alt');
      }
      _set(state.copyWith(
        phase: KbePhase.ready,
        fields: fields,
        initial: initial,
        base: base,
        unanswered: unanswered,
        messagePrefill: msg,
        aiDraft: aiDraft,
        textRevision: state.textRevision + 1,
        restorable: () => restored != null && !restored.sameAs(fields) && !restored.isEmpty ? restored : null,
      ));
      _schedulePreview(immediate: true);
      if (fields.question.trim().runes.length >= KbEditorValidation.aiMinQuestion) {
        _checkDuplicates();
        if (a.mode == KbeMode.create || a.mode == KbeMode.fromMessage) _scheduleSuggest();
      }
    } on KbEditorApiException catch (e) {
      _set(state.copyWith(phase: e.isNotFound ? KbePhase.deleted : KbePhase.loadError));
    } catch (_) {
      _set(state.copyWith(phase: KbePhase.loadError));
    }
  }

  // ---- Field edits -----------------------------------------------------------------

  void setQuestion(String v) {
    if (v == state.fields.question) return;
    _set(state.copyWith(fields: state.fields.copyWith(question: v)));
    _afterEdit();
    _scheduleSuggest();
    _scheduleDuplicates();
    _schedulePreview();
  }

  void setAnswer(String v) {
    if (v == state.fields.answer) return;
    _set(state.copyWith(fields: state.fields.copyWith(answer: v)));
    _afterEdit();
    _schedulePreview();
  }

  /// Blur after the first edit shows inline errors (§5).
  void blurQuestion() {
    if (state.fields.question != state.initial.question || state.fields.question.isNotEmpty) {
      _set(state.copyWith(showQuestionError: state.fields.question.isNotEmpty || state.dirty));
    }
    _dupTimer?.cancel();
    _checkDuplicates();
    _schedulePreview(immediate: true);
  }

  void blurAnswer() {
    if (state.fields.answer != state.initial.answer) _set(state.copyWith(showAnswerError: true));
  }

  /// Adds phrasings; returns false (and shakes) when any was a duplicate.
  bool addAlts(Iterable<String> raw, {bool fromAi = false}) {
    var dup = false;
    final alts = [...state.fields.alts];
    for (final p in raw) {
      final s = p.trim();
      if (s.isEmpty) continue;
      if (s.runes.length > KbEditorValidation.phrasingMax || alts.length >= KbEditorValidation.maxPhrasings) {
        dup = true;
        continue;
      }
      if (PhrasingNormalizer.isDuplicate(s, alts, question: state.fields.question)) {
        dup = true;
        continue;
      }
      alts.add(s);
      Analytics.log('kbe_alt_add', {'from_ai': fromAi});
    }
    final ghosts = [for (final g in state.ghosts) if (!PhrasingNormalizer.isDuplicate(g, alts)) g];
    _set(state.copyWith(fields: state.fields.copyWith(alts: alts), ghosts: ghosts, shakeTick: dup ? state.shakeTick + 1 : null));
    _afterEdit();
    _schedulePreview();
    return !dup;
  }

  bool editAlt(int index, String value) {
    final s = value.trim();
    final others = [...state.fields.alts]..removeAt(index);
    if (s.isEmpty) {
      removeAlt(index);
      return true;
    }
    if (s.runes.length > KbEditorValidation.phrasingMax ||
        PhrasingNormalizer.isDuplicate(s, others, question: state.fields.question)) {
      _set(state.copyWith(shakeTick: state.shakeTick + 1));
      return false;
    }
    final alts = [...state.fields.alts]..[index] = s;
    _set(state.copyWith(fields: state.fields.copyWith(alts: alts)));
    _afterEdit();
    _schedulePreview();
    return true;
  }

  void removeAlt(int index) {
    final alts = [...state.fields.alts]..removeAt(index);
    _set(state.copyWith(fields: state.fields.copyWith(alts: alts)));
    _afterEdit();
    _schedulePreview();
  }

  void acceptGhost(String g) {
    _set(state.copyWith(ghosts: [...state.ghosts]..remove(g)));
    addAlts([g], fromAi: true);
  }

  void dismissGhost(String g) {
    _dismissedGhosts.add(PhrasingNormalizer.key(g));
    _set(state.copyWith(ghosts: [...state.ghosts]..remove(g)));
  }

  void setTags(List<KbTag> tags) => _update(state.fields.copyWith(tags: tags));
  void setEnabled(bool v) => _update(state.fields.copyWith(enabled: v));
  void setChannels(List<String>? v) => _update(state.fields.copyWith(channels: () => v));
  void setVerbatim(bool v) {
    _update(state.fields.copyWith(verbatim: v));
    _schedulePreview(immediate: true);
  }

  void setHandoffAfter(bool v) => _update(state.fields.copyWith(handoffAfter: v));
  void setInternalNotes(String v) => _update(state.fields.copyWith(internalNotes: v));

  void setExpiresAt(DateTime? d) {
    _update(state.fields.copyWith(expiresAt: () => d));
    _set(state.copyWith(showDateError: d != null));
  }

  /// Rewrite sheet "استخدم هذا الرد", link insert, variable token.
  void replaceAnswer(String text) {
    _set(state.copyWith(fields: state.fields.copyWith(answer: text), textRevision: state.textRevision + 1, aiDraft: false));
    _afterEdit();
    _schedulePreview();
  }

  void _update(KbeFields f) {
    _set(state.copyWith(fields: f));
    _afterEdit();
  }

  // ---- Local autosave (§5) ---------------------------------------------------------

  void _afterEdit() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _writeLocalDraft);
  }

  Future<void> _writeLocalDraft() async {
    if (_disposed || !state.dirty) return;
    try {
      await _storage.write(key: arg.storageKey, value: jsonEncode(state.fields.toJson()));
    } catch (_) {}
  }

  Future<KbeFields?> _readLocalDraft() async {
    try {
      final raw = await _storage.read(key: arg.storageKey);
      if (raw == null) return null;
      return KbeFields.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLocalDraft() async {
    _autosaveTimer?.cancel();
    try {
      await _storage.delete(key: arg.storageKey);
    } catch (_) {}
  }

  void restoreLocalDraft() {
    final r = state.restorable;
    if (r == null) return;
    _set(state.copyWith(fields: r, restorable: () => null, textRevision: state.textRevision + 1, aiDraft: false));
    _schedulePreview(immediate: true);
  }

  void ignoreLocalDraft() {
    _set(state.copyWith(restorable: () => null));
    clearLocalDraft();
  }

  // ---- AI: phrasings / duplicates / preview ----------------------------------------

  void _scheduleSuggest() {
    _suggestTimer?.cancel();
    final q = state.fields.question.trim();
    if (q.runes.length < KbEditorValidation.aiMinQuestion || state.offline || !state.aiAvailable) return;
    _suggestTimer = Timer(const Duration(milliseconds: 800), () async {
      final key = PhrasingNormalizer.key(q);
      if (key == _lastSuggestKey) return;
      _lastSuggestKey = key;
      try {
        final list = await _api.suggestPhrasings(q);
        if (_disposed || PhrasingNormalizer.key(state.fields.question) != key) return;
        final ghosts = [
          for (final g in list)
            if (!_dismissedGhosts.contains(PhrasingNormalizer.key(g)) &&
                !PhrasingNormalizer.isDuplicate(g, state.fields.alts, question: state.fields.question))
              g,
        ].take(3).toList();
        _set(state.copyWith(ghosts: ghosts));
      } catch (_) {
        // Suggestions are optional.
      }
    });
  }

  void _scheduleDuplicates() {
    _dupTimer?.cancel();
    if (state.fields.question.trim().runes.length < KbEditorValidation.aiMinQuestion) return;
    _dupTimer = Timer(const Duration(seconds: 1), _checkDuplicates);
  }

  Future<void> _checkDuplicates() async {
    final q = state.fields.question.trim();
    if (q.runes.length < KbEditorValidation.aiMinQuestion || state.offline) return;
    final seq = ++_dupSeq;
    try {
      final r = await _api.checkDuplicates(
        question: q,
        answer: state.fields.answer.trim().isEmpty ? null : state.fields.answer.trim(),
        excludeId: state.base?.id,
      );
      if (_disposed || seq != _dupSeq) return;
      final similar = r.similar.firstOrNull;
      final conflict = r.conflicts.firstOrNull;
      final changed = similar?.id != state.similar?.id || conflict?.id != state.conflict?.id;
      if (changed && (similar != null || conflict != null)) Analytics.log('kbe_duplicate_shown');
      _set(state.copyWith(
        similar: () => similar,
        conflict: () => conflict,
        warningDismissed: changed ? false : state.warningDismissed,
      ));
    } catch (_) {}
  }

  void dismissWarning() => _set(state.copyWith(warningDismissed: true));

  void _schedulePreview({bool immediate = false}) {
    _previewTimer?.cancel();
    final f = state.fields;
    if (KbEditorValidation.question(f.question) != null || KbEditorValidation.answer(f.answer) != null) {
      if (state.preview != null || state.previewError) _set(state.copyWith(preview: () => null, previewError: false));
      return;
    }
    if (state.offline) return;
    _previewTimer = Timer(immediate ? Duration.zero : const Duration(milliseconds: 1200), _runPreview);
  }

  void refreshPreview() => _schedulePreview(immediate: true);

  Future<void> _runPreview() async {
    final f = state.fields;
    final seq = ++_previewSeq;
    final watch = Stopwatch()..start();
    _set(state.copyWith(previewLoading: true, previewError: false));
    try {
      final p = await _api.preview(
        question: f.question.trim(),
        answer: f.answer.trim(),
        altPhrasings: f.alts,
        testQuestion: state.testQuestion,
        verbatim: f.verbatim,
      );
      if (_disposed || seq != _previewSeq) return;
      Analytics.log('kbe_preview', {'confidence': p.confidence.name, 'latency_ms': watch.elapsedMilliseconds});
      _set(state.copyWith(preview: () => p, previewLoading: false));
    } on KbEditorApiException catch (e) {
      if (_disposed || seq != _previewSeq) return;
      _set(state.copyWith(previewLoading: false, previewError: true, aiAvailable: e.code == 'plan_limit' ? false : null));
    } catch (_) {
      if (_disposed || seq != _previewSeq) return;
      _set(state.copyWith(previewLoading: false, previewError: true));
    }
  }

  /// Tap bubble → edited test question.
  void setTestQuestion(String q) {
    final t = q.trim();
    _set(state.copyWith(testQuestion: () => t.isEmpty ? null : t));
    _schedulePreview(immediate: true);
  }

  /// "جرّب سؤالًا آخر": cycle the phrasings, then a generated test.
  void tryAnother() {
    final pool = [...state.fields.alts, state.fields.question.trim()];
    final current = state.preview?.testQuestion ?? state.testQuestion;
    String? next;
    for (var i = 0; i < pool.length; i++) {
      final c = pool[(_testCursor + i) % pool.length];
      if (c != current) {
        next = c;
        _testCursor = (_testCursor + i + 1) % pool.length;
        break;
      }
    }
    // Only the question left → let the server generate a paraphrase.
    _set(state.copyWith(testQuestion: () => pool.length <= 1 ? null : next));
    _schedulePreview(immediate: true);
  }

  // ---- Save / review (§5) ----------------------------------------------------------

  /// Marks every field touched; returns whether the form is valid.
  bool validateAll() {
    _set(state.copyWith(showQuestionError: true, showAnswerError: true, showDateError: true));
    return state.valid;
  }

  Map<String, Object?> _body() {
    final src = switch (arg.mode) {
      KbeMode.fromUnanswered => {'type': 'unanswered', 'id': arg.id},
      KbeMode.fromMessage => {'type': 'message', 'id': arg.id},
      KbeMode.draftReview => {'type': 'draft', 'id': arg.id},
      _ => null,
    };
    return {...state.fields.toWriteJson(), 'source': src};
  }

  /// Returns the outcome, or a [KbeSaveFailure] (409 / error).
  Future<Object?> save({int? overwriteVersion}) async {
    if (state.saving) return null;
    if (!validateAll() || state.offline) return null;
    final f = state.fields;
    _set(state.copyWith(phase: KbePhase.saving));
    try {
      final KbeOutcome outcome;
      if (arg.mode == KbeMode.draftReview) {
        final r = await _api.approveDraft(arg.id!, _body());
        _applySaved(r.entry);
        Analytics.log('kbe_draft_review', {'action': 'approve'});
        outcome = KbeOutcome(KbeOutcomeKind.approved, entryId: r.entry.id);
      } else if (!state.canEdit) {
        await _api.propose(_body(), idempotencyKey: _idempotencyKey);
        outcome = const KbeOutcome(KbeOutcomeKind.proposed);
      } else if (arg.mode == KbeMode.edit) {
        final r = await _api.update(
          arg.id!,
          overwriteVersion ?? state.base?.version ?? 1,
          _body(),
          idempotencyKey: WdApi.newIdempotencyKey(),
        );
        _applySaved(r.entry);
        outcome = KbeOutcome(KbeOutcomeKind.edited, entryId: r.entry.id);
      } else {
        final r = await _api.create(_body(), idempotencyKey: _idempotencyKey);
        _applySaved(r.entry);
        if (arg.mode == KbeMode.fromUnanswered) {
          _resolveUnanswered(arg.id!);
          outcome = KbeOutcome(KbeOutcomeKind.fromUnanswered, entryId: r.entry.id, waiting: r.waitingConversations);
        } else {
          outcome = KbeOutcome(
            arg.mode == KbeMode.fromMessage ? KbeOutcomeKind.fromChat : KbeOutcomeKind.created,
            entryId: r.entry.id,
          );
        }
      }
      await clearLocalDraft();
      _logSave(f, 'success');
      _set(state.copyWith(phase: KbePhase.ready, initial: state.fields));
      return outcome;
    } on KbEditorApiException catch (e) {
      _logSave(f, e.isConflict ? 'conflict' : 'error');
      if (e.isConflict) {
        _set(state.copyWith(phase: KbePhase.ready));
        return KbeSaveFailure(conflict: e.current, updatedBy: e.updatedBy);
      }
      if (e.isNotFound && arg.mode == KbeMode.edit) {
        _set(state.copyWith(phase: KbePhase.deleted));
        return null;
      }
      if (e.isForbidden && arg.mode != KbeMode.draftReview) {
        // No kb.edit after all → propose mode (§2).
        _set(state.copyWith(phase: KbePhase.ready, canEdit: false));
        return const KbeSaveFailure(forbidden: true);
      }
      _set(state.copyWith(phase: KbePhase.ready, showAnswerError: e.fields.containsKey('answer') ? true : null));
      return KbeSaveFailure(message: e.fields['answer']?.firstOrNull ?? e.message);
    } catch (_) {
      _logSave(f, 'error');
      _set(state.copyWith(phase: KbePhase.ready));
      return const KbeSaveFailure();
    }
  }

  /// 409 → "عرض نسختهم": load their copy into the form.
  void takeTheirs(KbQa current) {
    final f = KbeFields.fromQa(current);
    _set(state.copyWith(base: current, fields: f, initial: f, textRevision: state.textRevision + 1));
    _schedulePreview(immediate: true);
  }

  Future<Object?> rejectDraft() async {
    _set(state.copyWith(phase: KbePhase.saving));
    try {
      await _api.rejectDraft(arg.id!);
      Analytics.log('kbe_draft_review', {'action': 'reject'});
      ref.read(knowledgeControllerProvider.notifier).removeLocal(arg.id!);
      await clearLocalDraft();
      _set(state.copyWith(phase: KbePhase.ready, initial: state.fields));
      return const KbeOutcome(KbeOutcomeKind.rejected);
    } catch (_) {
      _set(state.copyWith(phase: KbePhase.ready));
      return const KbeSaveFailure();
    }
  }

  Future<Object?> delete() async {
    _set(state.copyWith(phase: KbePhase.saving));
    try {
      await _api.delete(arg.id!);
      ref.read(knowledgeControllerProvider.notifier).removeLocal(arg.id!);
      await clearLocalDraft();
      _set(state.copyWith(phase: KbePhase.ready, initial: state.fields));
      return const KbeOutcome(KbeOutcomeKind.deleted);
    } catch (_) {
      _set(state.copyWith(phase: KbePhase.ready));
      return const KbeSaveFailure();
    }
  }

  Future<List<KbVersion>> versions() => _api.versions(arg.id!);

  Future<bool> restoreVersion(int version) async {
    try {
      final e = await _api.restoreVersion(arg.id!, version);
      _applySaved(e);
      final f = KbeFields.fromQa(e);
      _set(state.copyWith(base: e, fields: f, initial: f, textRevision: state.textRevision + 1));
      _schedulePreview(immediate: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<KbTag>> tags() => _api.tags();

  void _applySaved(KbQa e) {
    try {
      ref.read(knowledgeControllerProvider.notifier).applySaved(e);
    } catch (_) {}
  }

  void _resolveUnanswered(String id) {
    try {
      ref.read(unansweredControllerProvider.notifier).resolved(id);
    } catch (_) {}
  }

  void logDiscard() => Analytics.log('kbe_discard', {'had_content': !state.fields.isEmpty});

  void _logSave(KbeFields f, String result) => Analytics.log('kbe_save', {
        'mode': arg.mode.name,
        'alts_count': f.alts.length,
        'answer_len_bucket': KbEditorValidation.lengthBucket(f.answer),
        'verbatim': f.verbatim,
        'has_expiry': f.expiresAt != null,
        'duration_s': DateTime.now().difference(_opened).inSeconds,
        'result': result,
      });
}
