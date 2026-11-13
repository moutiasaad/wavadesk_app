import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/analytics.dart';
import '../data/kb_api.dart';
import '../domain/kb_entry.dart';
import 'knowledge_controller.dart';
import '../../auth/application/auth_session.dart';

enum KbUploadPhase { uploading, processing, ready, failed }

enum KbFileRejection { type, size }

@immutable
class KbUploadJob {
  const KbUploadJob({
    required this.key,
    required this.file,
    this.phase = KbUploadPhase.uploading,
    this.progress = 0,
    this.entryId,
    this.facts = 0,
    this.error,
    this.result,
  });

  final String key;
  final KbPickedFile file;
  final KbUploadPhase phase;

  /// 0–1 while uploading.
  final double progress;
  final String? entryId;

  /// Extracted chunks once ready ("استخرجنا {n} معلومة").
  final int facts;
  final Object? error;

  /// The server's view once processing ended (drafts, error code, rights).
  final KbFile? result;

  KbUploadJob copyWith({KbUploadPhase? phase, double? progress, String? entryId, int? facts, Object? error, KbFile? result}) =>
      KbUploadJob(
        key: key,
        file: file,
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        entryId: entryId ?? this.entryId,
        facts: facts ?? this.facts,
        error: error ?? this.error,
        result: result ?? this.result,
      );
}

@immutable
class KbUploadState {
  const KbUploadState({this.jobs = const {}, this.readyTick = 0, this.lastReady});

  final Map<String, KbUploadJob> jobs;

  /// Bumped when a file finishes processing (ready or failed); [lastReady]
  /// is that job.
  final int readyTick;
  final KbUploadJob? lastReady;
}

final kbUploadControllerProvider = NotifierProvider<KbUploadController, KbUploadState>(KbUploadController.new);

/// Background upload + processing poll (Knowledge Base spec §6.2). Survives
/// the upload sheet closing; the KB list shows the processing badge.
class KbUploadController extends Notifier<KbUploadState> {
  static const maxBytes = 10 * 1024 * 1024;
  static const allowed = {'pdf', 'docx', 'txt', 'md'};

  final _polls = <String, Timer>{};

  @override
  KbUploadState build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    ref.onDispose(() {
      for (final t in _polls.values) {
        t.cancel();
      }
      _polls.clear();
    });
    return const KbUploadState();
  }

  static KbFileRejection? validate(KbPickedFile f) {
    final ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';
    if (!allowed.contains(ext)) return KbFileRejection.type;
    if (f.sizeBytes > maxBytes) return KbFileRejection.size;
    return null;
  }

  static String sizeBucket(int bytes) => switch (bytes) {
        < 1024 * 1024 => '<1MB',
        < 5 * 1024 * 1024 => '1-5MB',
        _ => '5-10MB',
      };

  void _put(KbUploadJob j) => state = KbUploadState(jobs: {...state.jobs, j.key: j}, readyTick: state.readyTick, lastReady: state.lastReady);

  /// Starts an upload; returns the job key to watch.
  String start(KbPickedFile file, {String? replaceId}) {
    final key = 'up_${DateTime.now().microsecondsSinceEpoch}';
    _put(KbUploadJob(key: key, file: file));
    unawaited(_run(key, file, replaceId));
    return key;
  }

  Future<void> _run(String key, KbPickedFile file, String? replaceId) async {
    final api = ref.read(kbApiProvider);
    try {
      final id = await api.uploadFile(file, replaceId: replaceId, onProgress: (p) {
        final j = state.jobs[key];
        if (j != null) _put(j.copyWith(progress: p));
      });
      _put(state.jobs[key]!.copyWith(phase: KbUploadPhase.processing, progress: 1, entryId: id));
      _poll(key, id);
    } catch (e) {
      _put(state.jobs[key]!.copyWith(phase: KbUploadPhase.failed, error: e));
      Analytics.log('kb_file_upload', {'mime': file.mime, 'size_bucket': sizeBucket(file.sizeBytes), 'result': 'error'});
    }
  }

  void _poll(String key, String id) {
    _polls[key]?.cancel();
    _polls[key] = Timer(const Duration(seconds: 3), () async {
      try {
        final f = await ref.read(kbApiProvider).file(id);
        final j = state.jobs[key];
        if (j == null) return;
        if (f.status == KbStatus.processing) return _poll(key, id);
        final ok = f.status != KbStatus.failed;
        final done = j.copyWith(phase: ok ? KbUploadPhase.ready : KbUploadPhase.failed, facts: f.draftsCount, result: f);
        // readyTick also moves on failure: [lastReady] says which (its phase).
        state = KbUploadState(jobs: {...state.jobs, key: done}, readyTick: state.readyTick + 1, lastReady: done);
        Analytics.log('kb_file_upload', {'mime': j.file.mime, 'size_bucket': sizeBucket(j.file.sizeBytes), 'result': ok ? 'ready' : 'failed'});
        ref.read(knowledgeControllerProvider.notifier).refresh();
      } catch (_) {
        _poll(key, id);
      }
    });
  }

  void forget(String key) {
    _polls.remove(key)?.cancel();
    state = KbUploadState(jobs: {...state.jobs}..remove(key), readyTick: state.readyTick, lastReady: state.lastReady);
  }
}
