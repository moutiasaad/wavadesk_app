import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/language_detector.dart';

/// "ردّك الأصلي" label row + the original text box (Rewrite spec §5.2,
/// §5.3). Read-only by default (4 lines + "المزيد"); "تعديل" turns it into a
/// multiline field.
class RewriteOriginalBox extends StatefulWidget {
  const RewriteOriginalBox({
    super.key,
    required this.source,
    required this.editing,
    required this.selectionMode,
    required this.onEdit,
    required this.onChanged,
    this.editEnabled = true,
  });

  final String source;
  final bool editing;

  /// Opened from a text selection → "سيتم استبدال الجزء المحدد فقط".
  final bool selectionMode;
  final VoidCallback onEdit;
  final ValueChanged<String> onChanged;
  final bool editEnabled;

  @override
  State<RewriteOriginalBox> createState() => _RewriteOriginalBoxState();
}

class _RewriteOriginalBoxState extends State<RewriteOriginalBox> {
  static const _collapsedLines = 4;
  bool _expanded = false;
  late final TextEditingController _controller = TextEditingController(text: widget.source);

  @override
  void didUpdateWidget(RewriteOriginalBox old) {
    super.didUpdateWidget(old);
    if (widget.editing && !old.editing) {
      _controller.value = TextEditingValue(
        text: widget.source,
        selection: TextSelection.collapsed(offset: widget.source.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextDirection _direction(String text) => LanguageDetector.isArabic(text) ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final style = t.bodyMedium.copyWith(color: c.textSecondary);

    final label = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.rw_original,
              style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
            ),
          ),
          if (!widget.editing)
            Semantics(
              button: true,
              label: l.rw_edit,
              excludeSemantics: true,
              child: InkWell(
                onTap: widget.editEnabled ? widget.onEdit : null,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32, minWidth: AppSpacing.minTouch),
                  child: Opacity(
                    opacity: widget.editEnabled ? 1 : 0.4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(AppIcons.edit, size: AppIconSize.sm, color: c.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(l.rw_edit, style: t.buttonSmall.copyWith(color: c.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final Widget box;
    if (widget.editing) {
      box = AppTextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textDirection: _direction(_controller.text),
        style: t.bodyMedium.copyWith(color: c.textPrimary),
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {}); // direction follows the text
        },
      );
    } else {
      box = LayoutBuilder(
        builder: (context, constraints) {
          final dir = _direction(widget.source);
          final painter = TextPainter(
            text: TextSpan(text: widget.source, style: style),
            textDirection: dir,
            maxLines: _collapsedLines,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth - 24);
          final overflows = painter.didExceedMaxLines;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: AppMotion.fast,
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    widget.source,
                    style: style,
                    textDirection: dir,
                    maxLines: _expanded ? null : _collapsedLines,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                ),
                if (overflows || _expanded)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          _expanded ? MaterialLocalizations.of(context).collapsedIconTapHint : l.rw_more,
                          style: t.buttonSmall.copyWith(color: c.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        box,
        if (widget.selectionMode)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l.rw_selection_hint, style: t.caption.copyWith(color: c.textTertiary)),
          ),
      ],
    );
  }
}
