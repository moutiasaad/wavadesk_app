import 'package:flutter/material.dart';

/// All color tokens from Design System §3. Light and dark values are written
/// out explicitly — dark colors are never computed at runtime (§10).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    // Brand
    required this.primary,
    required this.primaryPressed,
    required this.primaryContainer,
    required this.primaryContainerBorder,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    // Backgrounds & surfaces
    required this.background,
    required this.backgroundMuted,
    required this.chatBackground,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.scrim,
    required this.divider,
    required this.border,
    required this.borderStrong,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnDark,
    required this.textLink,
    required this.textError,
    required this.textSuccess,
    required this.textWarning,
    required this.textInfo,
    // Semantic
    required this.success,
    required this.successContainer,
    required this.error,
    required this.errorContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    // Presence
    required this.presenceOnline,
    required this.presenceBusy,
    required this.presenceAway,
    // Conversation status
    required this.statusOpen,
    required this.statusOpenContainer,
    required this.statusPending,
    required this.statusPendingContainer,
    required this.statusWaiting,
    required this.statusWaitingContainer,
    required this.statusSnoozed,
    required this.statusSnoozedContainer,
    required this.statusResolved,
    required this.statusResolvedContainer,
    required this.statusClosed,
    required this.statusClosedContainer,
    required this.statusAi,
    required this.statusAiContainer,
    // Priority
    required this.priorityUrgent,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    // Channels
    required this.channelWhatsapp,
    required this.channelWhatsappContainer,
    required this.channelWeb,
    required this.channelWebContainer,
    required this.channelMessenger,
    required this.channelMessengerContainer,
    required this.channelInstagram,
    required this.channelInstagramContainer,
    required this.channelEmail,
    required this.channelEmailContainer,
    required this.channelTelegram,
    required this.channelTelegramContainer,
    required this.channelSms,
    required this.channelSmsContainer,
    required this.channelOther,
    required this.channelOtherContainer,
    // Chat
    required this.bubbleIncoming,
    required this.bubbleOutgoing,
    required this.bubbleOutgoingForeground,
    required this.bubbleAi,
    required this.bubbleAiBorder,
    required this.bubbleSystem,
    required this.noteBackground,
    required this.noteForeground,
    required this.noteBorder,
    required this.readTickOnPrimary,
    // Misc
    required this.searchHighlight,
    required this.metricAlertBorder,
    required this.snackbarBackground,
    required this.snackbarForeground,
    required this.snackbarIconSuccess,
    required this.snackbarIconError,
  });

  final Brightness brightness;

  final Color primary;
  final Color primaryPressed;
  final Color primaryContainer;
  final Color primaryContainerBorder;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color accent;

  final Color background;
  final Color backgroundMuted;
  final Color chatBackground;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color scrim;
  final Color divider;
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textOnDark;
  final Color textLink;
  final Color textError;
  final Color textSuccess;
  final Color textWarning;
  final Color textInfo;

  final Color success;
  final Color successContainer;
  final Color error;
  final Color errorContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  final Color presenceOnline;
  final Color presenceBusy;
  final Color presenceAway;

  final Color statusOpen;
  final Color statusOpenContainer;
  final Color statusPending;
  final Color statusPendingContainer;
  final Color statusWaiting;
  final Color statusWaitingContainer;
  final Color statusSnoozed;
  final Color statusSnoozedContainer;
  final Color statusResolved;
  final Color statusResolvedContainer;
  final Color statusClosed;
  final Color statusClosedContainer;
  final Color statusAi;
  final Color statusAiContainer;

  final Color priorityUrgent;
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;

  final Color channelWhatsapp;
  final Color channelWhatsappContainer;
  final Color channelWeb;
  final Color channelWebContainer;
  final Color channelMessenger;
  final Color channelMessengerContainer;
  final Color channelInstagram;
  final Color channelInstagramContainer;
  final Color channelEmail;
  final Color channelEmailContainer;
  final Color channelTelegram;
  final Color channelTelegramContainer;
  final Color channelSms;
  final Color channelSmsContainer;
  final Color channelOther;
  final Color channelOtherContainer;

  final Color bubbleIncoming;
  final Color bubbleOutgoing;
  final Color bubbleOutgoingForeground;
  final Color bubbleAi;
  final Color bubbleAiBorder;
  final Color bubbleSystem;
  final Color noteBackground;
  final Color noteForeground;
  final Color noteBorder;
  final Color readTickOnPrimary;

  final Color searchHighlight;
  final Color metricAlertBorder;
  final Color snackbarBackground;
  final Color snackbarForeground;
  final Color snackbarIconSuccess;
  final Color snackbarIconError;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppColors(
    brightness: Brightness.light,
    primary: Color(0xFF0F7E7A),
    primaryPressed: Color(0xFF0A5E5B),
    primaryContainer: Color(0xFFECF7F6),
    primaryContainerBorder: Color(0xFFD6EFED),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF0A5E5B),
    secondary: Color(0xFF0D1417),
    onSecondary: Color(0xFFFFFFFF),
    accent: Color(0xFF15B6A8),
    background: Color(0xFFFFFFFF),
    backgroundMuted: Color(0xFFF5F7F9),
    chatBackground: Color(0xFFF2F4F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEF2F5),
    surfaceElevated: Color(0xFFFFFFFF),
    scrim: Color(0x6B0D1417), // #0D1417 @ 42%
    divider: Color(0xFFE9EEF2),
    border: Color(0xFFE9EEF2),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textTertiary: Color(0xFF94A3B8),
    textDisabled: Color(0xFFCBD5E1),
    textOnDark: Color(0xFFFFFFFF),
    textLink: Color(0xFF0F7E7A),
    textError: Color(0xFFBE123C),
    textSuccess: Color(0xFF15803D),
    textWarning: Color(0xFFB45309),
    textInfo: Color(0xFF1D4ED8),
    success: Color(0xFF16A34A),
    successContainer: Color(0xFFE9F9EF),
    error: Color(0xFFE11D48),
    errorContainer: Color(0xFFFFF1F2),
    warning: Color(0xFFD97706),
    warningContainer: Color(0xFFFEF3E2),
    info: Color(0xFF2563EB),
    infoContainer: Color(0xFFEFF4FF),
    presenceOnline: Color(0xFF22C55E),
    presenceBusy: Color(0xFFF59E0B),
    presenceAway: Color(0xFFCBD5E1),
    statusOpen: Color(0xFF0A5E5B),
    statusOpenContainer: Color(0xFFECF7F6),
    statusPending: Color(0xFFB45309),
    statusPendingContainer: Color(0xFFFEF3E2),
    statusWaiting: Color(0xFFBE123C),
    statusWaitingContainer: Color(0xFFFFF1F2),
    statusSnoozed: Color(0xFF6D28D9),
    statusSnoozedContainer: Color(0xFFF3EEFF),
    statusResolved: Color(0xFF15803D),
    statusResolvedContainer: Color(0xFFE9F9EF),
    statusClosed: Color(0xFF64748B),
    statusClosedContainer: Color(0xFFEEF2F5),
    statusAi: Color(0xFF0A5E5B),
    statusAiContainer: Color(0xFFECF7F6),
    priorityUrgent: Color(0xFFE11D48),
    priorityHigh: Color(0xFFEA580C),
    priorityMedium: Color(0xFFD97706),
    priorityLow: Color(0xFF94A3B8),
    channelWhatsapp: Color(0xFF25D366),
    channelWhatsappContainer: Color(0xFFE8F9EF),
    channelWeb: Color(0xFF2563EB),
    channelWebContainer: Color(0xFFEFF4FF),
    channelMessenger: Color(0xFF0866FF),
    channelMessengerContainer: Color(0xFFEAF1FF),
    channelInstagram: Color(0xFFE4405F),
    channelInstagramContainer: Color(0xFFFDECF0),
    channelEmail: Color(0xFF64748B),
    channelEmailContainer: Color(0xFFEEF2F5),
    channelTelegram: Color(0xFF26A5E4),
    channelTelegramContainer: Color(0xFFE8F6FD),
    channelSms: Color(0xFF7C3AED),
    channelSmsContainer: Color(0xFFF3EEFF),
    channelOther: Color(0xFF475569),
    channelOtherContainer: Color(0xFFEEF2F5),
    bubbleIncoming: Color(0xFFFFFFFF),
    bubbleOutgoing: Color(0xFF0F7E7A),
    bubbleOutgoingForeground: Color(0xFFFFFFFF),
    bubbleAi: Color(0xFFE3F3F1),
    bubbleAiBorder: Color(0xFFD6EFED),
    bubbleSystem: Color(0xFFE8ECEF),
    noteBackground: Color(0xFFFFFBEB),
    noteForeground: Color(0xFF78530A),
    noteBorder: Color(0xFFF1CF7F),
    readTickOnPrimary: Color(0xFF9FE3DC),
    searchHighlight: Color(0xFFFDF0C4),
    metricAlertBorder: Color(0xFFFECDD3),
    snackbarBackground: Color(0xFF0D1417),
    snackbarForeground: Color(0xFFFFFFFF),
    snackbarIconSuccess: Color(0xFF4ADE80),
    snackbarIconError: Color(0xFFFB7185),
  );

  static const dark = AppColors(
    brightness: Brightness.dark,
    primary: Color(0xFF2BB8AD),
    primaryPressed: Color(0xFF5CCFC5),
    primaryContainer: Color(0xFF0F2E2D),
    primaryContainerBorder: Color(0xFF1D4A47),
    onPrimary: Color(0xFF04211F),
    onPrimaryContainer: Color(0xFF9FE3DC),
    secondary: Color(0xFFE6ECEF),
    onSecondary: Color(0xFF0D1417),
    accent: Color(0xFF3FD3C6),
    background: Color(0xFF0B1113),
    backgroundMuted: Color(0xFF0F1619),
    chatBackground: Color(0xFF0E1518),
    surface: Color(0xFF151E22),
    surfaceVariant: Color(0xFF1C272C),
    surfaceElevated: Color(0xFF1C272C),
    scrim: Color(0x99000000), // #000000 @ 60%
    divider: Color(0xFF243036),
    border: Color(0xFF243036),
    borderStrong: Color(0xFF3A474F),
    textPrimary: Color(0xFFE6ECEF),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    textDisabled: Color(0xFF3A474F),
    textOnDark: Color(0xFFFFFFFF),
    textLink: Color(0xFF2BB8AD),
    textError: Color(0xFFFB7185),
    textSuccess: Color(0xFF4ADE80),
    textWarning: Color(0xFFFBBF24),
    textInfo: Color(0xFF60A5FA),
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF0F2A1A),
    error: Color(0xFFFB7185),
    errorContainer: Color(0xFF2E1219),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF2E2110),
    info: Color(0xFF60A5FA),
    infoContainer: Color(0xFF13203A),
    presenceOnline: Color(0xFF22C55E),
    presenceBusy: Color(0xFFF59E0B),
    presenceAway: Color(0xFF64748B),
    // Status foregrounds use the dark text tokens so they stay readable on
    // the dark containers (§10 rule 5).
    statusOpen: Color(0xFF9FE3DC),
    statusOpenContainer: Color(0xFF0F2E2D),
    statusPending: Color(0xFFFBBF24),
    statusPendingContainer: Color(0xFF2E2110),
    statusWaiting: Color(0xFFFB7185),
    statusWaitingContainer: Color(0xFF2E1219),
    statusSnoozed: Color(0xFFC4B5FD),
    statusSnoozedContainer: Color(0xFF221A38),
    statusResolved: Color(0xFF4ADE80),
    statusResolvedContainer: Color(0xFF0F2A1A),
    statusClosed: Color(0xFF94A3B8),
    statusClosedContainer: Color(0xFF1C272C),
    statusAi: Color(0xFF9FE3DC),
    statusAiContainer: Color(0xFF0F2E2D),
    priorityUrgent: Color(0xFFE11D48),
    priorityHigh: Color(0xFFEA580C),
    priorityMedium: Color(0xFFD97706),
    priorityLow: Color(0xFF94A3B8),
    // Channel containers: 15% of the brand color over `surface` #151E22,
    // pre-computed (§10 rule 4).
    channelWhatsapp: Color(0xFF25D366),
    channelWhatsappContainer: Color(0xFF17392C),
    channelWeb: Color(0xFF2563EB),
    channelWebContainer: Color(0xFF172840),
    channelMessenger: Color(0xFF0866FF),
    channelMessengerContainer: Color(0xFF122D43),
    channelInstagram: Color(0xFFE4405F),
    channelInstagramContainer: Color(0xFF34212D),
    channelEmail: Color(0xFF64748B),
    channelEmailContainer: Color(0xFF212B32),
    channelTelegram: Color(0xFF26A5E4),
    channelTelegramContainer: Color(0xFF17313D),
    channelSms: Color(0xFF7C3AED),
    channelSmsContainer: Color(0xFF242240),
    channelOther: Color(0xFF475569),
    channelOtherContainer: Color(0xFF1D262D),
    bubbleIncoming: Color(0xFF151E22),
    // Outgoing bubble keeps the brand teal in dark mode (§10 rule 2).
    bubbleOutgoing: Color(0xFF0F7E7A),
    bubbleOutgoingForeground: Color(0xFFFFFFFF),
    bubbleAi: Color(0xFF12302E),
    bubbleAiBorder: Color(0xFF1D4A47),
    bubbleSystem: Color(0xFF1C272C),
    noteBackground: Color(0xFF2A2312),
    noteForeground: Color(0xFFF3D79A),
    noteBorder: Color(0xFF6B5320),
    readTickOnPrimary: Color(0xFF9FE3DC),
    searchHighlight: Color(0xFF2E2110),
    metricAlertBorder: Color(0xFF3A474F),
    snackbarBackground: Color(0xFFE6ECEF),
    snackbarForeground: Color(0xFF0D1417),
    snackbarIconSuccess: Color(0xFF15803D),
    snackbarIconError: Color(0xFFBE123C),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}
