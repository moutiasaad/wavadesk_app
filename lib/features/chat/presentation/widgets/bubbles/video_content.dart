import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/media_url_provider.dart';
import 'image_content.dart';

/// Video (Chat spec §4.4): thumbnail + 44 play circle + duration chip.
/// Play opens the signed link in the phone's video player.
class VideoContent extends ConsumerStatefulWidget {
  const VideoContent({super.key, required this.message});

  final Message message;

  @override
  ConsumerState<VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends ConsumerState<VideoContent> {
  bool _opening = false;

  Future<void> _play() async {
    final l = context.l10n;
    final id = widget.message.id;
    if (!hasServerMedia(id)) {
      AppSnackbar.show(context, message: l.bubble_file_sending);
      return;
    }
    setState(() => _opening = true);
    try {
      final url = await ref.read(mediaUrlProvider(id).future);
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) throw StateError('no app');
    } catch (_) {
      ref.invalidate(mediaUrlProvider(id));
      if (mounted) AppSnackbar.show(context, message: l.bubble_video_unavailable, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final l = context.l10n;
    final d = message.mediaDuration ?? Duration.zero;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: 240,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPlaceholder(seed: message.id, icon: null),
              Center(
                child: Semantics(
                  button: true,
                  label: l.bubble_play_video,
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _opening ? null : _play,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: _opening
                              ? const AppSpinner(size: 20, delayed: false, color: Colors.white)
                              : const AppIcon(AppIcons.play, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: 8,
                end: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    AppFormat.clock(d),
                    style: context.text.chatTimestamp.copyWith(color: Colors.white),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
