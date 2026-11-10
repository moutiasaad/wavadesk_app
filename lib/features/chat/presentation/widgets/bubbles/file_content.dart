import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// File (Chat spec §4.4): 40 tile (`surfaceVariant`, type icon) + name (1
/// line) + size/type caption + download icon; progress ring while
/// downloading (simulated — no real files in sample data).
class FileContent extends StatefulWidget {
  const FileContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  State<FileContent> createState() => _FileContentState();
}

class _FileContentState extends State<FileContent> {
  double? _progress;
  bool _done = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _download() {
    if (_progress != null || _done) return;
    setState(() => _progress = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      final next = (_progress ?? 0) + 0.1;
      if (next >= 1) {
        t.cancel();
        setState(() {
          _progress = null;
          _done = true;
        });
        AppSnackbar.show(context, message: context.l10n.bubble_downloaded, kind: SnackKind.success);
      } else {
        setState(() => _progress = next);
      }
    });
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
            child: Icon(AppIcons.file, size: 20, color: c.primary),
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
                  child: _progress != null
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 2.5,
                            color: widget.foreground,
                            backgroundColor: widget.foreground.withValues(alpha: 0.2),
                          ),
                        )
                      : Icon(_done ? AppIcons.check : AppIcons.download, size: 20, color: widget.foreground),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
