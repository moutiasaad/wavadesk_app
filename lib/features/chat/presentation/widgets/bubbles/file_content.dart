import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/media_download.dart';
import '../../../application/media_url_provider.dart';

/// File (Chat spec §4.4): 40 tile (`surfaceVariant`, type icon) + name (1
/// line) + size/type caption + download icon. Tap the file to open it in
/// the phone's viewer; the download icon saves it on the phone (real
/// progress ring, then ✓).
class FileContent extends ConsumerStatefulWidget {
  const FileContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  ConsumerState<FileContent> createState() => _FileContentState();
}

class _FileContentState extends ConsumerState<FileContent> {
  bool _opening = false;

  /// Null = idle; 0–1 while downloading (0 also when the size is unknown).
  double? _progress;
  bool _saved = false;

  String get _name => widget.message.fileName ?? 'file';

  /// False → a message explains why (still sending, or not on the server).
  bool _canFetch() {
    final l = context.l10n;
    final m = widget.message;
    if (!hasServerMedia(m.id)) {
      AppSnackbar.show(context, message: l.bubble_file_sending);
      return false;
    }
    if (!m.mediaAvailable) {
      AppSnackbar.show(context, message: l.bubble_file_unavailable);
      return false;
    }
    return true;
  }

  Future<void> _open() async {
    if (_opening || !_canFetch()) return;
    final l = context.l10n;
    final id = widget.message.id;
    setState(() => _opening = true);
    try {
      final url = await ref.read(mediaUrlProvider(id).future);
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) throw StateError('no app');
    } catch (_) {
      ref.invalidate(mediaUrlProvider(id));
      if (mounted) AppSnackbar.show(context, message: l.bubble_file_unavailable, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _save() async {
    if (_progress != null || !_canFetch()) return;
    final l = context.l10n;
    setState(() => _progress = 0);
    try {
      final bytes = await downloadMessageMedia(ref, widget.message.id, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!mounted) return;
      setState(() => _progress = null);
      if (await saveToDevice(_name, bytes)) {
        if (!mounted) return;
        setState(() => _saved = true);
        AppSnackbar.show(context, message: l.bubble_saved(_name), kind: SnackKind.success);
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.bubble_save_failed, kind: SnackKind.error);
    } finally {
      if (mounted && _progress != null) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final m = widget.message;
    final name = m.fileName ?? l.media_file;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : '';
    final progress = _progress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Semantics(
              button: true,
              label: '${l.bubble_open_file} $name',
              excludeSemantics: true,
              child: InkWell(
                onTap: _open,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
                      alignment: Alignment.center,
                      child: _opening
                          ? AppSpinner(size: 18, delayed: false, color: c.primary)
                          : AppIcon(AppIcons.file, color: c.primary),
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: l.bubble_download,
            excludeSemantics: true,
            child: InkResponse(
              onTap: _save,
              radius: 22,
              child: SizedBox.square(
                dimension: 40,
                child: Center(
                  child: progress != null
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2.5,
                            color: widget.foreground,
                            backgroundColor: widget.foreground.withValues(alpha: 0.2),
                          ),
                        )
                      : AppIcon(_saved ? AppIcons.check : AppIcons.download, color: widget.foreground),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
