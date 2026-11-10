import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import '../../l10n/app_localizations.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeName => Localizations.localeOf(this).languageCode;
}

// ---- Enum labels ----------------------------------------------------------------

extension ChannelLabel on Channel {
  String label(AppLocalizations l) => switch (this) {
    Channel.whatsapp => l.channel_whatsapp,
    Channel.web => l.channel_web,
    Channel.messenger => l.channel_messenger,
    Channel.instagram => l.channel_instagram,
    Channel.email => l.channel_email,
    Channel.telegram => l.channel_telegram,
    Channel.sms => l.channel_sms,
    Channel.other => l.channel_other,
  };

  IconData get glyph => switch (this) {
    Channel.whatsapp => AppIcons.whatsapp,
    Channel.web => AppIcons.webChat,
    Channel.messenger => AppIcons.messenger,
    Channel.instagram => AppIcons.instagram,
    Channel.email => AppIcons.email,
    Channel.telegram => AppIcons.telegram,
    Channel.sms => AppIcons.sms,
    Channel.other => AppIcons.otherChannel,
  };

  Color brand(AppColors c) => switch (this) {
    Channel.whatsapp => c.channelWhatsapp,
    Channel.web => c.channelWeb,
    Channel.messenger => c.channelMessenger,
    Channel.instagram => c.channelInstagram,
    Channel.email => c.channelEmail,
    Channel.telegram => c.channelTelegram,
    Channel.sms => c.channelSms,
    Channel.other => c.channelOther,
  };

  Color container(AppColors c) => switch (this) {
    Channel.whatsapp => c.channelWhatsappContainer,
    Channel.web => c.channelWebContainer,
    Channel.messenger => c.channelMessengerContainer,
    Channel.instagram => c.channelInstagramContainer,
    Channel.email => c.channelEmailContainer,
    Channel.telegram => c.channelTelegramContainer,
    Channel.sms => c.channelSmsContainer,
    Channel.other => c.channelOtherContainer,
  };
}

extension StatusLabel on ConversationStatus {
  String label(AppLocalizations l) => switch (this) {
    ConversationStatus.open => l.status_open,
    ConversationStatus.pending => l.status_pending,
    ConversationStatus.waiting => l.status_waiting,
    ConversationStatus.snoozed => l.status_snoozed,
    ConversationStatus.resolved => l.status_resolved,
    ConversationStatus.closed => l.status_closed,
    ConversationStatus.ai => l.status_ai,
  };

  Color foreground(AppColors c) => switch (this) {
    ConversationStatus.open => c.statusOpen,
    ConversationStatus.pending => c.statusPending,
    ConversationStatus.waiting => c.statusWaiting,
    ConversationStatus.snoozed => c.statusSnoozed,
    ConversationStatus.resolved => c.statusResolved,
    ConversationStatus.closed => c.statusClosed,
    ConversationStatus.ai => c.statusAi,
  };

  Color container(AppColors c) => switch (this) {
    ConversationStatus.open => c.statusOpenContainer,
    ConversationStatus.pending => c.statusPendingContainer,
    ConversationStatus.waiting => c.statusWaitingContainer,
    ConversationStatus.snoozed => c.statusSnoozedContainer,
    ConversationStatus.resolved => c.statusResolvedContainer,
    ConversationStatus.closed => c.statusClosedContainer,
    ConversationStatus.ai => c.statusAiContainer,
  };

  IconData get icon => switch (this) {
    ConversationStatus.open => AppIcons.inbox,
    ConversationStatus.pending => AppIcons.hourglass,
    ConversationStatus.waiting => AppIcons.clock,
    ConversationStatus.snoozed => AppIcons.snooze,
    ConversationStatus.resolved => AppIcons.resolve,
    ConversationStatus.closed => AppIcons.lock,
    ConversationStatus.ai => AppIcons.sparkle,
  };
}

extension PriorityLabel on Priority {
  String label(AppLocalizations l) => switch (this) {
    Priority.urgent => l.priority_urgent,
    Priority.high => l.priority_high,
    Priority.medium => l.priority_medium,
    Priority.low => l.priority_low,
  };

  Color color(AppColors c) => switch (this) {
    Priority.urgent => c.priorityUrgent,
    Priority.high => c.priorityHigh,
    Priority.medium => c.priorityMedium,
    Priority.low => c.priorityLow,
  };

  /// Filled bars in the 3-bar indicator (§8.9).
  int get bars => switch (this) {
    Priority.urgent || Priority.high => 3,
    Priority.medium => 2,
    Priority.low => 1,
  };
}

