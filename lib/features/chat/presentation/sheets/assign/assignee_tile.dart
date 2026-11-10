import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../core/utils/arabic_normalizer.dart';
import '../../../domain/assignee.dart';

enum _Kind { agent, team, ai }

/// Gendered presence ("متاح" / "متاحة") — masculine when unknown (§5.6).
String presenceLabel(AppLocalizations l, AgentAssignee a) => switch (a.presence) {
  Presence.online => a.female ? l.as_online_f : l.as_online_m,
  Presence.busy => a.female ? l.as_busy_f : l.as_busy_m,
  Presence.away => l.as_away,
};

/// One selectable row: agent | me | team | AI (Assign spec §5.6–§5.8).
class AssigneeTile extends StatelessWidget {
  const AssigneeTile.agent({
    super.key,
    required AgentAssignee this.agent,
    required this.selected,
    required this.onTap,
    this.isMe = false,
    this.isCurrent = false,
    this.query = '',
    this.reasonSuffix,
    this.capacityErrorMax,
    this.indent = 0,
    this.showHints = true,
  }) : _kind = _Kind.agent,
       team = null,
       ai = null,
       expanded = false,
       onToggleExpand = null;

  const AssigneeTile.team({
    super.key,
    required TeamAssignee this.team,
    required this.selected,
    required this.onTap,
    required this.expanded,
    required this.onToggleExpand,
    this.isCurrent = false,
    this.query = '',
  }) : _kind = _Kind.team,
       agent = null,
       ai = null,
       isMe = false,
       reasonSuffix = null,
       capacityErrorMax = null,
       indent = 0,
       showHints = true;

  const AssigneeTile.ai({
    super.key,
    required AiAssignee this.ai,
    required this.selected,
    required this.onTap,
    this.isCurrent = false,
  }) : _kind = _Kind.ai,
       agent = null,
       team = null,
       isMe = false,
       query = '',
       reasonSuffix = null,
       capacityErrorMax = null,
       indent = 0,
       showHints = true,
       expanded = false,
       onToggleExpand = null;

  final _Kind _kind;
  final AgentAssignee? agent;
  final TeamAssignee? team;
  final AiAssignee? ai;
  final bool selected;
  final VoidCallback onTap;
  final bool isMe;

  /// Current owner → disabled with "الحالي".
  final bool isCurrent;

  /// Normalized search query, bolded in the name.
  final String query;

  /// Suggested row: "· تعاملت مع العميل سابقًا".
  final String? reasonSuffix;

  /// 422 capacity error after submit.
  final int? capacityErrorMax;

  /// Team members list (52dp).
  final double indent;
  final bool showHints;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    late final Widget leading;
    late final String name;
    String? nameNote;
    late String subtitle;
    Color subtitleColor = c.textSecondary;
    var enabled = !isCurrent;
    final badges = <Widget>[];
    double? load;
    String? helper;
    Color helperColor = c.textWarning;

