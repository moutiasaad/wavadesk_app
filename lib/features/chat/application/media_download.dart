import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/local_media.dart';
import 'media_url_provider.dart';

/// The media of a message as bytes: from memory when this phone sent it,
/// otherwise from its signed link, reporting 0–1 progress when the size
/// is known.
Future<Uint8List> downloadMessageMedia(WidgetRef ref, String messageId, {void Function(double progress)? onProgress}) async {
  final local = LocalMedia.of(messageId);
  if (local != null) return local;
  final url = await ref.read(mediaUrlProvider(messageId).future);
  final client = http.Client();
  try {
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) {
      // A stale or refused link: the next try asks for a fresh one.
      ref.invalidate(mediaUrlProvider(messageId));
      throw http.ClientException('HTTP ${res.statusCode}', Uri.parse(url));
    }
    final total = res.contentLength ?? 0;
    final out = BytesBuilder(copy: false);
    await for (final chunk in res.stream) {
      out.add(chunk);
      if (total > 0) onProgress?.call((out.length / total).clamp(0, 1).toDouble());
    }
    return out.takeBytes();
  } finally {
    client.close();
  }
}

/// System "save as" (Android picks a folder, iOS the Files app). True when
/// the file was written.
Future<bool> saveToDevice(String fileName, Uint8List bytes) async {
  final path = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
  return path != null;
}
