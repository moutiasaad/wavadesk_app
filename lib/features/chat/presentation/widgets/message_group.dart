import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/messages_controller.dart';
import '../../domain/conversation_detail.dart';
import '../../domain/message_grouping.dart';
import 'bubbles/message_bubble.dart';
import 'message_actions_menu.dart';

/// One message row inside a sender group (Chat spec §4.3): group spacing,
/// swipe-to-reply, press scale, long-press menu, highlight pulse and the
/// enter animation.
class MessageRow extends ConsumerStatefulWidget {
  const MessageRow({
    super.key,
    required this.conversationId,
    required this.item,
    required this.detail,
    required this.maxWidth,
    required this.onQuoteTap,
    this.highlighted = false,
    this.animateIn = false,
    this.readOnly = false,
    this.allowTranscribe = false,
  });

  final String conversationId;
  final MessageItem item;
  final ConversationDetail detail;
  final double maxWidth;
  final void Function(String messageId) onQuoteTap;
  final bool highlighted;
  final bool animateIn;
  final bool readOnly;

  /// Keeps "تحويل لنص" available even when [readOnly] (pre-claim).
  final bool allowTranscribe;

  @override
  ConsumerState<MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends ConsumerState<MessageRow> with TickerProviderStateMixin {
  final _bubbleKey = GlobalKey();
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: widget.animateIn ? 0 : 1,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _pulseValue = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
  ]).animate(_pulse);
  Timer? _staticHighlight;
  bool _staticOn = false;

  bool _pressed = false;

  Message get _m => widget.item.message;

  @override
  void initState() {
    super.initState();
    if (widget.animateIn) _enter.forward();
    if (widget.highlighted) WidgetsBinding.instance.addPostFrameCallback((_) => _startHighlight());
  }

  @override
  void didUpdateWidget(MessageRow old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !old.highlighted) _startHighlight();
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    _staticHighlight?.cancel();
    super.dispose();
  }

  void _startHighlight() {
    if (!mounted) return;
    if (AppMotion.reduced(context)) {
      // Static highlight 1.5s under reduce motion (§11).
      setState(() => _staticOn = true);
      _staticHighlight?.cancel();
      _staticHighlight = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _staticOn = false);
      });
    } else {
      _pulse.forward(from: 0);
    }
  }

  void _openMenu() {
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    showMessageActionsMenu(
      context,
      ref,
      conversationId: widget.conversationId,
      message: _m,
      bubbleRect: rect,
      readOnly: widget.readOnly,
      allowTranscribe: widget.allowTranscribe,
    );
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.msgaction_delete_title,
      body: l.msgaction_delete_body,
      confirmLabel: l.chat_delete,
      icon: AppIcons.delete,
    );
    if (ok) ref.read(messagesControllerProvider(widget.conversationId).notifier).delete(_m.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final d = widget.detail;
    final own =
        _m.type == MessageBubbleType.outgoing || (_m.type == MessageBubbleType.internalNote && _m.senderId == d.meId);
    final canDelete = !widget.readOnly && own && d.permissions.canDeleteMessages && _m.kind != MessageKind.deleted;

    Widget bubble = KeyedSubtree(
      key: _bubbleKey,
      child: MessageBubble(
        conversationId: widget.conversationId,
        message: _m,
        detail: d,
        firstInGroup: widget.item.firstInGroup,
        lastInGroup: widget.item.lastInGroup,
        maxWidth: widget.maxWidth,
        onQuoteTap: widget.onQuoteTap,
      ),
    );

    // Highlight pulse behind the bubble (#FDF0C4 = searchHighlight).
    bubble = AnimatedBuilder(
      animation: _pulseValue,
      child: bubble,
      builder: (context, child) {
        final v = _staticOn ? 1.0 : _pulseValue.value;
        if (v == 0) return child!;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: c.searchHighlight.withValues(alpha: v),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: child,
        );
      },
    );

    if (_m.type != MessageBubbleType.system) {
      bubble = Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onLongPress: _openMenu,
            child: bubble,
          ),
        ),
      );
    }

    final row = Padding(
      padding: EdgeInsets.only(top: widget.item.gapAbove),
      child: Semantics(
        container: true,
        label: MessageBubble.describe(context, _m, d),
        excludeSemantics: _m.type != MessageBubbleType.system,
        customSemanticsActions: {
          if (_m.text.trim().isNotEmpty)
            CustomSemanticsAction(label: l.msgaction_copy): () {
              Clipboard.setData(ClipboardData(text: _m.text));
              AppSnackbar.show(context, message: l.msgaction_copied);
            },
          if (canDelete) CustomSemanticsAction(label: l.chat_delete): _delete,
        },
        child: RepaintBoundary(child: bubble),
      ),
    );

    if (!widget.animateIn || AppMotion.reduced(context)) return row;
    final curve = CurvedAnimation(parent: _enter, curve: AppMotion.standard);
    return AnimatedBuilder(
      animation: curve,
      child: row,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(offset: Offset(0, 8 * (1 - curve.value)), child: child),
      ),
    );
  }
}
