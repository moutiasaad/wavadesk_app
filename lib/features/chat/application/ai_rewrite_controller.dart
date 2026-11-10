import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../../customer/data/contacts_repository.dart';
import '../data/ai_rewrite_api.dart';
import '../domain/rewrite_session.dart';
import '../domain/rewrite_style.dart';

/// One sheet opening. [sessionId] is unique per open, so closing and
/// reopening starts a fresh session (Rewrite spec §7).
@immutable
class RewriteArgs {
  RewriteArgs({
    required this.conversationId,
    required this.contactId,
    required this.source,
    required this.entry,
    required this.note,
    required this.channel,
    required this.agentId,
    this.aiEnabled = true,
    this.canViewPlans = false,
    this.kbAnswer = false,
  }) : sessionId = '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  static int _seq = 0;

  final String sessionId;
  final String conversationId;
  final String contactId;
  final String source;
  final RewriteEntry entry;
  final bool note;
  final Channel channel;
  final String agentId;

  /// Workspace AI switched off → plan-limit card without a request.
  final bool aiEnabled;
  final bool canViewPlans;

  /// KB answer editor (Add Answer spec §6.2): no conversation, no contact.
  final bool kbAnswer;

  @override
  bool operator ==(Object other) => other is RewriteArgs && other.sessionId == sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

final aiRewriteControllerProvider = NotifierProvider.autoDispose
    .family<AiRewriteController, RewriteSession, RewriteArgs>(AiRewriteController.new);

/// Session versions map, cancel tokens, streaming and the persisted
/// last-used style (§5.4, §6, §7).
class AiRewriteController extends AutoDisposeFamilyNotifier<RewriteSession, RewriteArgs> {
  RewriteCancelToken? _token;
  StreamSubscription<RewriteEvent>? _sub;
  Timer? _countdown;
  bool _lastWasRegenerate = false;
  bool _used = false;
  bool _disposed = false;
  String _pendingSource = '';
  final _tried = <String>{};
  final _editedLogged = <String>{};

  AiRewriteApi get _api => ref.read(aiRewriteApiProvider);
  String get _prefsKey => 'rw_last_style_${arg.agentId}';

  @override
  RewriteSession build(RewriteArgs args) {
    final style = _initialStyle(args.note, kb: args.kbAnswer);
    final offline = ref.read(inboxProvider).network == NetworkState.offline;
    ref.listen(inboxProvider.select((s) => s.network), (_, n) {
      if (n == NetworkState.offline) {
        _cancel();
        state = state.copyWith(status: RewriteStatus.offline);
      } else if (n == NetworkState.online && state.status == RewriteStatus.offline) {
        _restoreOrRun();
      }
    });
    ref.onDispose(() {
      _disposed = true;
      _cancel();
      _countdown?.cancel();
      if (!_used) {
        Analytics.log('rw_dismiss', {'had_result': state.versions.isNotEmpty, 'styles_tried': _tried.length});
      }
    });

    final contacts = ref.read(contactsRepositoryProvider);
    final cachedLanguage = args.kbAnswer ? null : contacts.cached(args.contactId)?.language;
    if (cachedLanguage == null && !args.kbAnswer) {
      contacts.fetch(args.contactId).then((c) {
        if (!_disposed && c.language != null) state = state.copyWith(preferredLanguage: c.language);
      }, onError: (_) {});
    }
    if (!args.note && !args.kbAnswer) {
      _api.teamStyles().then((styles) {
        if (!_disposed && styles.isNotEmpty) state = state.copyWith(teamStyles: styles);
      });
    }

    Analytics.log('rw_open', {
      'entry': args.entry.name,
      'source_len': args.source.length,
      'mode': args.note ? 'note' : 'reply',
      'auto_style': style.id,
    });

    // First request fires in parallel with the sheet animation (§3 Enter).
    scheduleMicrotask(() => _run());
    return RewriteSession(
      source: args.source,
      entry: args.entry,
      note: args.note,
      style: style,
      status: offline ? RewriteStatus.offline : RewriteStatus.loading,
      preferredLanguage: cachedLanguage,
      channelLimit: args.note || args.kbAnswer ? null : channelCharLimit(args.channel),
      canViewPlans: args.canViewPlans,
      kbAnswer: args.kbAnswer,
    );
  }

