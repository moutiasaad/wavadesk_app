import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:uuid/uuid.dart';

/// Build-time configuration (`--dart-define=…`), see
/// whatsapp-saas/docs/mobile/FLUTTER_CLIENT_NOTES.md §1.
///
/// `WAVADESK_API_URL` is the origin only (e.g. `http://10.0.2.2:8000`);
/// `/mobile/v1` is appended per call. A `--dart-define` wins; otherwise
/// [loadApiConfig] reads the bundled `assets/config/api.json`, so the app
/// works whichever IDE run configuration launched it.
String apiBaseUrl = const String.fromEnvironment('WAVADESK_API_URL');
String apiKey = const String.fromEnvironment('WAVADESK_API_KEY');
String bootstrapSecret = const String.fromEnvironment('WAVADESK_BOOTSTRAP_SECRET');

/// Fills the API settings from `assets/config/api.json` (same keys as
/// `dart_defines/*.json`) when they were not passed at build time.
Future<void> loadApiConfig() async {
  if (apiBaseUrl.isNotEmpty && apiKey.isNotEmpty) return;
  try {
    final raw = jsonDecode(await rootBundle.loadString('assets/config/api.json'));
    if (raw is! Map) return;
    String pick(String key, String current) => current.isNotEmpty ? current : '${raw[key] ?? ''}'.trim();
    apiBaseUrl = pick('WAVADESK_API_URL', apiBaseUrl).replaceFirst(RegExp(r'/+$'), '');
    apiKey = pick('WAVADESK_API_KEY', apiKey);
    bootstrapSecret = pick('WAVADESK_BOOTSTRAP_SECRET', bootstrapSecret);
  } catch (_) {
    // No bundled config: main() shows the "API not configured" screen.
  }
}


/// Error answer from `/mobile/v1` (`{"error": {code, message, details, request_id}}`)
/// or a transport failure (`status == 0`, `code == 'network'`).
class WdApiException implements Exception {
  const WdApiException({
    required this.status,
    required this.code,
    this.message,
    this.details = const {},
    this.requestId,
    this.retryAfter,
  });

  final int status;
  final String code;

  /// Already localised for `Accept-Language`; safe to show to the user.
  final String? message;
  final Map<String, dynamic> details;
  final String? requestId;
  final Duration? retryAfter;

  bool get isNetwork => status == 0;

  @override
  String toString() => 'WdApiException($status $code, request_id=$requestId)';
}

/// A successful answer: `data` + `meta` of the envelope.
class WdResponse {
  const WdResponse(this.status, this.data, this.meta, {this.etag});

  final int status;
  final dynamic data;
  final Map<String, dynamic> meta;

  /// `ETag` header, when the endpoint sends one (dashboard).
  final String? etag;

  /// 304 to a conditional GET: keep the cached copy.
  bool get notModified => status == 304;

  Map<String, dynamic> get map => data is Map ? Map<String, dynamic>.from(data as Map) : const {};

  List<Map<String, dynamic>> get list =>
      data is List ? (data as List).whereType<Map>().map(Map<String, dynamic>.from).toList() : const [];

  String? get nextCursor => meta['next_cursor'] as String?;
}

/// What the client needs from the signed-in session. Implemented by
/// `AuthRepository` so tokens live in one place (secure storage).
abstract interface class WdSessionStore {
  String get deviceId;
  String? get accessToken;
  String? get refreshToken;
  DateTime? get accessExpiresAt;
  String? get signingSecret;

  /// Both tokens rotate on every refresh; the signing secret does not.
  Future<void> saveRefreshedTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessExpiresAt,
  });
}

/// Signed HTTP client for the Laravel mobile API (`/mobile/v1`).
///
/// Every request carries the API key, device id, timestamp, nonce and an
/// HMAC signature (bootstrap secret before login, device signing secret
/// after). Handles the single-flight token refresh, clock skew and nonce
/// replays, and turns error envelopes into [WdApiException].
class WdApi {
  WdApi({
    required String baseUrl,
    required this.apiKey,
    required this.bootstrapSecret,
    required this.appVersion,
    http.Client? client,
  })  : _origin = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  final Uri _origin;
  final http.Client _client;
  final String apiKey;
  final String bootstrapSecret;
  final String appVersion;

