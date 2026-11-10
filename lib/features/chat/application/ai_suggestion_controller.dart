import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';

enum AiCardView { hidden, card, collapsed, loading, noAnswer }

@immutable
class AiSuggestionState {
  const AiSuggestionState({this.suggestion, this.view = AiCardView.hidden, this.expanded = false});

  final AiSuggestion? suggestion;
  final AiCardView view;

  /// Body expanded past 5 lines ("المزيد").
  final bool expanded;

  bool get lowConfidence => (suggestion?.confidence ?? 1) < 0.6;
}

final aiSuggestionControllerProvider = NotifierProvider.autoDispose
    .family<AiSuggestionController, AiSuggestionState, String>(AiSuggestionController.new);

/// AI suggestion card state (Chat spec §4.6). Mirrors the conversation's
/// suggestion; dismiss collapses it to the "اقتراح جاهز" pill.
///
/// Real API: `GET /mobile/v1/conversations/{id}/ai-suggestion` (202 while it
/// is generated → polled), `POST …/ai-suggestion/regenerate`. A 402/403
/// (plan limit, AI module off) hides the card.
class AiSuggestionController extends AutoDisposeFamilyNotifier<AiSuggestionState, String> {
  bool _expanded = false;

  // ---- real-API state ----
  AiSuggestion? _remote;
  bool _remoteLoading = false;
  bool _remoteDismissed = false;
  Timer? _poll;
  int _pollsLeft = 0;
  bool _started = false;

  @override
  AiSuggestionState build(String id) {
    ref.onDispose(() => _poll?.cancel());
    if (!_started) {
      _started = true;
      Future.microtask(_fetch);
    }
    return _remoteState();
  }

  AiSuggestionState _remoteState() {
    final s = _remote;
    final view = _remoteLoading
        ? AiCardView.loading
        : s == null
        ? AiCardView.hidden
        : (_remoteDismissed ? AiCardView.collapsed : AiCardView.card);
    return AiSuggestionState(suggestion: s, view: view, expanded: _expanded);
  }

  void _emit() => state = _remoteState();

  WdApi get _api => ref.read(wdApiRequiredProvider);

  Future<void> _fetch({bool regenerate = false}) async {
    _poll?.cancel();
    try {
      final r = regenerate
          ? await _api.post('conversations/$arg/ai-suggestion/regenerate', body: const {})
          : await _api.get('conversations/$arg/ai-suggestion');
      _apply(r);
    } on WdApiException catch (e) {
      // plan_limit / module_unavailable / no messages yet / network: no card.
      if (kDebugMode) debugPrint('[ai-suggestion] ${e.code}');
      _remoteLoading = false;
      if (e.status == 402 || e.status == 403) _remote = null;
      _emit();
    }
  }

  void _apply(WdResponse r) {
    final d = r.map;
    final text = (d['text'] as String?)?.trim() ?? '';
    if (r.status == 202 || d['status'] == 'pending') {
      _remoteLoading = true;
      _emit();
      if (_pollsLeft <= 0) _pollsLeft = 15;
      _pollsLeft--;
      if (_pollsLeft > 0) {
        _poll = Timer(const Duration(seconds: 2), _fetch);
      } else {
        _remoteLoading = false;
        _emit();
      }
      return;
    }
    _pollsLeft = 0;
    _remoteLoading = false;
    _remote = text.isEmpty ? null : AiSuggestion(text: text, source: '');
    _emit();
  }

  void _log(String action) =>
      Analytics.log('chat_ai_suggestion_action', {'action': action, 'confidence': state.suggestion?.confidence});

  /// Sends exactly the suggested text (`sent_via: ai_suggestion`).
  void send() {
    final s = state.suggestion;
    if (s == null) return;
    HapticFeedback.lightImpact();
    _log('send');
    _remote = null;
    _emit();
    unawaited(
      _api
          .post(
            'conversations/$arg/messages',
            body: {'text': s.text, 'sent_via': 'ai_suggestion', 'client_id': const Uuid().v4()},
          )
          .catchError((Object e) {
            // Put the card back so the agent can retry or edit.
            _remote = s;
            _emit();
            return const WdResponse(0, null, {});
          }),
    );
  }

  /// Returns the text for the composer and collapses the card.
  String? edit() {
    final s = state.suggestion;
    if (s == null) return null;
    _log('edit');
    _remoteDismissed = true;
    _emit();
    return s.text;
  }

  Future<void> regenerate() {
    _log('regenerate');
    _remoteLoading = true;
    _remoteDismissed = false;
    _pollsLeft = 0;
    _emit();
    return _fetch(regenerate: true);
  }

  /// ✕, swipe down, or the agent started typing.
  void collapse({bool byUser = true}) {
    if (state.view != AiCardView.card) return;
    if (byUser) _log('dismiss');
    _remoteDismissed = true;
    _emit();
  }

  void expandFromPill() {
    _remoteDismissed = false;
    _emit();
  }

  void toggleBody() {
    _expanded = !_expanded;
    state = AiSuggestionState(suggestion: state.suggestion, view: state.view, expanded: _expanded);
  }
}