  RewriteStyle _initialStyle(bool note, {bool kb = false}) {
    final saved = ref.read(sharedPrefsProvider).getString(_prefsKey);
    final s = saved == null ? null : RewriteStyle.builtIn(saved);
    if (kb) return s != null && RewriteStyle.kbAnswerChips.contains(s) ? s : RewriteStyle.defaultStyle;
    // Only chip styles auto-run; a "المزيد" pick doesn't stick across opens.
    if (s == null || !RewriteStyle.chips.contains(s)) {
      return note ? RewriteStyle.defaultNoteStyle : RewriteStyle.defaultStyle;
    }
    if (note && !s.allowedInNote) return RewriteStyle.defaultNoteStyle;
    return s;
  }

  // ---- Requests ----------------------------------------------------------------------

  void _cancel() {
    _token?.cancel();
    _token = null;
    _sub?.cancel();
    _sub = null;
  }

  void _restoreOrRun() {
    if (state.hasCached(state.style)) {
      state = state.copyWith(status: RewriteStatus.success);
    } else {
      _run();
    }
  }

  void _run({bool regenerate = false}) {
    _cancel();
    _countdown?.cancel();
    _lastWasRegenerate = regenerate;
    final args = arg;
    final style = state.style;

    if (!args.aiEnabled) {
      state = state.copyWith(status: RewriteStatus.planLimit, errorCode: 'ai_disabled');
      return;
    }
    if (state.source.length > RewriteSession.maxSourceChars) {
      state = state.copyWith(status: RewriteStatus.tooLong);
      return;
    }
    if (ref.read(inboxProvider).network == NetworkState.offline) {
      state = state.copyWith(status: RewriteStatus.offline);
      return;
    }

    _tried.add(style.id);
    state = state.copyWith(status: RewriteStatus.loading, streamingText: '', clearErrorCode: true);
    final token = _token = RewriteCancelToken();
    final watch = Stopwatch()..start();
    var streamed = false;
    final request = RewriteRequest(
      conversationId: args.conversationId,
      sourceText: state.source,
      style: style.id,
      mode: args.note ? 'note' : 'reply',
      targetLanguage: style.isTranslate ? state.targetLanguage : null,
      variantIndex: regenerate ? state.versionsOf(style).length : 0,
    );

    _sub = _api
        .rewrite(request, token)
        .listen(
          (e) {
            if (token.cancelled || state.style != style) return;
            switch (e) {
              case RewriteDelta(:final text):
                streamed = true;
                state = state.copyWith(status: RewriteStatus.streaming, streamingText: state.streamingText + text);
              case RewriteDone(:final version):
                final list = [...state.versionsOf(style), version];
                state = state.copyWith(
                  status: RewriteStatus.success,
                  streamingText: '',
                  versions: {...state.versions, style.id: list},
                  index: {...state.index, style.id: list.length - 1},
                );
                Analytics.log('rw_result', {
                  'style': style.id,
                  'latency_ms': watch.elapsedMilliseconds,
                  'streamed': streamed,
                  'inserted_name': version.insertedName,
                  'fact_warning': version.factWarning,
                  'unchanged': version.unchanged,
                });
            }
          },
          onError: (Object e) {
            if (token.cancelled || state.style != style) return;
            _onError(e is AiRewriteException ? e : const AiRewriteException('server'));
          },
          cancelOnError: true,
        );
  }

