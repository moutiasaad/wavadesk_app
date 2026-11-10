import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../domain/language_detector.dart';
import '../domain/rewrite_session.dart';
import '../domain/rewrite_style.dart';

/// `POST /mobile/v1/ai/rewrite` request (Rewrite spec §8). The server adds the
/// last 6 messages, contact first name, tone settings, brand and limits.
class RewriteRequest {
  const RewriteRequest({
    required this.conversationId,
    required this.sourceText,
    required this.style,
    required this.mode,
    this.targetLanguage,
    this.variantIndex = 0,
    this.stream = true,
  });

  final String conversationId;
  final String sourceText;
  final String style;

  /// "reply" | "note"
  final String mode;

  /// "en" | "ar" — translate only.
  final String? targetLanguage;

  /// 0..4, regenerate diversity.
  final int variantIndex;
  final bool stream;

  Map<String, Object?> toJson() => {
    'conversation_id': conversationId,
    'source_text': sourceText,
    'style': style,
    'target_language': targetLanguage,
    'mode': mode,
    'variant_index': variantIndex,
    'stream': stream,
  };
}

sealed class RewriteEvent {
  const RewriteEvent();
}

/// A streamed token chunk (SSE `delta`).
class RewriteDelta extends RewriteEvent {
  const RewriteDelta(this.text);
  final String text;
}

/// Final payload (200 body or SSE `done`).
class RewriteDone extends RewriteEvent {
  const RewriteDone(this.version);
  final RewriteVersion version;
}

class AiRewriteException implements Exception {
  const AiRewriteException(this.code, {this.retryAfter = 0, this.statusCode = 0});

  /// network | timeout | server | plan_limit | ai_disabled | content_blocked |
  /// too_long | rate_limited
  final String code;
  final int retryAfter;
  final int statusCode;

  @override
  String toString() => 'AiRewriteException($code)';
}

/// Cancels an in-flight rewrite (style switch, regenerate, close — §6).
class RewriteCancelToken {
  bool _cancelled = false;
  final _listeners = <void Function()>[];

  bool get cancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in List.of(_listeners)) {
      l();
    }
    _listeners.clear();
  }

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

abstract interface class AiRewriteApi {
  /// Emits [RewriteDelta]s (when streaming) then exactly one [RewriteDone],
  /// or fails with [AiRewriteException]. Emits nothing after [token] is
  /// cancelled.
  Stream<RewriteEvent> rewrite(RewriteRequest request, RewriteCancelToken token);

  /// Workspace custom styles ("أساليب فريقك"). Empty on any failure.
  Future<List<RewriteStyle>> teamStyles();
}

final aiRewriteApiProvider = Provider<AiRewriteApi>((ref) {
  if (!useRealApi) {
    return SimulatedAiRewriteApi(
      contactFirstName: (id) {
        final name = ref.read(inboxProvider.notifier).byId(id)?.customer.name;
        return name?.split(' ').first;
      },
    );
  }
  return HttpAiRewriteApi(ref.read(wdApiRequiredProvider));
});

RewriteVersion rewriteVersionFromJson(Map<String, dynamic> j, {required String fallbackLanguage}) => RewriteVersion(
  id: '${j['id'] ?? j['rewrite_id'] ?? ''}',
  text: (j['text'] as String?) ?? '',
  language: (j['language'] as String?) ?? fallbackLanguage,
  insertedName: j['inserted_name'] == true,
  factWarning: j['fact_check_warning'] == true,
  unchanged: j['unchanged'] == true,
);

// ---- HTTP + SSE ---------------------------------------------------------------------

/// Real `/mobile/v1/ai/rewrite` (JSON, or SSE with Accept: text/event-stream).
///
/// Server built-in style ids differ from ours; styles the server has no
/// built-in for are sent as `style: custom` with an instruction.
class HttpAiRewriteApi implements AiRewriteApi {
  HttpAiRewriteApi(this._api);

  final WdApi _api;

  /// §6 "Timeouts: 12s → error state" (first token; a stream may run longer).
  static const timeout = Duration(seconds: 25);

  static const _serverStyles = {
    'professional': 'formal',
    'formal': 'formal',
    'shorter': 'shorter',
    'friendlier': 'friendly',
    'apology': 'empathetic',
    'fix': 'fix_grammar',
    'translate': 'translate',
  };