    switch (_kind) {
      case _Kind.agent:
        final a = agent!;
        leading = AppAvatar(
          name: a.name,
          id: a.id,
          imageUrl: a.avatarUrl,
          presence: a.presence,
          size: AppAvatarSize.md,
          ringColor: c.surfaceElevated,
        );
        name = isMe ? l.as_me : a.name;
        if (isMe) nameNote = '(${a.firstName})';
        final second = a.presence == Presence.away && a.lastSeenAt != null
            ? l.as_last_seen(AppFormat.shortDuration(context, DateTime.now().difference(a.lastSeenAt!)))
            : l.as_open_count(a.openConversations);
        subtitle = '${presenceLabel(l, a)} · $second';
        if (reasonSuffix != null) subtitle = '$subtitle · $reasonSuffix';
        if (isCurrent) badges.add(_Tag(label: l.as_badge_current, fg: c.textSecondary, bg: c.surfaceVariant));
        if (a.atCapacity) {
          badges.add(_Tag(label: l.as_badge_capacity, fg: c.statusWaiting, bg: c.statusWaitingContainer));
        }
        load = a.load;
        if (!a.assignable) {
          enabled = false;
          subtitle = a.unassignableReason == UnassignableReason.capacity
              ? l.as_capacity_reached(a.maxConcurrent ?? a.openConversations)
              : l.as_unavailable;
        }
        if (capacityErrorMax != null) {
          helper = l.as_capacity_reached(capacityErrorMax!);
          helperColor = c.textError;
        } else if (selected && showHints && enabled) {
          // Busy / away stay selectable, with a heads-up (§6).
          helper = switch (a.presence) {
            Presence.busy => a.female ? l.as_busy_hint_f : l.as_busy_hint,
            Presence.away => a.female ? l.as_away_hint_f : l.as_away_hint,
            Presence.online => null,
          };
        }
      case _Kind.team:
        final tm = team!;
        leading = _TeamAvatar(id: tm.id);
        name = tm.name;
        if (tm.availableCount == 0 && tm.membersCount > 0) {
          subtitle = l.as_team_none_available;
          subtitleColor = c.textWarning;
        } else {
          final routing = switch (tm.routing) {
            TeamRouting.leastBusy => l.as_routing_least,
            TeamRouting.roundRobin => l.as_routing_rr,
            TeamRouting.manual => l.as_routing_manual,
          };
          subtitle = '${l.as_members(tm.membersCount)} · $routing';
          if (tm.availableCount < tm.membersCount) subtitle = '$subtitle · ${l.as_available_count(tm.availableCount)}';
        }
        if (isCurrent) badges.add(_Tag(label: l.as_badge_current, fg: c.textSecondary, bg: c.surfaceVariant));
      case _Kind.ai:
        leading = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
          child: AppIcon(AppIcons.ai, color: c.primary),
        );
        name = l.as_ai_name;
        subtitle = l.as_ai_sub;
        if (!ai!.available) {
          enabled = false;
          subtitle = l.as_ai_unavailable;
        }
        if (isCurrent) badges.add(_Tag(label: l.as_badge_current, fg: c.textSecondary, bg: c.surfaceVariant));
    }

    final titleStyle = t.listTitle.copyWith(fontSize: 14.5, color: c.textPrimary);
    final range = _kind == _Kind.ai ? null : ArabicNormalizer.matchRange(name, query);
    final title = Text.rich(
      TextSpan(
        children: [
          if (range == null)
            TextSpan(text: name)
          else ...[
            TextSpan(text: name.substring(0, range.$1)),
            TextSpan(
              text: name.substring(range.$1, range.$2),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: name.substring(range.$2)),
          ],
          if (nameNote != null)
            TextSpan(
              text: ' $nameNote',
              style: t.caption.copyWith(color: c.textTertiary),
            ),
        ],
      ),
      style: titleStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final semantics = [name, ?nameNote, if (isCurrent) l.as_badge_current, subtitle, ?helper].join('، ');

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: _RowShell(
        selected: selected,
        enabled: enabled,
        onTap: enabled ? onTap : null,
        indent: indent,
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(child: title),
                      for (final b in badges) ...[const SizedBox(width: 6), b],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.bodySmall.copyWith(fontSize: 12.5, color: subtitleColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (load != null && enabled) ...[const SizedBox(height: 5), _LoadBar(load: load)],
                  if (helper != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(helper, style: t.caption.copyWith(color: helperColor)),
                    ),
                ],
              ),
            ),
            if (onToggleExpand != null) _ExpandButton(team: team!, expanded: expanded, onTap: onToggleExpand!),
            const SizedBox(width: AppSpacing.sm),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Row ≥ 60, V10, 40% when disabled; a 200ms `primaryContainer` flash on
/// select (none under reduce motion).
class _RowShell extends StatefulWidget {
  const _RowShell({
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.child,
    this.indent = 0,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget child;
  final double indent;

  @override
  State<_RowShell> createState() => _RowShellState();
}

class _RowShellState extends State<_RowShell> {
  int _flash = 0;

  @override
  void didUpdateWidget(_RowShell old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _flash++;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_flash),
            tween: Tween(begin: _flash == 0 || reduced ? 0 : 1, end: 0),
            duration: const Duration(milliseconds: 200),
            builder: (_, v, child) => Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: EdgeInsetsDirectional.only(
                start: widget.indent + AppSpacing.xs,
                end: AppSpacing.xs,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: c.primaryContainer.withValues(alpha: v),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Radio 26: unselected 2dp `borderStrong` ring; selected = filled
/// `primary` with a white check 13 (scale 0.6→1, 150ms).
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    return SizedBox.square(
      dimension: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.borderStrong, width: 2),
            ),
          ),
          AnimatedScale(
            scale: selected ? 1 : 0.6,
            duration: reduced ? Duration.zero : AppMotion.fast,
            curve: AppMotion.standard,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: reduced ? Duration.zero : AppMotion.fast,
              child: Container(
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.check, size: AppIconSize.xs, color: c.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3dp × 64 load bar: `success` < 60%, `warning` 60–90%, `error` ≥ 90%.
class _LoadBar extends StatelessWidget {
  const _LoadBar({required this.load});

  final double load;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = load >= 0.9 ? c.error : (load >= 0.6 ? c.warning : c.success);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          width: 64,
          height: 3,
          child: Stack(
            children: [
              Container(color: c.surfaceVariant),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: load.clamp(0.0, 1.0),
                child: Container(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
    child: Text(label, style: context.text.tagLabel.copyWith(color: fg)),
  );
}

/// 40 rounded square (radius 12), hue from the team id (DS §3.9), users 20.
class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    var sum = 0;
    for (final u in id.codeUnits) {
      sum = (sum * 31 + u) % 360;
    }
    final hue = sum.toDouble();
    final bg = HSLColor.fromAHSL(1, hue, 0.5, c.isDark ? 0.22 : 0.92).toColor();
    final fg = HSLColor.fromAHSL(1, hue, 0.55, c.isDark ? 0.75 : 0.35).toColor();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: AppIcon(AppIcons.team, color: fg),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.team, required this.expanded, required this.onTap});

  final TeamAssignee team;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      expanded: expanded,
      label: context.l10n.as_expand_team(team.name),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox.square(
          dimension: 40,
          child: AnimatedRotation(
            // Points to the end side; rotates 90° to point down when open.
            turns: expanded ? (rtl ? -0.25 : 0.25) : 0,
            duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.normal,
            child: AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.textTertiary),
          ),
        ),
      ),
    );
  }
}
