import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/ai_suggestion_controller.dart';
import '../../../application/composer_controller.dart';
import '../../../application/messages_controller.dart';
import '../../../data/messages_repository.dart';
import '../../../domain/conversation_detail.dart';
import '../../../domain/rewrite_session.dart';
import 'attach_sheet.dart';
import 'attachments_preview.dart';
import 'composer_mode_toggle.dart';
import 'mention_panel.dart';
import 'quick_replies_panel.dart';
import 'reply_preview_bar.dart';
import 'voice_recorder.dart';

/// Message input bar (Chat spec §4.7, DS §8.6).
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    super.key,
    required this.detail,
    this.focusNode,
    this.onOpenTemplates,
    this.onOpenRewrite,
    this.onSent,
  });

  final ConversationDetail detail;
  final FocusNode? focusNode;
  final VoidCallback? onOpenTemplates;

  /// Opens the AI Rewrite sheet (Rewrite spec §2) on [source] — the whole
  /// draft or a selection.
  final Future<RewriteOutcome?> Function(String source, {required RewriteEntry entry, required bool note})?
  onOpenRewrite;

  /// After a send — e.g. the temporary note composer in claim state closes
  /// and the claim bar returns (Claim spec §5.3).
  final VoidCallback? onSent;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> with SingleTickerProviderStateMixin {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final VoiceRecorderController _recorder = VoiceRecorderController(
    onSend: _sendVoice,
    onPermissionDenied: () => _toast(context.l10n.composer_mic_denied),
    onError: () => _toast(context.l10n.composer_record_failed),
  );
  final _aiTooltip = GlobalKey<TooltipState>();

  /// 150ms cross-fade when a rewrite lands in the field (Rewrite spec §12).
  late final AnimationController _applyFade = AnimationController(vsync: this, duration: AppMotion.fast, value: 1);

  // "{name} يشاهد أيضًا" shows for 4s whenever the viewer set changes.
  String _viewersKey = '';
  bool _showViewers = false;
  Timer? _viewersTimer;

  String get _id => widget.detail.id;
  ComposerController get _composer => ref.read(composerControllerProvider(_id).notifier);

  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _recorder.addListener(_rebuild);
    // Rebuild per keystroke so the '/' and '@' panels follow the text.
    _text = _composer.text..addListener(_rebuild);
  }

  @override
  void dispose() {
    try {
      _text.removeListener(_rebuild);
    } catch (_) {
      // The composer provider may already have disposed its controller.
    }
    _recorder.removeListener(_rebuild);
    _recorder.dispose();
    _viewersTimer?.cancel();
    _applyFade.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  // ---- Sending ------------------------------------------------------------------------

  void _send() {
    final state = ref.read(composerControllerProvider(_id));
    if (!state.canSend) return;
    final names = [for (final a in ref.read(colleaguesProvider)) a.name.split(' ').first];
    final out = _composer.takeOutgoing(mentionNames: names);
    if (out.isEmpty) return;
    final messages = ref.read(messagesControllerProvider(_id).notifier);
    for (final m in out) {
      messages.send(m);
    }
    HapticFeedback.lightImpact();
    _focus.requestFocus(); // keep focus after send (§4.7.6)
    widget.onSent?.call();
  }

  void _sendVoice(Duration d, String path) {
    ref.read(messagesControllerProvider(_id).notifier).send(OutgoingMessage(
          text: '',
          kind: MessageKind.voice,
          duration: d,
          localPath: path,
          localMime: VoiceRecorderController.mime,
        ));
    HapticFeedback.lightImpact();
  }

  void _toast(String message) {
    if (mounted) AppSnackbar.show(context, message: message, kind: SnackKind.error);
  }

  Future<void> _attach() async {
    final now = DateTime.now();
    final opt = await showAttachSheet(
      context,
      whatsapp: widget.detail.channel == Channel.whatsapp,
      windowClosed: widget.detail.windowClosed(now),
    );
    if (opt == null || !mounted) return;
    final l = context.l10n;
    switch (opt) {
      case AttachOption.media:
      case AttachOption.camera:
        _composer.addAttachment(MessageKind.image, 'IMG_${now.millisecondsSinceEpoch % 10000}.jpg');
      case AttachOption.file:
        _composer.addAttachment(MessageKind.file, 'document.pdf');
      case AttachOption.location:
        final label = l.composer_location_sample;
        ref
            .read(messagesControllerProvider(_id).notifier)
            .send(OutgoingMessage(text: label, kind: MessageKind.location, locationLabel: label));
      case AttachOption.quickReplies:
        final t = _composer.text;
        t.value = const TextEditingValue(text: '/', selection: TextSelection.collapsed(offset: 1));
        _focus.requestFocus();
      case AttachOption.template:
        widget.onOpenTemplates?.call();
      case AttachOption.product:
        break;
      case AttachOption.note:
        _composer.enterNoteMode();
        _focus.requestFocus();
    }
  }

  /// ✦ in the field: needs ≥ 2 characters, else the 2s hint (§2).
  Future<void> _rewrite() async {
    final text = _composer.text.text;
    if (text.trim().characters.length < 2) {
      _aiTooltip.currentState?.ensureTooltipVisible();
      return;
    }
    await _openRewrite(text, entry: _composer.fromSuggestion ? RewriteEntry.suggestion : RewriteEntry.composer);
  }

  /// Selection toolbar "حسّن بالذكاء": only the selected text is rewritten
  /// and replaced.
  Future<void> _rewriteSelection(TextSelection sel) async {
    final text = _composer.text.text;
    if (!sel.isValid || sel.isCollapsed || sel.end > text.length) return;
    await _openRewrite(
      sel.textInside(text),
      entry: RewriteEntry.selection,
      range: TextRange(start: sel.start, end: sel.end),
    );
  }

  Future<void> _openRewrite(String source, {required RewriteEntry entry, TextRange? range}) async {
    final open = widget.onOpenRewrite;
    if (open == null) return;
    final note = ref.read(composerControllerProvider(_id)).mode == ComposerMode.note;
    _focus.unfocus(); // the keyboard goes down while the sheet is open (§3)
    final out = await open(source, entry: entry, note: note);
    if (out == null || !mounted) return; // dismissed → composer unchanged
    _composer.applyRewrite(out, range: range);
    if (!AppMotion.reduced(context)) _applyFade.forward(from: 0.35);
    _focus.requestFocus();
  }

  /// Default toolbar + "حسّن بالذكاء" first when ≥ 2 chars are selected.
  Widget _contextMenu(BuildContext context, EditableTextState state, {required bool allowRewrite}) {
    final items = [...state.contextMenuButtonItems];
    final value = state.textEditingValue;
    final sel = value.selection;
    final selected = sel.isValid && !sel.isCollapsed ? sel.textInside(value.text) : '';
    if (allowRewrite && widget.onOpenRewrite != null && selected.trim().characters.length >= 2) {
      items.insert(
        0,
        ContextMenuButtonItem(
          label: context.l10n.rw_toolbar,
          onPressed: () {
            state.hideToolbar();
            _rewriteSelection(sel);
          },
        ),
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(anchors: state.contextMenuAnchors, buttonItems: items);
  }

  /// Tablets with a hardware keyboard: Enter sends, Shift+Enter = newline.
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    if (!tablet || e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static final _rtlChar = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
  static final _ltrChar = RegExp(r'[A-Za-zÀ-ɏ]');

  /// Direction from the first strong character (§4.7 field).
  TextDirection? _directionOf(String text) {
    for (final ch in text.characters) {
      if (_rtlChar.hasMatch(ch)) return TextDirection.rtl;
      if (_ltrChar.hasMatch(ch)) return TextDirection.ltr;
    }
    return null;
  }

  void _syncViewers(List<Agent> viewers) {
    final key = viewers.map((a) => a.id).join(',');
    if (key == _viewersKey) return;
    _viewersKey = key;
    _viewersTimer?.cancel();
    _showViewers = viewers.isNotEmpty;
    if (_showViewers) {
      _viewersTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showViewers = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final state = ref.watch(composerControllerProvider(_id));
    final ctrl = _composer.text;
    final conv = widget.detail.conversation;
    final note = state.mode == ComposerMode.note;
    final windowClosed = widget.detail.windowClosed(DateTime.now());

    // Typing collapses the AI card to its pill (§4.6 auto-hide).
    ref.listen(composerControllerProvider(_id).select((s) => s.hasText), (prev, has) {
      if (has && prev != true) ref.read(aiSuggestionControllerProvider(_id).notifier).collapse(byUser: false);
    });
    _syncViewers(conv.viewers);

    final text = ctrl.text;
    final slashQuery = !note && text.startsWith('/') && !text.contains('\n') ? text.substring(1) : null;
    final mentionMatch = note ? RegExp(r'@([^\s@]*)$').firstMatch(text) : null;

    // Presence / colleague typing row (§7).
    final presence = conv.colleagueTypingNote != null
        ? l.composer_colleague_typing_note(conv.colleagueTypingNote!)
        : (_showViewers && conv.viewers.isNotEmpty ? l.composer_colleague_viewing(conv.viewers.first.name) : null);

    final accent = note ? c.warning : c.primary;

    Widget trailingButton;
    if (windowClosed) {
      trailingButton = Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: AppButton(
          label: l.composer_template,
          icon: AppIcons.templates,
          size: AppButtonSize.small,
          variant: AppButtonVariant.tonal,
          onPressed: widget.onOpenTemplates,
        ),
      );
    } else if (_recorder.recording && _recorder.locked) {
      // Hands-free recording: send the voice note.
      trailingButton = Semantics(
        button: true,
        label: l.composer_record_send,
        excludeSemantics: true,
        child: InkResponse(
          key: const ValueKey('send-voice'),
          onTap: () => unawaited(_recorder.send()),
          radius: 26,
          child: SizedBox.square(
            dimension: AppSpacing.minTouch,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                child: const AppIcon(AppIcons.send, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    } else if (state.canSend || note) {
      trailingButton = Semantics(
        button: true,
        enabled: state.canSend,
        label: note ? l.composer_send_note : l.composer_send,
        excludeSemantics: true,
        child: InkResponse(
          key: const ValueKey('send'),
          onTap: state.canSend ? _send : null,
          radius: 26,
          child: SizedBox.square(
            dimension: AppSpacing.minTouch,
            child: Center(
              child: Opacity(
                opacity: state.canSend ? 1 : 0.4,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: AppIcon(note ? AppIcons.note : AppIcons.send, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      trailingButton = VoiceRecordButton(key: const ValueKey('mic'), controller: _recorder, color: c.primary);
    }

    final field = _recorder.recording || _recorder.cancelled
        ? RecordingField(controller: _recorder)
        : _Field(
            controller: ctrl,
            focusNode: _focus,
            onKey: _onKey,
            enabled: !windowClosed,
            note: note,
            direction: _directionOf(text),
            placeholder: windowClosed
                ? l.composer_template_only
                : (note ? l.chat_note_placeholder : l.chat_placeholder),
            semanticLabel: note ? l.composer_note_field_label : l.composer_field_label,
            contextMenuBuilder: (ctx, s) => _contextMenu(ctx, s, allowRewrite: !windowClosed),
            // Notes get the ✦ too, with the note-only styles (§2).
            aiButton: windowClosed
                ? null
                : Tooltip(
                    key: _aiTooltip,
                    message: l.rw_empty_hint,
                    triggerMode: TooltipTriggerMode.manual,
                    showDuration: const Duration(seconds: 2),
                    child: AppIconButton(
                      icon: AppIcons.ai,
                      size: 32,
                      iconSize: 22,
                      iconColor: text.trim().isEmpty ? c.primary.withValues(alpha: 0.4) : c.primary,
                      semanticLabel: l.composer_ai_rewrite,
                      onPressed: _rewrite,
                    ),
                  ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: AppMotion.normal,
          child: presence == null
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
                    child: Text(presence, style: t.caption.copyWith(color: c.textSecondary)),
                  ),
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.background,
            border: Border(top: BorderSide(color: c.divider)),
          ),
          padding: EdgeInsets.fromLTRB(10, AppSpacing.sm, 10, AppSpacing.sm + MediaQuery.viewPaddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.showModeToggle)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ComposerModeToggle(
                    mode: state.mode,
                    onChanged: (m) {
                      _composer.setMode(m);
                      _focus.requestFocus();
                    },
                  ),
                ),
              if (slashQuery != null)
                QuickRepliesPanel(
                  replies: ref.watch(quickRepliesProvider),
                  query: slashQuery,
                  onPick: (r) {
                    _composer.insertQuickReply(r, contactName: widget.detail.contact.name);
                    _focus.requestFocus();
                  },
                ),
              if (mentionMatch != null)
                MentionPanel(
                  agents: ref.watch(colleaguesProvider),
                  query: mentionMatch.group(1) ?? '',
                  onPick: (a) {
                    _composer.insertMention(a.name.split(' ').first);
                    _focus.requestFocus();
                  },
                ),
              if (state.replyTo != null)
                ReplyPreviewBar(
                  message: state.replyTo!,
                  senderName: state.replyTo!.type == MessageBubbleType.incoming
                      ? widget.detail.contact.name
                      : (state.replyTo!.senderName ?? l.common_you),
                  onClose: () => _composer.setReply(null),
                ),
              if (state.attachments.isNotEmpty)
                AttachmentsPreview(attachments: state.attachments, onRemove: _composer.removeAttachment),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppIconButton(
                    icon: AppIcons.add,
                    size: 44,
                    iconSize: 24,
                    semanticLabel: l.composer_attach,
                    onPressed: _recorder.recording ? null : _attach,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FadeTransition(opacity: _applyFade, child: field),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: RotationTransition(turns: Tween(begin: 0.25, end: 0.0).animate(anim), child: child),
                    ),
                    child: trailingButton,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The pill text field: min 44, max 6 lines, radius full (22 multi-line),
/// `surfaceVariant` (note mode: `noteBackground`), AI ✦ trailing.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focusNode,
    required this.onKey,
    required this.enabled,
    required this.note,
    required this.direction,
    required this.placeholder,
    required this.semanticLabel,
    required this.contextMenuBuilder,
    this.aiButton,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusOnKeyEventCallback onKey;
  final bool enabled;
  final bool note;
  final TextDirection? direction;
  final String placeholder;
  final String semanticLabel;
  final EditableTextContextMenuBuilder contextMenuBuilder;
  final Widget? aiButton;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final style = t.bodyLarge.copyWith(fontSize: 15);
    return LayoutBuilder(
      builder: (context, box) {
        final innerWidth = box.maxWidth - 16 - (aiButton == null ? 14 : 48);
        final painter = TextPainter(
          text: TextSpan(text: controller.text.isEmpty ? ' ' : controller.text, style: style),
          textDirection: direction ?? Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: innerWidth > 0 ? innerWidth : 1);
        final multiline = controller.text.contains('\n') || painter.computeLineMetrics().length > 1;
        return AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: note ? c.noteBackground : c.surfaceVariant,
            borderRadius: BorderRadius.circular(multiline ? 22 : AppRadius.full),
            border: note ? Border.all(color: c.noteBorder) : null,
          ),
          padding: EdgeInsetsDirectional.only(start: 16, end: aiButton == null ? 14 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: onKey,
                  child: Semantics(
                    label: semanticLabel,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      contextMenuBuilder: contextMenuBuilder,
                      minLines: 1,
                      maxLines: 6,
                      textDirection: direction,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      style: style.copyWith(color: note ? c.noteForeground : c.textPrimary),
                      cursorColor: note ? c.warning : c.primary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: placeholder,
                        hintMaxLines: 1,
                        hintStyle: style.copyWith(color: c.textTertiary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
              ),
              if (aiButton != null) Padding(padding: const EdgeInsets.only(bottom: 2), child: aiButton),
            ],
          ),
        );
      },
    );
  }
}