  static const _customInstructions = {
    'saudi': 'Rewrite it in a natural Saudi Arabic dialect, polite and clear.',
    'msa': 'Rewrite it in clear Modern Standard Arabic (fusha).',
    'greeting': 'Add a short, warm greeting at the start; keep the rest.',
    'bullets': 'Turn it into short bullet points; keep every fact.',
    'sales': 'Make it persuasive and sales-oriented without inventing offers or prices.',
    'simple': 'Use very simple words and short sentences.',
  };

  Map<String, Object?> _body(RewriteRequest r) {
    final server = _serverStyles[r.style];
    final custom = _customInstructions[r.style];
    return {
      'text': r.sourceText,
      // Workspace styles are already server ids (style_…).
      'style': server ?? (custom != null ? 'custom' : r.style),
      if (server == null && custom != null) 'instruction': custom,
      if (r.targetLanguage != null) 'target_language': r.targetLanguage,
      'mode': r.mode == 'note' ? 'note' : 'reply',
      'variant_index': r.variantIndex.clamp(0, 5),
    };
  }

  @override
  Stream<RewriteEvent> rewrite(RewriteRequest request, RewriteCancelToken token) {
    final out = StreamController<RewriteEvent>();
    final fallbackLanguage = request.targetLanguage ?? LanguageDetector.detect(request.sourceText);
    var finished = false;
    StreamSubscription<String>? sub;

    void finish([Object? error]) {
      if (finished) return;
      finished = true;
      sub?.cancel();
      if (error != null && !token.cancelled) out.addError(error);
      out.close();
    }

    final timer = Timer(timeout, () => finish(const AiRewriteException('timeout')));
    token.onCancel(() {
      timer.cancel();
      finish();
    });

    () async {
      try {
        if (!request.stream) {
          final r = await _api.post('ai/rewrite', body: _body(request));
          if (!token.cancelled && !finished) {
            out.add(RewriteDone(rewriteVersionFromJson(r.map, fallbackLanguage: fallbackLanguage)));
          }
        } else {
          final res = await _api.openStream('POST', 'ai/rewrite', body: _body(request));
          if (token.cancelled) return;
          final type = res.headers['content-type'] ?? '';
          if (type.contains('text/event-stream')) {
            await _readSse(res.stream, out, token, fallbackLanguage, () => finished, (s) => sub = s);
          } else {
            final body = await res.stream.bytesToString();
            final j = jsonDecode(body.isEmpty ? '{}' : body);
            final data = j is Map && j['data'] is Map ? j['data'] as Map : (j is Map ? j : const {});
            if (!token.cancelled && !finished) {
              out.add(
                RewriteDone(rewriteVersionFromJson(Map<String, dynamic>.from(data), fallbackLanguage: fallbackLanguage)),
              );
            }
          }
        }
        timer.cancel();
        finish();
      } on AiRewriteException catch (e) {
        timer.cancel();
        finish(e);
      } on WdApiException catch (e) {
        timer.cancel();
        finish(aiExceptionFrom(e));
      } catch (_) {
        timer.cancel();
        finish(const AiRewriteException('server'));
      }
    }();

    return out.stream;
  }

