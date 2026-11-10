import 'dart:async';

import '../../../core/api/wd_api.dart';

/// Upload progress event: `progress` 0–1, then `uploadId` when done.
class UploadProgress {
  const UploadProgress(this.progress, {this.uploadId});

  final double progress;
  final String? uploadId;
  bool get done => uploadId != null;
}

/// `POST /mobile/v1/uploads` (multipart) → `upl_…` id to send as
/// `media_upload_id` (Chat spec §8).
abstract interface class UploadsApi {
  Stream<UploadProgress> upload({required String fileName, required List<int> bytes, required String mime});
}

class HttpUploadsApi implements UploadsApi {
  HttpUploadsApi(this._api);

  final WdApi _api;

  /// Server `kind`: image | audio | video | document.
  static String kindFor(String mime) {
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('audio/')) return 'audio';
    if (mime.startsWith('video/')) return 'video';
    return 'document';
  }

  @override
  Stream<UploadProgress> upload({required String fileName, required List<int> bytes, required String mime}) async* {
    // The signed multipart call has no byte-level progress: show a start
    // tick, then done. The body hash covers the file bytes (README §B).
    yield const UploadProgress(0.1);
    final r = await _api.upload(
      'uploads',
      bytes: bytes,
      filename: fileName,
      contentType: mime,
      fields: {'kind': kindFor(mime)},
    );
    yield UploadProgress(1, uploadId: '${r.map['id']}');
  }
}

/// Sample mode: fake progress over ~1.2s.
class SimulatedUploadsApi implements UploadsApi {
  @override
  Stream<UploadProgress> upload({required String fileName, required List<int> bytes, required String mime}) async* {
    for (var i = 1; i <= 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      yield UploadProgress(i / 6 * 0.99);
    }
    yield UploadProgress(1, uploadId: 'upload-${DateTime.now().millisecondsSinceEpoch}');
  }
}
