import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/media_url_provider.dart';

/// File (Chat spec §4.4): 40 tile (`surfaceVariant`, type icon) + name (1
/// line) + size/type caption + download icon. Tap opens the file from its
/// signed link in the phone's viewer / browser.
class FileContent extends ConsumerStatefulWidget {
  const FileContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  ConsumerState<FileContent> createState() => _FileContentState();
}

class _FileContentState extends ConsumerState<FileContent> {
  bool _opening = false;
  bool _done = false;

  Future<void> _download() async {
    if (_opening) return;
    final l = context.l10n;
    final id = widget.message.id;
    if (!hasServerMedia(id)) {
      AppSnackbar.show(context, message: l.bubble_file_sending);
      return;
    }
    setState(() => _opening = true);
    try {
      final url = await ref.read(mediaUrlProvider(id).future);
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) throw StateError('no app');
      setState(() => _done = true);
    } catch (_) {
      ref.invalidate(mediaUrlProvider(id));
      if (mounted) AppSnackbar.show(context, message: l.bubble_file_unavailable, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final m = widget.message;
    final name = m.fileName ?? context.l10n.media_file;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: AppIcon(AppIcons.file, color: c.primary),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: t.bodyMedium.copyWith(color: widget.foreground, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [?m.fileSize, if (ext.isNotEmpty) ext].join(' · '),
                  style: t.caption.copyWith(color: widget.foreground.withValues(alpha: 0.65)),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: context.l10n.bubble_download,
            excludeSemantics: true,
            child: InkResponse(
              onTap: _download,
              radius: 22,
              child: SizedBox.square(
                dimension: 40,
                child: Center(
                  child: _opening
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: widget.foreground,
                            backgroundColor: widget.foreground.withValues(alpha: 0.2),
                          ),
                        )
                      : AppIcon(_done ? AppIcons.check : AppIcons.download, color: widget.foreground),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
