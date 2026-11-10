import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// WhatsApp-like outgoing bubble on the chat background (WhatsApp spec
/// §5.2 live preview, §4.5 template preview). Variables (`{اسم_العميل}`,
/// `{{1}}`) render as tonal spans. [numberedButtons] = linked_device, where
/// quick buttons are sent as a numbered list instead of real buttons.
class WaMessagePreview extends StatelessWidget {
  const WaMessagePreview({
    super.key,
    required this.text,
    this.buttons = const [],
    this.numberedButtons = false,
    this.highlightTemplateVars = false,
  });

  final String text;
  final List<String> buttons;
  final bool numberedButtons;
  final bool highlightTemplateVars;

  static final _vars = RegExp(r'\{\{\d+\}\}|\{[^{}\s]{1,30}\}');

  List<InlineSpan> _spans(BuildContext context, String s, TextStyle base) {
    final c = context.colors;
    final out = <InlineSpan>[];
    var last = 0;
    for (final m in _vars.allMatches(s)) {
      if (m.start > last) out.add(TextSpan(text: s.substring(last, m.start)));
      out.add(TextSpan(
        text: m.group(0),
        style: base.copyWith(color: c.onPrimaryContainer, backgroundColor: c.primaryContainer, fontWeight: FontWeight.w700),
      ));
      last = m.end;
    }
    if (last < s.length) out.add(TextSpan(text: s.substring(last)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final labels = [for (final b in buttons) if (b.trim().isNotEmpty) b.trim()];
    final body = numberedButtons && labels.isNotEmpty
        ? '$text\n\n${[for (var i = 0; i < labels.length; i++) '${i + 1}. ${labels[i]}'].join('\n')}'
        : text;
    final style = t.chatMessage.copyWith(fontSize: 14, color: c.textPrimary);
    final now = TimeOfDay.now();

    return Semantics(
      label: '${l.wa_preview}: $body',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: c.chatBackground, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(
                    color: c.isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: const Radius.circular(AppRadius.lg),
                      topEnd: const Radius.circular(AppRadius.bubbleTail),
                      bottomStart: const Radius.circular(AppRadius.lg),
                      bottomEnd: Radius.circular(labels.isNotEmpty && !numberedButtons ? 4 : AppRadius.lg),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(style: style, children: _spans(context, body.isEmpty ? '…' : body, style)),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                          style: t.chatTimestamp.copyWith(color: c.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!numberedButtons)
                  for (final b in labels)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: c.isDark ? const Color(0xFF1F2C33) : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        b,
                        textAlign: TextAlign.center,
                        style: t.buttonSmall.copyWith(color: c.isDark ? const Color(0xFF53BDEB) : const Color(0xFF0B7FC0)),
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