  late WdSessionStore session;

  /// `ar` | `en` | `fr`; sent as `Accept-Language` so `error.message` is
  /// localised. Kept in sync with the app language (WavadeskApp).
  String locale = supportedLocale(PlatformDispatcher.instance.locale.languageCode);

  /// The app's languages; anything else falls back to Arabic.
  static String supportedLocale(String code) => const {'en', 'fr'}.contains(code) ? code : 'ar';

  /// Emits the error code when the server ends the session
  /// (`token_reused`, `invalid_refresh_token`, …). The auth layer signs out.
  final _sessionEnded = StreamController<String>.broadcast();
  Stream<String> get sessionEnded => _sessionEnded.stream;

  static const _uuid = Uuid();
  static const _timeout = Duration(seconds: 20);
  /// Endpoints that need no access token.
  static final _publicPath = RegExp(r'/mobile/v1/(health|media/download/)');

  static const _hardLogoutCodes = {
    'unauthenticated',
    'invalid_refresh_token',
    'token_reused',
    'device_mismatch',
    'account_disabled',
  };

  int _clockOffset = 0;
  Completer<void>? _refreshing;

  static String newIdempotencyKey() => _uuid.v4();

  Uri uri(String path, [Map<String, Object?>? query]) {
    final q = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    final p = path.startsWith('/') ? path.substring(1) : path;
    return _origin.replace(path: '/mobile/v1/$p', queryParameters: q.isEmpty ? null : q);
  }

  // ---- public verbs -------------------------------------------------------

  /// [ifNoneMatch] makes a conditional GET; a 304 comes back as
  /// [WdResponse.notModified] instead of an error.
  Future<WdResponse> get(String path, {Map<String, Object?>? query, bool bootstrap = false, String? ifNoneMatch}) =>
      _send('GET', uri(path, query), bootstrap: bootstrap, ifNoneMatch: ifNoneMatch);

  Future<WdResponse> post(String path, {Object? body, String? idempotencyKey, bool bootstrap = false}) =>
      _send('POST', uri(path), body: body, idempotencyKey: idempotencyKey, bootstrap: bootstrap);

  Future<WdResponse> put(String path, {Object? body, String? idempotencyKey}) =>
      _send('PUT', uri(path), body: body, idempotencyKey: idempotencyKey);

  Future<WdResponse> patch(String path, {Object? body, String? idempotencyKey}) =>
      _send('PATCH', uri(path), body: body, idempotencyKey: idempotencyKey);

  Future<WdResponse> delete(String path, {Map<String, Object?>? query, Object? body, String? idempotencyKey}) =>
      _send('DELETE', uri(path, query), body: body, idempotencyKey: idempotencyKey);

