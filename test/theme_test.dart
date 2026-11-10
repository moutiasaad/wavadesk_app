import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wavadesk/core/theme/app_theme.dart';

void main() {
  test('light and dark themes expose every token extension', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.extension<AppColors>(), isNotNull);
      expect(theme.extension<AppTextStyles>(), isNotNull);
      expect(theme.extension<AppShadows>(), isNotNull);
    }
  });

  test('brand tokens match Design System §3.1', () {
    expect(AppColors.light.primary, const Color(0xFF0F7E7A));
    expect(AppColors.dark.primary, const Color(0xFF2BB8AD));
    // §10 rule 2: outgoing bubble keeps the brand teal in dark mode.
    expect(AppColors.dark.bubbleOutgoing, const Color(0xFF0F7E7A));
  });

  test('bubble tail sits on the logical bottom corner per direction', () {
    final incoming = AppRadius.bubble(outgoing: false, hasTail: true);
    final outgoing = AppRadius.bubble(outgoing: true, hasTail: true);
    expect(incoming.bottomStart, const Radius.circular(AppRadius.bubbleTail));
    expect(outgoing.bottomEnd, const Radius.circular(AppRadius.bubbleTail));
    // RTL resolves the outgoing tail to the bottom-left corner.
    expect(outgoing.resolve(TextDirection.rtl).bottomLeft, const Radius.circular(AppRadius.bubbleTail));
  });
}
