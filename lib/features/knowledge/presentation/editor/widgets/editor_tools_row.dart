import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../domain/kb_entry.dart';

/// Tag · ✦ حسّن الصياغة · أضف رابطًا (Add Answer spec §4.6). Wraps at
/// large text sizes.
class EditorToolsRow extends StatelessWidget {
  const EditorToolsRow({
    super.key,
    required this.tags,
    required this.onTag,
    required this.onImprove,
    required this.onAddLink,
    this.enabled = true,
  });

  final List<KbTag> tags;
  final VoidCallback onTag;

  /// null when there's no answer to improve or AI is unavailable.
  final VoidCallback? onImprove;
  final VoidCallback onAddLink;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final tagLabel = tags.isEmpty ? l.kbe_tag : (tags.length == 1 ? tags.first.name : '${tags.first.name} +${tags.length - 1}');
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _ToolChip(icon: AppIcons.tag, label: tagLabel, onTap: enabled ? onTag : null),
        _ToolChip(
          icon: AppIcons.sparkle,
          label: l.kbe_improve,
          onTap: enabled ? onImprove : null,
          background: c.primaryContainer,
          border: c.primaryContainerBorder,
          foreground: c.primary,
        ),
        _ToolChip(icon: AppIcons.link, label: l.kbe_add_link, onTap: enabled ? onAddLink : null),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label, this.onTap, this.background, this.border, this.foreground});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? background;
  final Color? border;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final fg = foreground ?? c.textSecondary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          color: background ?? c.surface,
          shape: StadiumBorder(side: BorderSide(color: border ?? c.border)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            // 28 visual, 48 touch via the padding around the row.
            child: Container(
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: t.chipLabel.copyWith(color: fg, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
