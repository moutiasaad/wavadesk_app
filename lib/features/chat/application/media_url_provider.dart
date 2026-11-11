import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_api.dart';

/// Only messages the server knows (`msg_…`) have media to fetch.
bool hasServerMedia(String messageId) => messageId.startsWith('msg_');

/// 5-minute signed link of a message's media (`GET media/{msg_…}/url`),
/// kept for 4 minutes so scrolling back does not ask again. Fails (404
/// `media_not_available`) for media we do not host.
final mediaUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, messageId) async {
  final url = await ref.read(chatApiProvider).mediaUrl(messageId);
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 4), link.close);
  ref.onDispose(timer.cancel);
  return url;
});
