import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import 'file_content.dart';
import 'text_content.dart';

/// Email (Chat spec §4.4): subject `h6` + body (simplified rich text, max 12
/// lines, "عرض الكل" expands) + attachments list.
class EmailContent extends StatefulWidget {
  const EmailContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  State<EmailContent> createState() => _EmailContentState();
}

class _EmailContentState extends State<EmailContent> {
  bool _expanded = false;

  /// Strips tags from HTML bodies → plain paragraphs.
  static String _plain(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final m = widget.message;
    final body = _plain(m.text);
    final long = '\n'.allMatches(body).length > 11 || body.length > 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m.emailSubject != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(m.emailSubject!, style: t.h6.copyWith(color: widget.foreground)),
          ),
        if (body.isNotEmpty) TextContent(text: body, color: widget.foreground, maxLines: _expanded ? null : 12),
        if (long)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: widget.foreground,
              textStyle: t.buttonSmall,
              minimumSize: const Size(48, 36),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? context.l10n.bubble_show_less : context.l10n.bubble_show_all),
          ),
        if (m.fileName != null) ...[
          Divider(height: 12, color: widget.foreground.withValues(alpha: 0.15)),
          FileContent(message: m, foreground: widget.foreground),
        ],
      ],
    );
  }
}
