import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import 'image_content.dart';

/// Video (Chat spec §4.4): thumbnail + 44 play circle + duration chip.
class VideoContent extends StatelessWidget {
  const VideoContent({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
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
                      onTap: () => AppSnackbar.show(context, message: l.bubble_video_unavailable),
                      child: const SizedBox.square(
                        dimension: 44,
                        child: AppIcon(AppIcons.play, color: Colors.white),
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