  void _onError(AiRewriteException e) {
    Analytics.log('rw_error', {'code': e.code});
    switch (e.code) {
      case 'rate_limited':
        state = state.copyWith(status: RewriteStatus.rateLimited, retryAfter: e.retryAfter, errorCode: e.code);
        _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
          final left = state.retryAfter - 1;
          if (left <= 0) {
            t.cancel();
            _run(regenerate: _lastWasRegenerate);
          } else {
            state = state.copyWith(retryAfter: left);
          }
        });
      case 'plan_limit' || 'ai_disabled':
        state = state.copyWith(status: RewriteStatus.planLimit, errorCode: e.code);
      case 'content_blocked':
        state = state.copyWith(status: RewriteStatus.blocked, errorCode: e.code);
      case 'too_long':
        state = state.copyWith(status: RewriteStatus.tooLong, errorCode: e.code);
      case 'network' when ref.read(inboxProvider).network == NetworkState.offline:
        state = state.copyWith(status: RewriteStatus.offline, errorCode: e.code);
      default:
        state = state.copyWith(status: RewriteStatus.error, errorCode: e.code);
    }
  }

  // ---- Actions -----------------------------------------------------------------------

  /// Chip tap: runs at once and cancels any in-flight request; a style with
  /// cached versions shows its last one with no request (§5.4, §7).
  void selectStyle(RewriteStyle s) {
    if (s == state.style || !state.chipsEnabled) return;
    final cached = state.hasCached(s);
    Analytics.log('rw_style_select', {'style': s.id, 'cached': cached});
    if (RewriteStyle.chips.contains(s)) {
      unawaited(ref.read(sharedPrefsProvider).setString(_prefsKey, s.id));
    }
    _cancel();
    _countdown?.cancel();
    state = state.copyWith(style: s, streamingText: '', editingOriginal: false);
    if (cached) {
      state = state.copyWith(status: RewriteStatus.success, clearErrorCode: true);
    } else {
      _run();
    }
  }

  /// "المزيد" pick → temporary 7th chip, selected (§5.4.2).
  void selectMoreStyle(RewriteStyle s) {
    if (!RewriteStyle.chips.contains(s)) state = state.copyWith(extraStyle: s);
    selectStyle(s);
  }

  /// ↻: a new version of the same style, up to 5 (§5.6).
  void regenerate() {
    if (!state.canRegenerate) return;
    Analytics.log('rw_regenerate', {'style': state.style.id, 'version_index': state.currentVersions.length});
    _run(regenerate: true);
  }

  /// "إعادة المحاولة" on the error card.
  void retry() => _run(regenerate: _lastWasRegenerate);

  void showVersion(int i) {
    final n = state.currentVersions.length;
    if (i < 0 || i >= n) return;
    state = state.copyWith(index: {...state.index, state.style.id: i});
  }

  void startEditOriginal() {
    _pendingSource = state.source;
    state = state.copyWith(editingOriginal: true);
  }

  void updatePendingSource(String text) => _pendingSource = text;

  /// "أعد الصياغة" after editing the original: the new text becomes the
  /// source, so every cached version is dropped.
  void rerunEdited() {
    final next = _pendingSource.trim();
    if (next.isEmpty) return;
    state = state.copyWith(source: next, editingOriginal: false, versions: const {}, index: const {});
    _run();
  }

  /// Inline edit of the result card (§5.5).
  void editResult(String text) {
    final v = state.current;
    if (v == null) return;
    if (_editedLogged.add(v.id)) Analytics.log('rw_edit_result', {'style': state.style.id});
    final list = [...state.currentVersions];
    list[state.currentIndex] = v.withEdit(text);
    state = state.copyWith(versions: {...state.versions, state.style.id: list});
  }

  /// "استخدم هذا الرد" — never sends (§2).
  RewriteOutcome? use() {
    final v = state.current;
    if (v == null || !(state.canUse)) return null;
    _used = true;
    final text = v.effectiveText.trim();
    final src = state.source.length;
    Analytics.log('rw_use', {
      'style': state.style.id,
      'version_index': state.currentIndex,
      'edited': v.edited,
      'delta_pct': src == 0 ? 0 : ((text.length - src) * 100 / src).round(),
    });
    return RewriteOutcome(text: text, rewriteId: v.id);
  }
}
