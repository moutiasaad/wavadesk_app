import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kb_api.dart';
import '../data/kb_editor_api.dart';
import '../domain/kb_entry.dart';
import 'kb_answer_editor_controller.dart';
import 'knowledge_controller.dart';

/// Web limits: 16 MB per file, images ≤ 5 MB.
abstract final class KbMediaLimits {
  static const maxBytes = 16 * 1024 * 1024;
  static const maxImageBytes = 5 * 1024 * 1024;
}

enum KbMediaRejection { type, tooBig, imageTooBig }

/// One attachment row: already on the server ([media]) or picked locally
/// ([file]) and waiting / uploading.
@immutable
class KbMediaItem {
  const KbMediaItem({
    required this.key,
    this.media,
    this.file,
    this.kind = KbMediaKind.image,
    this.sendMode = KbMediaSendMode.withText,
    this.progress,
    this.failed = false,
    this.error,
  });

  final String key;
  final KbMedia? media;
  final KbPickedFile? file;
  final KbMediaKind kind;
  final KbMediaSendMode sendMode;

  /// 0–1 while uploading, null otherwise.
  final double? progress;
  final bool failed;

  /// Server reason for a rejected upload (422 `upload_rejected`: type / size).
  final String? error;

  bool get uploaded => media != null;
  bool get uploading => progress != null;
  bool get queued => !uploaded && !uploading && !failed;
  String get title => media?.title ?? file?.name ?? '';

  KbMediaItem copyWith({KbMedia? media, KbMediaSendMode? sendMode, double? Function()? progress, bool? failed, String? Function()? error}) => KbMediaItem(
        key: key,
        media: media ?? this.media,
        file: file,
        kind: kind,
        sendMode: sendMode ?? this.sendMode,
        progress: progress != null ? progress() : this.progress,
        failed: failed ?? this.failed,
        error: error != null ? error() : this.error,
      );
}

@immutable
class KbMediaState {
  const KbMediaState({this.items = const [], this.entryId, this.seeded = false, this.planBlocked = false});

  final List<KbMediaItem> items;

  /// null in create mode until the entry is saved.
  final String? entryId;
  final bool seeded;

  /// 402 `plan_limit` seen: show the upgrade hint instead of the add button.
  final bool planBlocked;

  bool get hasQueued => items.any((i) => !i.uploaded);
  bool get busy => items.any((i) => i.uploading);

  KbMediaState copyWith({List<KbMediaItem>? items, String? entryId, bool? seeded, bool? planBlocked}) => KbMediaState(
        items: items ?? this.items,
        entryId: entryId ?? this.entryId,
        seeded: seeded ?? this.seeded,
        planBlocked: planBlocked ?? this.planBlocked,
      );
}

final kbMediaControllerProvider =
    NotifierProvider.autoDispose.family<KbMediaController, KbMediaState, KbeArgs>(KbMediaController.new);

/// The editor's "المرفقات" (images / voice notes sent with the answer, like
/// the web form). Existing entries upload right away; in create mode files
/// are queued and uploaded by [flush] once the entry exists.
class KbMediaController extends AutoDisposeFamilyNotifier<KbMediaState, KbeArgs> {
  int _seq = 0;
  KbEditorApi get _api => ref.read(kbEditorApiProvider);

  @override
  KbMediaState build(KbeArgs args) {
    // Seed from the loaded entry / draft once (edit + draft review).
    ref.listen(kbAnswerEditorControllerProvider(args).select((s) => s.base), (_, base) {
      if (base != null && !state.seeded) _seed(base);
    });
    final base = ref.read(kbAnswerEditorControllerProvider(args)).base;
    final editId = args.mode == KbeMode.edit ? args.id : null;
    if (base != null) return _seeded(base);
    return KbMediaState(entryId: editId, seeded: args.mode == KbeMode.create || args.mode == KbeMode.fromMessage || args.mode == KbeMode.fromUnanswered);
  }

  KbMediaState _seeded(KbQa base) => KbMediaState(
        entryId: base.id,
        seeded: true,
        items: [for (final m in base.media) KbMediaItem(key: m.id, media: m, kind: m.kind, sendMode: m.sendMode)],
      );

  void _seed(KbQa base) => state = _seeded(base);