extension PresenceLabel on Presence {
  String label(AppLocalizations l) => switch (this) {
    Presence.online => l.presence_online,
    Presence.busy => l.presence_busy,
    Presence.away => l.presence_away,
  };

  Color color(AppColors c) => switch (this) {
    Presence.online => c.presenceOnline,
    Presence.busy => c.presenceBusy,
    Presence.away => c.presenceAway,
  };
}

extension RoleLabel on AgentRole {
  String label(AppLocalizations l) => switch (this) {
    AgentRole.admin => l.role_admin,
    AgentRole.supervisor => l.role_supervisor,
    AgentRole.agent => l.role_agent,
  };
}

extension MediaLabel on MessageKind {
  String label(AppLocalizations l) => switch (this) {
    MessageKind.text => '',
    MessageKind.image => l.media_image,
    MessageKind.album => l.media_album,
    MessageKind.video => l.media_video,
    MessageKind.voice => l.media_voice,
    MessageKind.file => l.media_file,
    MessageKind.location => l.media_location,
    MessageKind.contact => l.media_contact,
    MessageKind.sticker => l.media_sticker,
    MessageKind.template => l.media_template,
    MessageKind.email => l.media_email,
    MessageKind.deleted => l.media_deleted,
    MessageKind.unsupported => l.media_unsupported,
  };

  IconData get icon => switch (this) {
    MessageKind.text => AppIcons.webChat,
    MessageKind.image => AppIcons.image,
    MessageKind.album => AppIcons.album,
    MessageKind.video => AppIcons.video,
    MessageKind.voice => AppIcons.mic,
    MessageKind.file => AppIcons.file,
    MessageKind.location => AppIcons.location,
    MessageKind.contact => AppIcons.contactCard,
    MessageKind.sticker => AppIcons.sticker,
    MessageKind.template => AppIcons.template,
    MessageKind.email => AppIcons.mail,
    MessageKind.deleted => AppIcons.block,
    MessageKind.unsupported => AppIcons.alert,
  };
}

// ---- Time formatting --------------------------------------------------------------

abstract final class AppFormat {
  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Conversation-list timestamp: time today, "أمس", weekday this week,
  /// otherwise a short date.
  static String listTimestamp(BuildContext context, DateTime t) {
    final l = context.l10n;
    final locale = context.localeName;
    final now = DateTime.now();
    if (_sameDay(t, now)) return intl.DateFormat.Hm(locale).format(t);
    if (_sameDay(t, now.subtract(const Duration(days: 1)))) return l.time_yesterday;
    if (now.difference(t).inDays < 7) return intl.DateFormat.EEEE(locale).format(t);
    return intl.DateFormat('d/M', locale).format(t);
  }

  /// "قبل دقيقتين" — used for notifications and screen-reader labels.
  static String relative(BuildContext context, DateTime t) {
    final l = context.l10n;
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return l.time_now;
    if (d.inHours < 1) return l.time_minutes_ago(d.inMinutes);
    if (d.inDays < 1) return l.time_hours_ago(d.inHours);
    return l.time_days_ago(d.inDays);
  }

  /// Bubble timestamp (always HH:mm).
  static String time(BuildContext context, DateTime t) => intl.DateFormat.Hm(context.localeName).format(t);

  /// Chat day divider: "اليوم", "أمس", or a full date.
  static String dayLabel(BuildContext context, DateTime t) {
    final l = context.l10n;
    final now = DateTime.now();
    if (_sameDay(t, now)) return l.time_today;
    if (_sameDay(t, now.subtract(const Duration(days: 1)))) return l.time_yesterday;
    return intl.DateFormat.yMMMMd(context.localeName).format(t);
  }

  /// Compact duration: "14 د", "2 س", "3 ي".
  static String shortDuration(BuildContext context, Duration d) {
    final l = context.l10n;
    if (d.inHours < 1) return l.duration_minutes_short(d.inMinutes.clamp(1, 59));
    if (d.inDays < 1) return l.duration_hours_short(d.inHours);
    return l.duration_days_short(d.inDays);
  }

  /// Voice-note length "0:24".
  static String clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static String date(BuildContext context, DateTime t) => intl.DateFormat.yMMMd(context.localeName).format(t);

  static String number(BuildContext context, num n) => intl.NumberFormat.decimalPattern(context.localeName).format(n);

  static String percent(BuildContext context, double v) =>
      intl.NumberFormat.percentPattern(context.localeName).format(v);
}

/// Bidi isolation for LTR fragments (phone numbers, emails, order IDs) inside
/// Arabic text (§11).
String ltr(String s) => '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';
