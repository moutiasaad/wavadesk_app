import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../ai_agent/presentation/sheets/channels_sheet.dart' show aiChannelLabel;

/// Channels an answer can be limited to (§4.9).
const kbEditorChannels = ['whatsapp', 'web', 'messenger'];

/// "خيارات متقدمة" (Add Answer spec §4.9), collapsed by default.
class EditorAdvancedSection extends StatefulWidget {
  const EditorAdvancedSection({
    super.key,
    required this.enabled,
    required this.channels,
    required this.expiresAt,
    required this.verbatim,
    required this.handoffAfter,
    required this.internalNotes,
    required this.onEnabled,
    required this.onChannels,
    required this.onExpiresAt,
    required this.onVerbatim,
    required this.onHandoffAfter,
    required this.onInternalNotes,
    this.dateError,
    this.editable = true,
    this.initiallyExpanded = false,
  });

  final bool enabled;
  final List<String>? channels;
  final DateTime? expiresAt;
  final bool verbatim;
  final bool handoffAfter;
  final String internalNotes;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<List<String>?> onChannels;
  final ValueChanged<DateTime?> onExpiresAt;
  final ValueChanged<bool> onVerbatim;
  final ValueChanged<bool> onHandoffAfter;
  final ValueChanged<String> onInternalNotes;
  final String? dateError;
  final bool editable;
  final bool initiallyExpanded;

  @override
  State<EditorAdvancedSection> createState() => _EditorAdvancedSectionState();
}

class _EditorAdvancedSectionState extends State<EditorAdvancedSection> {
  late bool _open = widget.initiallyExpanded;
  late final _notes = TextEditingController(text: widget.internalNotes);

  @override
  void didUpdateWidget(EditorAdvancedSection old) {
    super.didUpdateWidget(old);
    if (widget.internalNotes != _notes.text && widget.internalNotes != old.internalNotes) _notes.text = widget.internalNotes;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _toggleChannel(String ch) {
    final current = widget.channels ?? kbEditorChannels;
    final next = current.contains(ch) ? ([...current]..remove(ch)) : [...current, ch];
    if (next.isEmpty) return; // At least one channel.
    widget.onChannels(kbEditorChannels.every(next.contains) ? null : [for (final c in kbEditorChannels) if (next.contains(c)) c]);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.expiresAt != null && widget.expiresAt!.isAfter(tomorrow) ? widget.expiresAt! : tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) widget.onExpiresAt(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final reduced = AppMotion.reduced(context);
    final selected = widget.channels ?? kbEditorChannels;

    Widget switchRow(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) => InkWell(
          onTap: widget.editable ? () => onChanged(!value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.listTitle),
                      if (subtitle != null) Text(subtitle, style: t.bodySmall.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                AppSwitch(value: value, semanticLabel: title, onChanged: widget.editable ? onChanged : null),
              ],
            ),
          ),
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: c.divider),
        switchRow(l.kbe_enabled, widget.enabled, widget.onEnabled),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, AppSpacing.sm, 14, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.kbe_channels, style: t.listTitle),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final ch in kbEditorChannels)
                    AppFilterChip(
                      label: aiChannelLabel(l, ch),
                      selected: selected.contains(ch),
                      onTap: widget.editable ? () => _toggleChannel(ch) : null,
                    ),
                ],
              ),
              if (widget.channels == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(l.kbe_channels_all, style: t.caption.copyWith(color: c.textTertiary)),
                ),
            ],
          ),
        ),
        InkWell(
          onTap: widget.editable ? _pickDate : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.kbe_expires, style: t.listTitle),
                      Text(
                        widget.expiresAt == null
                            ? l.kbe_expires_none
                            : MaterialLocalizations.of(context).formatMediumDate(widget.expiresAt!),
                        style: t.bodySmall.copyWith(color: widget.dateError != null ? c.textError : c.textSecondary),
                      ),
                      if (widget.dateError != null)
                        Text(widget.dateError!, style: t.bodySmall.copyWith(color: c.textError)),
                    ],
                  ),
                ),
                if (widget.expiresAt != null && widget.editable)
                  IconButton(
                    onPressed: () => widget.onExpiresAt(null),
                    tooltip: l.kbe_expires_clear,
                    iconSize: 16,
                    icon: AppIcon(AppIcons.close, color: c.textSecondary),
                  )
                else
                  AppIcon(AppIcons.clock, size: AppIconSize.sm, color: c.textTertiary),
              ],
            ),
          ),
        ),
        switchRow(l.kbe_verbatim, widget.verbatim, widget.onVerbatim, subtitle: l.kbe_verbatim_sub),
        switchRow(l.kbe_handoff_after, widget.handoffAfter, widget.onHandoffAfter),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, AppSpacing.sm, 14, 14),
          child: AppTextField(
            label: l.kbe_internal_notes,
            hint: l.kbe_internal_notes_ph,
            controller: _notes,
            onChanged: widget.onInternalNotes,
            readOnly: !widget.editable,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.kbe_advanced, style: t.listTitle)),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: reduced ? Duration.zero : AppMotion.normal,
                        child: AppIcon(AppIcons.chevronDown, size: AppIconSize.sm, color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduced ? Duration.zero : AppMotion.normal,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: _open ? body : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