  /// Validates and adds a picked file; uploads now when the entry exists.
  KbMediaRejection? add(KbPickedFile file) {
    final voice = kbIsAudio(file);
    if (!voice && !kbIsImage(file)) return KbMediaRejection.type;
    if (file.sizeBytes > KbMediaLimits.maxBytes) return KbMediaRejection.tooBig;
    if (!voice && file.sizeBytes > KbMediaLimits.maxImageBytes) return KbMediaRejection.imageTooBig;
    final item = KbMediaItem(
      key: 'local_${_seq++}',
      file: file,
      kind: voice ? KbMediaKind.voice : KbMediaKind.image,
      // Web default: voice goes on its own, images with the text.
      sendMode: voice ? KbMediaSendMode.fileOnly : KbMediaSendMode.withText,
    );
    state = state.copyWith(items: [...state.items, item]);
    final id = state.entryId;
    if (id != null) unawaited(_upload(id, item.key));
    return null;
  }

  Future<bool> _upload(String entryId, String key) async {
    final item = _find(key);
    if (item == null || item.file == null || item.uploaded) return item?.uploaded ?? false;
    _put(key, (i) => i.copyWith(progress: () => 0, failed: false));
    try {
      final media = await _api.uploadMedia(
        entryId,
        item.file!,
        sendMode: item.sendMode,
        onProgress: (p) => _put(key, (i) => i.copyWith(progress: () => p)),
      );
      _put(key, (i) => i.copyWith(media: media, progress: () => null));
      _bumpListCount(entryId);
      return true;
    } on KbEditorApiException catch (e) {
      if (e.isPlanLimit) {
        // Plan lacks attachments: drop the pending rows, show the hint.
        state = state.copyWith(planBlocked: true, items: [for (final i in state.items) if (i.uploaded) i]);
        return false;
      }
      final reason = e.fields['file']?.firstOrNull ?? (e.status == 422 ? e.message : null);
      _put(key, (i) => i.copyWith(progress: () => null, failed: true, error: () => reason));
      return false;
    } catch (_) {
      _put(key, (i) => i.copyWith(progress: () => null, failed: true));
      return false;
    }
  }

  /// Retry a failed upload (entry must exist).
  void retry(String key) {
    final id = state.entryId;
    if (id != null) unawaited(_upload(id, key));
  }

  /// Uploads everything still local once [entryId] exists (after create /
  /// approve). Returns how many failed.
  Future<int> flush(String entryId) async {
    state = state.copyWith(entryId: entryId);
    var failed = 0;
    for (final i in [...state.items]) {
      if (i.uploaded) continue;
      if (!await _upload(entryId, i.key)) failed++;
    }
    return failed;
  }

  Future<void> setSendMode(String key, KbMediaSendMode mode) async {
    final item = _find(key);
    if (item == null || item.sendMode == mode) return;
    _put(key, (i) => i.copyWith(sendMode: mode));
    final media = item.media;
    if (media == null) return;
    try {
      final next = await _api.updateMedia(media.id, sendMode: mode);
      _put(key, (i) => i.copyWith(media: next));
    } catch (_) {
      _put(key, (i) => i.copyWith(sendMode: item.sendMode)); // revert
      rethrow;
    }
  }

  /// Removes the row (and the server copy when uploaded).
  Future<void> remove(String key) async {
    final item = _find(key);
    if (item == null) return;
    state = state.copyWith(items: [for (final i in state.items) if (i.key != key) i]);
    final media = item.media;
    if (media == null) return;
    try {
      await _api.deleteMedia(media.id);
      final id = state.entryId;
      if (id != null) _bumpListCount(id);
    } catch (_) {
      // Put it back where it was.
      state = state.copyWith(items: [...state.items, item]);
      rethrow;
    }
  }

  void _bumpListCount(String entryId) {
    final n = state.items.where((i) => i.uploaded).length;
    ref.read(knowledgeControllerProvider.notifier).setMediaCount(entryId, n);
  }

  KbMediaItem? _find(String key) => state.items.where((i) => i.key == key).firstOrNull;

  void _put(String key, KbMediaItem Function(KbMediaItem) f) {
    state = state.copyWith(items: [for (final i in state.items) i.key == key ? f(i) : i]);
  }
}