  /// `POST /uploads` (multipart). The signature hashes the file bytes.
  Future<WdResponse> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    String? contentType,
    Map<String, String> fields = const {},
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey();
    return _withRetries(() async {
      await ensureFreshToken();
      final target = uri(path);
      final req = http.MultipartRequest('POST', target)
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: contentType == null ? null : _mediaType(contentType),
        ));
      req.headers.addAll(_headers('POST', target, bytes, bootstrap: false, idempotencyKey: key));
      return _decode(await http.Response.fromStream(await _client.send(req).timeout(const Duration(seconds: 90))));
    });
  }

  /// Raw streamed request (SSE). The caller reads `response.stream`.
  /// Non-2xx answers are decoded and thrown as [WdApiException].
  Future<http.StreamedResponse> openStream(String method, String path, {Object? body, String? idempotencyKey}) async {
    final key = idempotencyKey ?? (method == 'GET' ? null : newIdempotencyKey());
    var retried = false;
    while (true) {
      await ensureFreshToken();
      final target = uri(path);
      final bytes = body == null ? <int>[] : utf8.encode(jsonEncode(body));
      final req = http.Request(method, target)..bodyBytes = bytes;
      req.headers.addAll(_headers(method, target, bytes, bootstrap: false, idempotencyKey: key));
      req.headers['Accept'] = 'text/event-stream';
      if (body != null) req.headers['Content-Type'] = 'application/json';
      final http.StreamedResponse res;
      try {
        res = await _client.send(req).timeout(_timeout);
      } on Exception catch (e) {
        throw _network(e);
      }
      if (res.statusCode < 300) return res;
      final err = _error(await http.Response.fromStream(res));
      if (!retried && await _recover(err)) {
        retried = true;
        continue;
      }
      throw err;
    }
  }

  // ---- token refresh ------------------------------------------------------

  /// Single-flight refresh 60 s before the access token expires
  /// (FLUTTER_CLIENT_NOTES §5). A refresh token works once.
  Future<void> ensureFreshToken({bool force = false}) async {
    final exp = session.accessExpiresAt;
    if (!force && (exp == null || exp.difference(DateTime.now().toUtc()) > const Duration(seconds: 60))) return;
    if (session.refreshToken == null) return;
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<void>();
    try {
      final r = await _send('POST', uri('auth/refresh'),
          body: {'refresh_token': session.refreshToken}, bootstrap: true, noRetry: true);
      final d = r.map;
      await session.saveRefreshedTokens(
        accessToken: d['access_token'] as String,
        refreshToken: d['refresh_token'] as String,
        accessExpiresAt: _expiry(d),
      );
      c.complete();
    } on WdApiException catch (e) {
      if (_hardLogoutCodes.contains(e.code)) _sessionEnded.add(e.code);
      c.completeError(e);
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  static DateTime _expiry(Map<String, dynamic> d) =>
      DateTime.tryParse(d['access_expires_at'] as String? ?? '')?.toUtc() ??
      DateTime.now().toUtc().add(Duration(seconds: (d['expires_in'] as num?)?.toInt() ?? 900));

  /// Parses `access_expires_at` / `expires_in` of a login or refresh answer.
  static DateTime expiryOf(Map<String, dynamic> d) => _expiry(d);

  // ---- internals ----------------------------------------------------------

  Future<WdResponse> _send(
    String method,
    Uri target, {
    Object? body,
    String? idempotencyKey,
    bool bootstrap = false,
    bool noRetry = false,
    String? ifNoneMatch,
  }) {
    // One key per user intent: reused on every automatic retry below.
    final key = method == 'GET' ? null : (idempotencyKey ?? newIdempotencyKey());
    final bytes = body == null ? <int>[] : utf8.encode(jsonEncode(body));
    Future<WdResponse> once() async {
      if (!bootstrap) await ensureFreshToken();
      // Signed out (login screen, after a logout): a provider still alive
      // must not hit the server without a token — fail locally instead.
      if (!bootstrap && session.accessToken == null && !_publicPath.hasMatch(target.path)) {
        throw const WdApiException(status: 401, code: 'signed_out');
      }
      final headers = _headers(method, target, bytes, bootstrap: bootstrap, idempotencyKey: key);
      if (body != null) headers['Content-Type'] = 'application/json';
      if (ifNoneMatch != null) headers['If-None-Match'] = ifNoneMatch;
      final req = http.Request(method, target)
        ..headers.addAll(headers)
        ..bodyBytes = bytes;
      final http.Response res;
      try {
        res = await http.Response.fromStream(await _client.send(req).timeout(_timeout)).timeout(_timeout);
      } on Exception catch (e) {
        throw _network(e);
      }
      return _decode(res);
    }

    return noRetry ? once() : _withRetries(once);
  }

  /// Replays once after a recoverable 401 (expired token, clock skew, nonce).
  Future<WdResponse> _withRetries(Future<WdResponse> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      if (await _recover(e)) return call();
      rethrow;
    }
  }

  Future<bool> _recover(WdApiException e) async {
    if (e.status != 401) return false;
    switch (e.code) {
      case 'token_expired':
        await ensureFreshToken(force: true);
        return true;
      case 'stale_request':
        final st = e.details['server_time'];
        final server = st is num
            ? st.toInt()
            : (DateTime.tryParse('$st')?.millisecondsSinceEpoch ?? 0) ~/ 1000;
        if (server > 0) _clockOffset = server - DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return true;
      case 'replayed_request':
        return true;
      default:
        if (_hardLogoutCodes.contains(e.code)) _sessionEnded.add(e.code);
        return false;
    }
  }

  Map<String, String> _headers(String method, Uri target, List<int> bodyBytes,
      {required bool bootstrap, String? idempotencyKey}) {
    final ts = '${DateTime.now().millisecondsSinceEpoch ~/ 1000 + _clockOffset}';
    final nonce = _uuid.v4();
    final path = target.hasQuery ? '${target.path}?${target.query}' : target.path;
    final canonical = '${method.toUpperCase()}\n$path\n$ts\n$nonce\n${sha256.convert(bodyBytes)}';
    final secret = bootstrap ? bootstrapSecret : (session.signingSecret ?? '');
    final sig = base64.encode(Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(canonical)).bytes);
    final token = session.accessToken;
    return {
      'X-Api-Key': apiKey,
      'X-App-Version': appVersion,
      'X-Device-Id': session.deviceId,
      'X-Timestamp': ts,
      'X-Nonce': nonce,
      'X-Signature': sig,
      'X-Request-Id': _uuid.v4(),
      'Accept': 'application/json',
      'Accept-Language': locale,
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      if (!bootstrap && token != null) 'Authorization': 'Bearer $token',
    };
  }

  WdResponse _decode(http.Response res) {
    final etag = res.headers['etag'];
    if (res.statusCode == 304) return WdResponse(304, null, const {}, etag: etag);
    if (res.statusCode >= 300) throw _error(res);
    if (res.statusCode == 204 || res.bodyBytes.isEmpty) return WdResponse(res.statusCode, null, const {}, etag: etag);
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    if (json is Map) {
      return WdResponse(
        res.statusCode,
        json['data'],
        json['meta'] is Map ? Map<String, dynamic>.from(json['meta'] as Map) : const {},
        etag: etag,
      );
    }
    return WdResponse(res.statusCode, json, const {}, etag: etag);
  }

  WdApiException _error(http.Response res) {
    Map<String, dynamic> err = const {};
    try {
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json is Map && json['error'] is Map) err = Map<String, dynamic>.from(json['error'] as Map);
    } catch (_) {}
    final retry = int.tryParse(res.headers['retry-after'] ?? '') ??
        (err['details'] is Map ? ((err['details'] as Map)['retry_after'] as num?)?.toInt() : null);
    if (kDebugMode) debugPrint('[wd] ${res.request?.method} ${res.request?.url.path} → ${res.statusCode} ${err['code']}');
    return WdApiException(
      status: res.statusCode,
      code: err['code'] as String? ?? (res.statusCode >= 500 ? 'server_error' : 'http_${res.statusCode}'),
      message: err['message'] as String?,
      details: err['details'] is Map ? Map<String, dynamic>.from(err['details'] as Map) : const {},
      requestId: err['request_id'] as String?,
      retryAfter: retry == null ? null : Duration(seconds: retry),
    );
  }

  static WdApiException _network(Object e) {
    if (kDebugMode) debugPrint('[wd] network error: $e');
    return const WdApiException(status: 0, code: 'network');
  }

  static MediaType? _mediaType(String type) {
    try {
      return MediaType.parse(type);
    } catch (_) {
      return null;
    }
  }
}

/// `SocketException` etc. are wrapped as `code == 'network'`.
bool isNetworkError(Object e) => e is WdApiException && e.isNetwork || e is SocketException;
