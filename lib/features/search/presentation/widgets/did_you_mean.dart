import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// "هل تقصد: {suggestion}؟" — suggestion in `primary` 700, tappable (§8).
class DidYouMean extends StatefulWidget {
  const DidYouMean({super.key, required this.suggestion, required this.onTap});

  final String suggestion;
  final VoidCallback onTap;

  @override
  State<DidYouMean> createState() => _DidYouMeanState();
}

class _DidYouMeanState extends State<DidYouMean> {
  late final _tap = TapGestureRecognizer()..onTap = widget.onTap;

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text.bodySmall.copyWith(color: c.textSecondary);
    final full = context.l10n.search_did_you_mean('\u0000');
    final parts = full.split('\u0000');
    return Semantics(
      button: true,
      label: context.l10n.search_did_you_mean(widget.suggestion),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 0),
        child: Text.rich(
          TextSpan(
            style: t,
            children: [
              TextSpan(text: parts.first),
              TextSpan(
                text: widget.suggestion,
                style: t.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                recognizer: _tap,
              ),
              if (parts.length > 1) TextSpan(text: parts.last),
            ],
          ),
        ),
      ),
    );
  }
}
