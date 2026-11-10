import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/kb_editor_validation.dart';
import '../../../domain/phrasing_normalizer.dart';

/// "صيغ أخرى يسأل بها العملاء" (Add Answer spec §4.4): neutral chips with
/// inline edit, "+ أضف صيغة" inline field, dashed AI ghost chips.
class AltPhrasingsEditor extends StatefulWidget {
  const AltPhrasingsEditor({
    super.key,
    required this.alts,
    required this.ghosts,
    required this.shakeTick,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onAcceptGhost,
    required this.onDismissGhost,
    this.enabled = true,
  });

  final List<String> alts;
  final List<String> ghosts;
  final int shakeTick;

  /// Returns false when a phrasing was rejected (duplicate / too long).
  final bool Function(List<String>) onAdd;
  final bool Function(int, String) onEdit;
  final ValueChanged<int> onRemove;
  final ValueChanged<String> onAcceptGhost;
  final ValueChanged<String> onDismissGhost;
  final bool enabled;

  @override
  State<AltPhrasingsEditor> createState() => _AltPhrasingsEditorState();
}

class _AltPhrasingsEditorState extends State<AltPhrasingsEditor> with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  final _input = TextEditingController();
  final _inputFocus = FocusNode(debugLabel: 'kbe-alt-input');

  /// -1 = adding a new phrasing; ≥0 = editing that chip; null = closed.
  int? _editing;

  /// Long-press reveals ✕ on every chip (always on tablets).
  bool _deleteMode = false;

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() {
      if (!_inputFocus.hasFocus && _editing != null) _commit(close: true);
    });
  }

  @override
  void didUpdateWidget(AltPhrasingsEditor old) {
    super.didUpdateWidget(old);
    if (old.shakeTick != widget.shakeTick) {
      if (!AppMotion.reduced(context)) _shake.forward(from: 0);
      AppSnackbar.show(context, message: _lastRejectMessage(), kind: SnackKind.error);
    }
  }

  String _lastRejectMessage() {
    final l = context.l10n;
    return widget.alts.length >= KbEditorValidation.maxPhrasings ? l.kbe_alt_limit : l.kbe_alt_exists;
  }

  @override
  void dispose() {
    _shake.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _open(int index) {
    setState(() {
      _editing = index;
      _input.text = index >= 0 ? widget.alts[index] : '';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _inputFocus.requestFocus());
  }

  void _cancel() => setState(() {
        _editing = null;
        _input.clear();
      });

  /// Enter / ، / , commit; on blur the field closes.
  void _commit({bool close = false}) {
    final editing = _editing;
    if (editing == null) return;
    final raw = _input.text;
    if (editing >= 0) {
      final ok = widget.onEdit(editing, raw);
      if (ok || close) _cancel();
      return;
    }
    final items = PhrasingNormalizer.split(raw);
    if (items.isNotEmpty) widget.onAdd(items);
    _input.clear();
    if (close || widget.alts.length + items.length >= KbEditorValidation.maxPhrasings) {
      _cancel();
    } else {
      _inputFocus.requestFocus();
    }
  }

  void _onInputChanged(String v) {
    if (v.contains('،') || v.contains(',')) _commit();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final showDelete = _deleteMode || tablet;
    final canAdd = widget.alts.length < KbEditorValidation.maxPhrasings;

    final children = <Widget>[
      for (var i = 0; i < widget.alts.length; i++)
        if (_editing == i)
          _InlineInput(key: const ValueKey('edit'), controller: _input, focusNode: _inputFocus, onChanged: _onInputChanged, onSubmit: _commit, onCancel: _cancel)
        else
          _PopIn(
            key: ValueKey('alt-${widget.alts[i]}'),
            child: _AltChip(
              text: widget.alts[i],
              showDelete: showDelete,
              enabled: widget.enabled,
              onTap: () => _open(i),
              onLongPress: () {
                HapticFeedback.selectionClick();
                setState(() => _deleteMode = !_deleteMode);
              },
              onDelete: () => widget.onRemove(i),
            ),
          ),
      for (final g in widget.ghosts)
        _PopIn(
          key: ValueKey('ghost-$g'),
          child: _GhostChip(
            text: g,
            onTap: widget.enabled ? () => widget.onAcceptGhost(g) : null,
            onLongPress: widget.enabled ? () => widget.onDismissGhost(g) : null,
          ),
        ),
      if (_editing == -1)
        _InlineInput(key: const ValueKey('add'), controller: _input, focusNode: _inputFocus, onChanged: _onInputChanged, onSubmit: _commit, onCancel: _cancel)
      else if (canAdd && widget.enabled)
        _AddChip(label: l.kbe_add_alt, onTap: () => _open(-1)),
    ];

    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        final v = _shake.value;
        final dx = v == 0 || v == 1 ? 0.0 : math.sin(v * math.pi * 6) * 5 * (1 - v);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: children),
    );
  }
}

/// Scale 0.8→1 + fade 150ms on add (§12).
class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.scale(scale: 0.8 + 0.2 * v, child: c)),
      child: child,
    );
  }
}

class _AltChip extends StatelessWidget {
  const _AltChip({
    required this.text,
    required this.showDelete,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  final String text;
  final bool showDelete;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.kbe_a11y_alt(text),
      customSemanticsActions: enabled ? {CustomSemanticsAction(label: l.kbe_a11y_alt_delete): onDelete} : null,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: Container(
            height: 32,
            constraints: const BoxConstraints(maxWidth: 280),
            padding: EdgeInsetsDirectional.only(start: AppSpacing.md, end: showDelete ? AppSpacing.xs : AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(text, style: t.chipLabel.copyWith(color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (showDelete && enabled)
                  InkResponse(
                    onTap: onDelete,
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(AppIcons.close, size: 12, color: c.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AI suggestion: dashed `primaryContainerBorder`, sparkle 11. Tap adds,
/// long-press dismisses.
class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.text, this.onTap, this.onLongPress});

  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      label: context.l10n.kbe_a11y_ghost(text),
      excludeSemantics: true,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: CustomPaint(
          painter: _DashedStadiumPainter(color: c.primaryContainerBorder),
          child: Container(
            height: 32,
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.sparkle, size: 11, color: c.primary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(text, style: t.chipLabel.copyWith(color: c.onPrimaryContainer), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  _DashedStadiumPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)).deflate(0.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in (Path()..addRRect(r)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadiumPainter old) => old.color != color;
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      child: Material(
        color: c.primaryContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            child: Text(label, style: t.chipLabel.copyWith(color: c.onPrimaryContainer)),
          ),
        ),
      ),
    );
  }
}

/// h32 pill field that replaces a chip while adding / editing.
class _InlineInput extends StatelessWidget {
  const _InlineInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
      child: Container(
        height: 32,
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: ShapeDecoration(
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.primary, width: 1.5)),
        ),
        child: IntrinsicWidth(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            maxLength: KbEditorValidation.phrasingMax,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit(),
            textInputAction: TextInputAction.done,
            style: t.chipLabel.copyWith(color: c.textPrimary),
            cursorColor: c.primary,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
    );
  }
}
