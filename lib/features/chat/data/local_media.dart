import 'dart:typed_data';

/// Bytes of media this device sent, keyed by message id (the local
/// client id, then the server's msg_ id once it answers). Own images show
/// at once and never download what we already have. Memory only; the
/// newest [_max] entries are kept.
abstract final class LocalMedia {
  static const _max = 40;
  static final _bytes = <String, Uint8List>{};

  static Uint8List? of(String messageId) => _bytes[messageId];

  static void put(String messageId, Uint8List bytes) {
    _bytes.remove(messageId);
    _bytes[messageId] = bytes;
    while (_bytes.length > _max) {
      _bytes.remove(_bytes.keys.first);
    }
  }

  /// The server copy of a sent message reuses the local bytes.
  static void alias(String fromId, String toId) {
    final b = _bytes[fromId];
    if (b != null) put(toId, b);
  }

  static void clear() => _bytes.clear();
}
