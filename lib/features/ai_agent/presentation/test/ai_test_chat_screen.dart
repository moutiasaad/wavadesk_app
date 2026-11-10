import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../chat/presentation/widgets/bubbles/typing_bubble.dart';
import '../../application/ai_test_controller.dart';
import 'ai_why_sheet.dart';

/// Sandbox chat (AI Agent spec §5.5). Roles flip: the tester is the
/// customer (end side); the AI answers at the incoming position.
class AiTestChatScreen extends ConsumerStatefulWidget {
  const AiTestChatScreen({super.key});

  @override
  ConsumerState<AiTestChatScreen> createState() => _AiTestChatScreenState();
}

class _AiTestChatScreenState extends ConsumerState<AiTestChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    _input.clear();
    setState(() {});
    ref.read(aiTestControllerProvider.notifier).send(t);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final reduced = AppMotion.reduced(context);
      final end = _scroll.position.maxScrollExtent;
      reduced ? _scroll.jumpTo(end) : _scroll.animateTo(end, duration: AppMotion.normal, curve: AppMotion.standard);
    });
  }

  Future<void> _pickChannel() async {
    final l = context.l10n;
    final current = ref.read(aiTestControllerProvider).channel;
    final picked = await AppBottomSheet.show<String>(
      context,
      title: l.ai_test_channel,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (key, label, icon) in [
            ('whatsapp', l.ai_channel_whatsapp, AppIcons.whatsapp),
            ('web', l.ai_channel_web, AppIcons.webChat),
          ])
            ListTile(
              leading: Icon(icon, color: ctx.colors.textSecondary),
              title: Text(label, style: ctx.text.listTitle),
              trailing: key == current ? Icon(AppIcons.check, color: ctx.colors.primary) : null,
              onTap: () => Navigator.of(ctx).pop(key),
            ),
        ],
      ),
    );
    if (picked != null) ref.read(aiTestControllerProvider.notifier).setChannel(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final state = ref.watch(aiTestControllerProvider);
    final ctrl = ref.read(aiTestControllerProvider.notifier);
    ref.listen(aiTestControllerProvider.select((s) => (s.messages.length, s.sending)), (_, _) => _toBottom());

    return Scaffold(
      backgroundColor: c.chatBackground,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.ai_test_title, style: t.h5),
            Text(l.ai_test_sub, style: t.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(AppIcons.more, color: c.textPrimary),
            onSelected: (v) => v == 'reset' ? ctrl.reset() : _pickChannel(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'reset', child: Text(l.ai_test_reset)),
              PopupMenuItem(value: 'channel', child: Text(l.ai_test_channel)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: c.infoContainer,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(AppIcons.info, size: 16, color: c.textInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l.ai_test_info, style: t.bodySmall.copyWith(color: c.textInfo))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
              children: [
                for (final m in state.messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: switch (m.role) {
                      AiTestRole.tester => _TesterBubble(text: m.text),
                      AiTestRole.ai => _AiBubble(
                          message: m,
                          onWhy: m.reply == null ? null : () => showAiWhySheet(context, m.reply!),
                          onRate: (r) => ctrl.rate(m.id, r),
                        ),
                      AiTestRole.handoff => _Pill(text: l.ai_test_handoff(aiReasonLabel(l, m.reply?.ruleTriggered))),
                      AiTestRole.error => _Pill(text: l.ai_test_error, error: true),
                    },
                  ),
                if (state.sending) const TypingBubble(),
              ],
            ),
          ),
          if (!state.started)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final p in [l.ai_test_p1, l.ai_test_p2, l.ai_test_p3, l.ai_test_p4])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                      child: Center(
                        child: AppFilterChip(label: p, selected: false, onTap: state.sending ? () {} : () => _send(p)),
                      ),
                    ),
                ],
              ),
            ),
          _Composer(
            controller: _input,
            enabled: !state.sending,
            onChanged: () => setState(() {}),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _TesterBubble extends StatelessWidget {
  const _TesterBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: c.bubbleOutgoing, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Text(text, style: t.chatMessage.copyWith(color: c.bubbleOutgoingForeground)),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.message, required this.onWhy, required this.onRate});

  final AiTestMessage message;
  final VoidCallback? onWhy;
  final ValueChanged<String> onRate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    Widget rateButton(String value, IconData icon, String label) {
      final on = message.rating == value;
      return Semantics(
        selected: on,
        child: AppIconButton(
          icon: icon,
          iconSize: 16,
          size: 32,
          iconColor: on ? c.primary : c.textTertiary,
          semanticLabel: label,
          onPressed: () => onRate(value),
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: c.bubbleAi,
                border: Border.all(color: c.bubbleAiBorder),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.sparkle, size: 13, color: c.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(l.ai_test_label, style: t.chatSenderLabel.copyWith(color: c.primary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(message.text, style: t.chatMessage.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onWhy != null)
                  TextButton(
                    onPressed: onWhy,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(l.ai_test_why, style: t.buttonSmall.copyWith(color: c.primary)),
                  ),
                rateButton('up', AppIcons.thumbsUp, '👍'),
                rateButton('down', AppIcons.thumbsDown, '👎'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: error ? c.errorContainer : c.bubbleSystem,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: error ? c.textError : c.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.enabled, required this.onChanged, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final canSend = enabled && controller.text.trim().isNotEmpty;
    return Material(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => onChanged(),
                  onSubmitted: (_) => canSend ? onSend() : null,
                  style: t.bodyMedium,
                  decoration: InputDecoration(
                    hintText: l.ai_test_hint,
                    counterText: '',
                    filled: true,
                    fillColor: c.surfaceVariant,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: AppIcons.send,
                variant: AppIconButtonVariant.filled,
                background: canSend ? c.primary : c.surfaceVariant,
                iconColor: canSend ? c.onPrimary : c.textDisabled,
                semanticLabel: l.composer_send,
                onPressed: canSend ? onSend : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
