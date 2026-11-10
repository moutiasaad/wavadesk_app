import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// Quoted message inside a bubble (Chat spec §4.4): 3dp start bar (primary,
/// white 60% on outgoing), sender `chatSenderLabel` + 2 lines `bodySmall`,
/// radius 10, 8% overlay. Tap → scroll to the original + highlight.
class ReplyQuote extends StatelessWidget {
  const ReplyQuote({super.key, required this.quote, required this.foreground, required this.onPrimary, this.onTap});

  final QuotedMessage quote;
  final Color foreground;
  final bool onPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bar = onPrimary ? Colors.white.withValues(alpha: 0.6) : c.primary;
    return Semantics(
      button: onTap != null,
      label: '${context.l10n.bubble_reply_to(quote.sender)}: ${quote.text}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(color: foreground.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: bar),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quote.sender,
                          style: t.chatSenderLabel.copyWith(color: onPrimary ? foreground : c.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          quote.text,
                          style: t.bodySmall.copyWith(color: foreground.withValues(alpha: 0.85)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