  /// SSE frames: `event: delta|done|error` + `data: {json}`, blank line ends
  /// a frame.
  Future<void> _readSse(
    Stream<List<int>> bytes,
    StreamController<RewriteEvent> out,
    RewriteCancelToken token,
    String fallbackLanguage,
    bool Function() isFinished,
    void Function(StreamSubscription<String>) onSub,
  ) {
    var event = 'message';
    final data = StringBuffer();
    var done = false;
    final completer = Completer<void>();

    void dispatch() {
      if (data.isEmpty) return;
      final raw = data.toString();
      data.clear();
      final Map<String, dynamic> j;
      try {
        final d = jsonDecode(raw);
        j = d is Map ? Map<String, dynamic>.from(d) : {'text': '$d'};
      } on FormatException {
        if ((event == 'delta' || event == 'message') && !isFinished()) out.add(RewriteDelta(raw));
        return;
      }
      switch (event) {
        case 'done':
          done = true;
          if (!isFinished()) out.add(RewriteDone(rewriteVersionFromJson(j, fallbackLanguage: fallbackLanguage)));
        case 'error':
          throw aiExceptionFromCode((j['code'] as String?) ?? 'server', retryAfter: (j['retry_after'] as num?)?.toInt());
        default:
          final t = j['text'] ?? j['delta'];
          if (t is String && !isFinished()) out.add(RewriteDelta(t));
      }
      event = 'message';
    }

    final sub = bytes
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (token.cancelled || completer.isCompleted) return;
            try {
              if (line.isEmpty) {
                dispatch();
                if (done) completer.complete();
              } else if (line.startsWith('event:')) {
                event = line.substring(6).trim();
              } else if (line.startsWith('data:')) {
                if (data.isNotEmpty) data.write('\n');
                data.write(line.substring(5).trimLeft());
              }
            } catch (e) {
              completer.completeError(e);
            }
          },
          onError: (Object e) {
            if (!completer.isCompleted) completer.completeError(const AiRewriteException('network'));
          },
          onDone: () {
            if (completer.isCompleted) return;
            try {
              dispatch();
            } catch (e) {
              completer.completeError(e);
              return;
            }
            if (!done && !token.cancelled) {
              completer.completeError(const AiRewriteException('server'));
            } else {
              completer.complete();
            }
          },
          cancelOnError: true,
        );
    onSub(sub);
    // A cancelled token stops listening; resolve so the caller can finish.
    token.onCancel(() {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  @override
  Future<List<RewriteStyle>> teamStyles() async {
    try {
      final r = await _api.get('ai/rewrite-styles');
      return [
        for (final s in r.list)
          if (s['custom'] == true && s['id'] != null)
            RewriteStyle.custom(id: '${s['id']}', label: '${s['name'] ?? s['id']}'),
      ];
    } catch (_) {
      return const [];
    }
  }
}

/// Maps a `/mobile/v1` error to the rewrite sheet's error codes.
AiRewriteException aiExceptionFrom(WdApiException e) {
  if (e.isNetwork) return const AiRewriteException('network');
  if (e.code == 'validation_failed') {
    return AiRewriteException(e.details.containsKey('text') ? 'too_long' : 'content_blocked', statusCode: e.status);
  }
  return aiExceptionFromCode(e.code, retryAfter: e.retryAfter?.inSeconds, statusCode: e.status);
}

AiRewriteException aiExceptionFromCode(String code, {int? retryAfter, int statusCode = 0}) => switch (code) {
  'plan_limit' => AiRewriteException('plan_limit', statusCode: statusCode),
  'module_unavailable' || 'role_forbidden' || 'ai_disabled' => AiRewriteException('ai_disabled', statusCode: statusCode),
  'rate_limited' => AiRewriteException('rate_limited', statusCode: statusCode, retryAfter: retryAfter ?? 30),
  'too_long' || 'content_blocked' => AiRewriteException(code, statusCode: statusCode),
  'network' => const AiRewriteException('network'),
  _ => AiRewriteException('server', statusCode: statusCode),
};

// ---- Sample mode ---------------------------------------------------------------------

/// Offline stand-in that streams believable rewrites word by word.
///
/// Demo triggers anywhere in the source text: `#500` server error, `#429`
/// rate limit (8s), `#402` plan limit, `#422` blocked content, `#timeout`.
class SimulatedAiRewriteApi implements AiRewriteApi {
  SimulatedAiRewriteApi({required this.contactFirstName});

  final String? Function(String conversationId) contactFirstName;
  int _seq = 0;

  static const _firstTokenDelay = Duration(milliseconds: 650);
  static const _tokenDelay = Duration(milliseconds: 45);

  @override
  Stream<RewriteEvent> rewrite(RewriteRequest request, RewriteCancelToken token) async* {
    final src = request.sourceText;
    await Future<void>.delayed(_firstTokenDelay);
    if (token.cancelled) return;
    if (src.contains('#timeout')) {
      await Future<void>.delayed(HttpAiRewriteApi.timeout);
      if (!token.cancelled) throw const AiRewriteException('timeout');
      return;
    }
    if (src.contains('#500')) throw const AiRewriteException('server', statusCode: 500);
    if (src.contains('#429')) throw const AiRewriteException('rate_limited', statusCode: 429, retryAfter: 8);
    if (src.contains('#402')) throw const AiRewriteException('plan_limit', statusCode: 402);
    if (src.contains('#422')) throw const AiRewriteException('content_blocked', statusCode: 422);
    if (src.length > RewriteSession.maxSourceChars) {
      throw const AiRewriteException('too_long', statusCode: 422);
    }

    final name = request.mode == 'note' ? null : contactFirstName(request.conversationId);
    final result = _compose(request, name);

    if (request.stream && !result.unchanged) {
      final words = result.text.split(' ');
      for (var i = 0; i < words.length; i++) {
        await Future<void>.delayed(_tokenDelay);
        if (token.cancelled) return;
        yield RewriteDelta(i == 0 ? words[i] : ' ${words[i]}');
      }
    }
    if (token.cancelled) return;
    yield RewriteDone(result);
  }

  RewriteVersion _compose(RewriteRequest r, String? name) {
    final base = _clean(r.sourceText);
    final ar = LanguageDetector.isArabic(base);
    final v = r.variantIndex;
    var insertedName = false;
    var factWarning = false;
    String pick(List<String> options) => options[v % options.length];
    String withName(String withN, String without) {
      if (name == null || name.isEmpty) return without;
      insertedName = true;
      return withN;
    }

    final core = _stripEnd(base);
    String text;
    var language = ar ? 'ar' : 'en';
    switch (r.style) {
      case 'professional':
        text = ar
            ? pick([
                'شكرًا لتواصلك معنا. $core، وسنوافيك بالتحديث في أقرب وقت.',
                'نقدّر تواصلك. $core، ونحن على متابعة مستمرة لطلبك.',
                'عزيزنا العميل، $core. يسعدنا خدمتك دائمًا.',
              ])
            : pick([
                'Thank you for reaching out. $core, and we will update you as soon as possible.',
                'We appreciate your patience. $core, and we are following up closely.',
                'Dear customer, $core. We are always happy to help.',
              ]);
      case 'shorter':
        text = _shorten(base, v);
      case 'friendlier':
        text = ar
            ? withName(
                pick(['أهلًا $name! 😊 $core، ولا تشيل هم.', 'هلا $name 🌷 $core، وأنا معك خطوة بخطوة.']),
                pick(['أهلًا وسهلًا! 😊 $core، ولا تشيل هم.', 'هلا والله 🌷 $core، وأنا معك خطوة بخطوة.']),
              )
            : withName(
                pick(['Hi $name! 😊 $core — happy to help.', 'Hey $name 🙌 $core, I\'ve got you.']),
                pick(['Hi there! 😊 $core — happy to help.', 'Hey 🙌 $core, I\'ve got you.']),
              );
      case 'apology':
        // Adds a timeline the agent didn't write → fact-check warning (§5.5).
        final hasTime = RegExp(r'ساعة|دقيقة|اليوم|غدًا|غدا|hour|minute|today|tomorrow').hasMatch(base);
        factWarning = !hasTime;
        text = ar
            ? withName(
                pick([
                  'نعتذر منك يا $name عن التأخير. $core، وسأرسل لك التحديث خلال ساعة.',
                  'آسفين جدًا يا $name على الإزعاج. $core، وسأتابع معك شخصيًا خلال ساعة.',
                ]),
                pick([
                  'نعتذر منك عن التأخير. $core، وسأرسل لك التحديث خلال ساعة.',
                  'آسفين جدًا على الإزعاج. $core، وسأتابع معك شخصيًا خلال ساعة.',
                ]),
              )
            : withName(
                pick([
                  'I\'m sorry for the delay, $name. $core, and I\'ll send you an update within an hour.',
                  'Apologies for the trouble, $name. $core — I\'ll personally follow up within an hour.',
                ]),
                pick([
                  'I\'m sorry for the delay. $core, and I\'ll send you an update within an hour.',
                  'Apologies for the trouble. $core — I\'ll personally follow up within an hour.',
                ]),
              );
        if (hasTime) text = text.replaceAll(RegExp(r'،? ?(وسأرسل لك التحديث|وسأتابع معك شخصيًا) خلال ساعة'), '');
      case 'fix':
        text = _fix(r.sourceText);
      case 'translate':
        language = r.targetLanguage ?? (ar ? 'en' : 'ar');
        text = language == 'en'
            ? pick([
                'Sorry for the delay — we\'re looking into it now and will update you shortly.',
                'Apologies for the wait. We\'re checking this right away and will get back to you soon.',
              ])
            : pick([
                'نعتذر عن التأخير، نتابع الموضوع الآن وسنعود إليك قريبًا.',
                'شكرًا لصبرك، نراجع طلبك حالًا وسنرد عليك في أقرب وقت.',
              ]);
      case 'formal':
        text = ar
            ? 'السادة الكرام، $core. وتفضلوا بقبول فائق الاحترام والتقدير.'
            : 'Dear valued customer, $core. Kind regards.';
      case 'saudi':
        language = 'ar';
        text = pick(['هلا والله! $core، وأبشر باللي يرضيك.', 'يا هلا، $core، وتامر أمر.']);
      case 'msa':
        language = 'ar';
        text = pick(['نشكر لك تواصلك. $core، ونحن في خدمتك دائمًا.', 'أهلًا بك. $core، ويسرّنا مساعدتك.']);
      case 'greeting':
        text = ar
            ? withName(
                'مرحبًا $name، $core. مع أطيب التحيات، فريق الدعم.',
                'مرحبًا، $core. مع أطيب التحيات، فريق الدعم.',
              )
            : withName(
                'Hello $name, $core. Best regards, the support team.',
                'Hello, $core. Best regards, the support team.',
              );
      case 'bullets':
        final parts = base
            .split(RegExp(r'[،,.؛;]|\s+و(?=\S)|\s+and\s+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        text = parts.length < 2 ? '• $core' : parts.map((p) => '• $p').join('\n');
      case 'sales':
        factWarning = true; // offer not in the source
        text = ar
            ? '$core 🎁 ولا تفوّت عرضنا الحالي: توصيل مجاني للطلبات فوق 200 ريال!'
            : '$core 🎁 Don\'t miss our current offer: free delivery on orders over 200 SAR!';
      case 'simple':
        text = _shorten(base, v + 1);
      default:
        // Workspace custom style.
        text = ar ? '$core 🌿 — فريق وافا' : '$core 🌿 — the Wava team';
    }

    final unchanged = r.style == 'fix' && text == r.sourceText.trim();
    return RewriteVersion(
      id: 'rw_${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      text: unchanged ? r.sourceText.trim() : text,
      language: language,
      insertedName: insertedName,
      factWarning: factWarning,
      unchanged: unchanged,
    );
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'#(500|429|402|422|timeout)'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _stripEnd(String s) => s.replaceAll(RegExp(r'[.!؟?،,\s]+$'), '');

  /// ≤ 60% of the length, cut on a word boundary.
  static String _shorten(String s, int variant) {
    final words = _stripEnd(s).split(' ');
    if (words.length <= 3) return _stripEnd(s);
    final keep = (words.length * (variant.isEven ? 0.6 : 0.5)).floor().clamp(2, words.length);
    return words.take(keep).join(' ');
  }

  static const _typos = {
    'انشاء الله': 'إن شاء الله',
    'ان شاء الله': 'إن شاء الله',
    'لاكن': 'لكن',
    'هاذا': 'هذا',
    'هاذي': 'هذي',
    'إنشاء الله': 'إن شاء الله',
    'مسؤل': 'مسؤول',
  };

  static const _enTypos = {
    'teh': 'the',
    'recieve': 'receive',
    'adress': 'address',
    'pls': 'please',
    'u': 'you',
    'i': 'I',
  };

  static String _fix(String source) {
    var s = source.trim().replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    _typos.forEach((k, v) => s = s.replaceAll(k, v));
    _enTypos.forEach((k, v) => s = s.replaceAll(RegExp('\\b$k\\b'), v));
    s = s.replaceAllMapped(RegExp(r'([!؟?.،,])\1+'), (m) => m.group(1)!);
    s = s.replaceAll(RegExp(r'\s+([،,.!؟?])'), r'$1');
    if (LanguageDetector.isArabic(s)) {
      s = s.replaceAll('?', '؟').replaceAll(',', '،');
    } else if (s.isNotEmpty) {
      s = s[0].toUpperCase() + s.substring(1);
    }
    if (s.isNotEmpty && !RegExp(r'[.!؟?…\p{So}]$', unicode: true).hasMatch(s)) s = '$s.';
    return s;
  }

  @override
  Future<List<RewriteStyle>> teamStyles() async => const [
    RewriteStyle.custom(id: 'ts_brand_voice', label: 'بأسلوب متجرنا'),
  ];
}
