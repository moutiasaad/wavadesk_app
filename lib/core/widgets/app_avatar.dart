import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'channel_badge.dart';

/// `xxs` (16) is the inline assignee chip in inbox row tags (Inbox spec §4.5.3).
enum AppAvatarSize { xxs, xs, sm, md, lg, xl, xxl }

extension on AppAvatarSize {
  double get dp => switch (this) {
    AppAvatarSize.xxs => 16,
    AppAvatarSize.xs => 24,
    AppAvatarSize.sm => 28,
    AppAvatarSize.md => 40,
    AppAvatarSize.lg => 50,
    AppAvatarSize.xl => 76,
    AppAvatarSize.xxl => 88,
  };
  double get font => switch (this) {
    AppAvatarSize.xxs => 9,
    AppAvatarSize.xs => 11,
    AppAvatarSize.sm => 12,
    AppAvatarSize.md => 15,
    AppAvatarSize.lg => 18,
    AppAvatarSize.xl => 28,
    AppAvatarSize.xxl => 32,
  };
  double get presenceDot => switch (this) {
    AppAvatarSize.xxs => 6,
    AppAvatarSize.xs => 8,
    AppAvatarSize.sm => 9,
    AppAvatarSize.md => 12,
    AppAvatarSize.lg => 13,
    AppAvatarSize.xl => 16,
    AppAvatarSize.xxl => 18,
  };
}

enum _AvatarKind { person, team, ai }

/// §8.10. Photo or deterministic-initials fallback (§3.9). A customer avatar
/// may carry a [channel] badge, an agent avatar a [presence] dot — never both.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    required this.id,
    this.size = AppAvatarSize.md,
    this.imageUrl,
    this.channel,
    this.presence,
    this.ringColor,
  }) : assert(channel == null || presence == null, 'Never show both badges'),
       _kind = _AvatarKind.person;

  const AppAvatar.team({super.key, this.size = AppAvatarSize.md})
    : name = '',
      id = '',
      imageUrl = null,
      channel = null,
      presence = null,
      ringColor = null,
      _kind = _AvatarKind.team;

  const AppAvatar.ai({super.key, this.size = AppAvatarSize.md})
    : name = '',
      id = '',
      imageUrl = null,
      channel = null,
      presence = null,
      ringColor = null,
      _kind = _AvatarKind.ai;

  final String name;

  /// Stable id used to pick the hue.
  final String id;
  final AppAvatarSize size;
  final String? imageUrl;
  final Channel? channel;
  final Presence? presence;

  /// Ring color around badges; match the surface the avatar sits on.
  final Color? ringColor;
  final _AvatarKind _kind;

  static int _hue(String id) {
    var h = 0;
    for (final unit in id.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h % 360;
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = size.dp;

    Widget face;
    switch (_kind) {
      case _AvatarKind.team:
        face = Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: AppIcon(AppIcons.team, dp: d * 0.45, color: c.textSecondary),
        );
        return Semantics(label: context.l10n.a11y_team_avatar, child: face);
      case _AvatarKind.ai:
        face = Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
          child: AppIcon(AppIcons.ai, dp: d * 0.45, color: c.primary),
        );
        return Semantics(label: context.l10n.a11y_ai_avatar, child: face);
      case _AvatarKind.person:
        final hue = _hue(id).toDouble();
        final bg = c.isDark
            ? HSLColor.fromAHSL(1, hue, 0.30, 0.22).toColor()
            : HSLColor.fromAHSL(1, hue, 0.55, 0.92).toColor();
        final fg = c.isDark
            ? HSLColor.fromAHSL(1, hue, 0.60, 0.80).toColor()
            : HSLColor.fromAHSL(1, hue, 0.45, 0.30).toColor();
        face = ClipOval(
          child: Container(
            width: d,
            height: d,
            color: bg,
            alignment: Alignment.center,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: d,
                    height: d,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initials(context, fg),
                  )
                : _initials(context, fg),
          ),
        );
    }

    final ring = ringColor ?? c.background;
    Widget? corner;
    if (channel != null) {
      corner = ChannelBadge.avatar(channel: channel!, size: size.dp >= 50 ? 18 : 16, ringColor: ring);
    } else if (presence != null) {
      final dot = size.presenceDot;
      corner = Container(
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: presence!.color(c),
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 2),
        ),
      );
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            face,
            if (corner != null)
              PositionedDirectional(end: channel != null ? -2 : -1, bottom: channel != null ? -2 : -1, child: corner),
          ],
        ),
      ),
    );
  }

  Widget _initials(BuildContext context, Color fg) => Text(
    _initial(name),
    style: TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: size.font,
      fontWeight: FontWeight.w700,
      height: 1,
      color: fg,
    ),
    textScaler: TextScaler.noScaling,
  );
}
