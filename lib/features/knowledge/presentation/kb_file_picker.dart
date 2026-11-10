import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../data/kb_api.dart';

/// System file picker (file_picker) → [KbPickedFile] with bytes loaded.
/// Returns null when the user cancels or the platform refuses.
Future<KbPickedFile?> _pick(FileType type, {List<String>? extensions}) async {
  try {
    final r = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? extensions : null,
      withData: true,
    );
    final f = r?.files.firstOrNull;
    if (f == null) return null;
    final bytes = f.bytes ?? Uint8List(0);
    return KbPickedFile(name: f.name, sizeBytes: f.size, mime: kbMimeOf(f.name), bytes: bytes);
  } catch (e) {
    debugPrint('KB file picker failed: $e');
    return null;
  }
}

/// Documents for the knowledge base (spec 12 §6.2).
Future<KbPickedFile?> pickKbDocument() => _pick(FileType.custom, extensions: const ['pdf', 'docx', 'txt', 'md']);

/// The web's JSON import file.
Future<KbPickedFile?> pickKbJson() => _pick(FileType.custom, extensions: const ['json']);

/// An image attached to an answer.
Future<KbPickedFile?> pickKbImage() => _pick(FileType.image);

/// A voice note / audio file attached to an answer.
Future<KbPickedFile?> pickKbAudio() => _pick(FileType.custom, extensions: const ['mp3', 'm4a', 'aac', 'ogg', 'opus', 'wav', 'amr']);

/// Mime from the extension (the picker gives none on Android).
String kbMimeOf(String name) => switch (name.split('.').last.toLowerCase()) {
      'pdf' => 'application/pdf',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'md' => 'text/markdown',
      'json' => 'application/json',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' || 'oga' || 'opus' => 'audio/ogg',
      'wav' => 'audio/wav',
      'amr' => 'audio/amr',
      _ => 'application/octet-stream',
    };
