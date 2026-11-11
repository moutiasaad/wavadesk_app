import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/models/models.dart';

/// A file picked for the chat, bytes loaded.
@immutable
class PickedMedia {
  const PickedMedia({required this.name, required this.bytes, required this.mime, required this.kind});

  final String name;
  final Uint8List bytes;
  final String mime;
  final MessageKind kind;

  int get size => bytes.length;
}

/// Why a picked file cannot be sent.
enum PickRejection { type, size }

/// The server's limits (config/mobile.php `uploads.types`).
abstract final class ChatMediaRules {
  static const documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'zip'];
  static const audioExtensions = ['mp3', 'm4a', 'aac', 'ogg', 'opus', 'wav'];

  static int maxBytes(MessageKind kind) => switch (kind) {
        MessageKind.image => 5 * 1024 * 1024,
        MessageKind.video || MessageKind.voice => 16 * 1024 * 1024,
        _ => 10 * 1024 * 1024,
      };

  static String mimeOf(String name) => switch (name.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        '3gp' => 'video/3gpp',
        'mp3' => 'audio/mpeg',
        'm4a' => 'audio/mp4',
        'aac' => 'audio/aac',
        'ogg' || 'opus' => 'audio/ogg',
        'wav' => 'audio/wav',
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls' => 'application/vnd.ms-excel',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'ppt' => 'application/vnd.ms-powerpoint',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'txt' => 'text/plain',
        'csv' => 'text/csv',
        'zip' => 'application/zip',
        _ => 'application/octet-stream',
      };

  static MessageKind? kindOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (mimeOf(name)) {
      final m when m.startsWith('image/') => MessageKind.image,
      final m when m.startsWith('video/') => MessageKind.video,
      final m when m.startsWith('audio/') => MessageKind.voice,
      _ when documentExtensions.contains(ext) => MessageKind.file,
      _ => null,
    };
  }

  static PickRejection? check(PickedMedia f) {
    if (kindOf(f.name) == null) return PickRejection.type;
    if (f.size > maxBytes(f.kind)) return PickRejection.size;
    return null;
  }
}

final _images = ImagePicker();

/// Photos are resized so they stay under the server's 5 MB image limit.
const _maxWidth = 2560.0;
const _quality = 85;

Future<PickedMedia?> _fromXFile(XFile x) async {
  final name = x.name.isNotEmpty ? x.name : x.path.split('/').last;
  final kind = ChatMediaRules.kindOf(name);
  if (kind == null) return PickedMedia(name: name, bytes: await x.readAsBytes(), mime: 'application/octet-stream', kind: MessageKind.file);
  return PickedMedia(name: name, bytes: await x.readAsBytes(), mime: ChatMediaRules.mimeOf(name), kind: kind);
}

/// Gallery: several photos and videos at once.
Future<List<PickedMedia>> pickGalleryMedia() async {
  try {
    final files = await _images.pickMultipleMedia(maxWidth: _maxWidth, imageQuality: _quality, limit: 10);
    return [for (final f in files) ?await _fromXFile(f)];
  } catch (e) {
    debugPrint('gallery picker failed: $e');
    return const [];
  }
}

/// Camera: one photo.
Future<PickedMedia?> pickCameraPhoto() async {
  try {
    final x = await _images.pickImage(source: ImageSource.camera, maxWidth: _maxWidth, imageQuality: _quality);
    return x == null ? null : await _fromXFile(x);
  } catch (e) {
    debugPrint('camera failed: $e');
    return null;
  }
}

/// Documents and audio files (several at once).
Future<List<PickedMedia>> pickDocuments() async {
  try {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [...ChatMediaRules.documentExtensions, ...ChatMediaRules.audioExtensions],
      allowMultiple: true,
      withData: true,
    );
    return [
      for (final f in r?.files ?? const <PlatformFile>[])
        if (f.bytes != null)
          PickedMedia(
            name: f.name,
            bytes: f.bytes!,
            mime: ChatMediaRules.mimeOf(f.name),
            kind: ChatMediaRules.kindOf(f.name) ?? MessageKind.file,
          ),
    ];
  } catch (e) {
    debugPrint('document picker failed: $e');
    return const [];
  }
}
