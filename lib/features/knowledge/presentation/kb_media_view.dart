import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/kb_entry.dart';
import 'files/kb_file_upload_sheet.dart' show kbFileSize;

/// "صورة · 1.2 ميجابايت" / "تسجيل صوتي · 0:12".
String kbMediaMeta(AppLocalizations l, KbMedia m) {
  if (m.kind == KbMediaKind.voice) {
    final d = m.durationSeconds;
    final len = d == null ? null : '${d ~/ 60}:${(d % 60).toString().padLeft(2, '0')}';
    return [l.kbe_media_voice, ?len].join(' · ');
  }
  return [l.kbe_media_image, if (m.sizeBytes > 0) kbFileSize(l, m.sizeBytes)].join(' · ');
}

/// Bytes of an image just picked (not uploaded yet); else the URL is used.
Uint8List? _bytesFor(KbMedia? media, List<int>? local) =>
    local != null && local.isNotEmpty ? Uint8List.fromList(local) : null;

/// Square preview: the image itself, or a voice tile.
class KbMediaThumb extends StatelessWidget {
  const KbMediaThumb({super.key, required this.kind, this.media, this.localBytes, this.size = 44});

  final KbMediaKind kind;
  final KbMedia? media;
  final List<int>? localBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tile(IconData icon) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: AppIcon(icon, dp: size * 0.45, color: c.primary),
        );
    if (kind == KbMediaKind.voice) return tile(AppIcons.voice);
    final bytes = _bytesFor(media, localBytes);
    final url = media?.url;
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes, fit: BoxFit.cover, width: size, height: size, errorBuilder: (_, _, _) => tile(AppIcons.image));
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(url, fit: BoxFit.cover, width: size, height: size, errorBuilder: (_, _, _) => tile(AppIcons.image));
    } else {
      return tile(AppIcons.image);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: image);
  }
}

/// Image full-screen (pinch to zoom); voice opens the file in the system
/// player (the chat voice player is simulated, it can't play a URL).
Future<void> openKbMedia(BuildContext context, KbMedia m) async {
  final l = context.l10n;
  if (m.kind == KbMediaKind.voice) {
    final url = m.url;
    final ok = url != null && url.isNotEmpty && await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) AppSnackbar.show(context, message: l.kbe_media_failed, kind: SnackKind.error);
    return;
  }
  final bytes = _bytesFor(m, null);
  final url = m.url;
  if (bytes == null && (url == null || url.isEmpty)) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
          child: InteractiveViewer(
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, _, _) => const AppIcon(AppIcons.image, size: AppIconSize.xl, color: Colors.white54))
                : Image.network(url!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const AppIcon(AppIcons.image, size: AppIconSize.xl, color: Colors.white54)),
          ),
        ),
      ),
    ),
  );
}

/// Read-only attachments card for the Q&A detail screen.
class KbMediaCard extends StatelessWidget {
  const KbMediaCard({super.key, required this.media});

  final List<KbMedia> media;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.kb_media_title, style: t.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          for (final m in media)
            Semantics(
              button: true,
              label: '${m.title}، ${kbMediaMeta(l, m)}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => openKbMedia(context, m),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      KbMediaThumb(kind: m.kind, media: m),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: t.listTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              [kbMediaMeta(l, m), m.sendMode == KbMediaSendMode.withText ? l.kbe_media_with_text : l.kbe_media_file_only].join(' · '),
                              style: t.bodySmall.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      AppIcon(m.kind == KbMediaKind.voice ? AppIcons.play : AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
