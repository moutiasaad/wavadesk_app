import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/assign_controller.dart';
import '../../../../../core/utils/arabic_normalizer.dart';
import '../../../domain/assign_button_label.dart';
import '../../../domain/assignee.dart';
import 'assign_footer.dart';
import 'assign_header.dart';
import 'assign_live_banner.dart';
import 'assignee_filter_chips.dart';
import 'assignee_search_field.dart';
import 'assignee_tile.dart';
import 'bulk_assign_errors_sheet.dart';
import 'suggested_assignee.dart';
import 'team_members_expansion.dart';

/// "إسناد المحادثة" (Assign spec, frame 07). One conversation or bulk.
/// Shows the result snackbar (with Undo / Retry / errors) on [context].
Future<AssignResult?> showAssignSheet(
  BuildContext context,
  WidgetRef ref, {
  required Iterable<String> conversationIds,
  AssignSource? source,
}) async {
  final ids = conversationIds.toList();
  if (ids.isEmpty) return null;
  final args = AssignArgs(
    conversationIds: ids,
    source: source ?? (ids.length > 1 ? AssignSource.bulk : AssignSource.menu),
  );
  // Undo / Retry run after the sheet closes: keep the controller alive.
  final keepAlive = ref.listenManual(assignControllerProvider(args), (_, _) {});
  final out = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    sheetAnimationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(duration: Duration(milliseconds: 300), reverseDuration: Duration(milliseconds: 220)),
    builder: (ctx) => _AssignSheet(args: args),
  );
  if (!context.mounted) {
    keepAlive.close();
    return null;
  }
  final result = await _handleOutcome(context, ref, out);
  // Long enough for the 5s Undo snackbar (and a retry).
  Timer(const Duration(seconds: 8), keepAlive.close);
  return result;
}

const _resolvedSignal = 'resolved';

Future<AssignResult?> _handleOutcome(BuildContext context, WidgetRef ref, Object? out) async {
  final l = context.l10n;
  switch (out) {
    case _resolvedSignal:
      AppSnackbar.show(context, message: l.as_resolved_live);
      return null;
    case AssignSucceeded(:final result, :final undo):
      final bulk = result.total > 1;
      final String message;
      if (bulk) {
        message = l.as_done_bulk(result.succeeded.length, result.total);
      } else if (result.unassigned) {
        message = l.as_unassigned_done;
      } else if (result.target is TeamTarget && result.assigneeName == (result.target as TeamTarget).team.name) {
        message = l.as_queued_team(result.assigneeName);
      } else {
        message = l.as_done(result.assigneeName);
      }
      if (result.claimed) return result; // the chat itself shows the claim
      if (bulk && result.failures.isNotEmpty) {
        AppSnackbar.show(
          context,
          message: message,
          kind: result.succeeded.isEmpty ? SnackKind.error : SnackKind.info,
          actionLabel: l.as_show_errors,
          onAction: () => showBulkAssignErrorsSheet(context, ref, result.failures),
        );
      } else if (undo != null) {
        AppSnackbar.undo(context, message: message, onUndo: undo);
      } else {
        AppSnackbar.show(context, message: message, kind: SnackKind.success);
      }
      return result;
    case AssignFailed(:final code, :final retry):
      if (code == 'forbidden') {
        AppSnackbar.show(context, message: l.as_forbidden, kind: SnackKind.error);
        return null;
      }
      AppSnackbar.show(
        context,
        message: l.as_error,
        kind: SnackKind.error,
        actionLabel: l.as_retry,
        onAction: () async {
          final again = await retry();
          if (context.mounted) await _handleOutcome(context, ref, again);
        },
      );
      return null;
    default:
      return null;
  }
}

class _AssignSheet extends ConsumerStatefulWidget {
  const _AssignSheet({required this.args});

  final AssignArgs args;

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  final _note = TextEditingController();
  final _search = TextEditingController();
  final _titleFocus = FocusNode(debugLabel: 'assign-title');
  final _sheet = DraggableScrollableController();
  double _extent = 0.82;

  static const _initial = 0.82;

  AssignController get _ctrl => ref.read(assignControllerProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _note.dispose();
    _search.dispose();
    _titleFocus.dispose();
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _submit({bool unassign = false}) async {
    final out = unassign ? await _ctrl.unassign(_note.text) : await _ctrl.submit(_note.text);
    if (!mounted || out is AssignStayOpen) return;
    Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(assignControllerProvider(widget.args));
    final ctrl = _ctrl;
    ref.listen(assignControllerProvider(widget.args).select((x) => x.resolvedWhileOpen), (_, v) {
      if (v) Navigator.of(context).pop(_resolvedSignal);
    });

    final p = s.payload;
    final bulk = widget.args.bulk;
    final current = s.expectedCurrent;
    String? currentName;
    if (!bulk && current != null && p != null) {
      currentName = switch (current.type) {
        AssigneeType.agent => p.agentById(current.id)?.name,
        AssigneeType.team => p.teamById(current.id)?.name,
        AssigneeType.ai => l.as_ai_name,
      };
    }
    final unassigned = current == null;
    final label = assignButtonLabel(
      l,
      target: s.selected,
      count: widget.args.conversationIds.length,
      takenLive: s.takenLiveBy != null,
      unassigned: unassigned,
    );
    final radius = AppRadius.sheet * (1 - ((_extent - _initial) / (1 - _initial)).clamp(0.0, 1.0));

    return PopScope(
      // Not dismissible while the request is in flight (§5.10).
      canPop: !s.submitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            if ((n.extent - _extent).abs() > 0.005) setState(() => _extent = n.extent);
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _sheet,
            expand: false,
            initialChildSize: _initial,
            minChildSize: 0.5,
            maxChildSize: 1,
            snap: true,
            snapSizes: const [_initial],
            builder: (ctx, scroll) => Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: l.as_title,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                  boxShadow: context.shadows.high,
                ),
                padding: const EdgeInsets.fromLTRB(18, AppSpacing.sm, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.borderStrong,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AssignHeader(
                      title: bulk ? l.as_title_bulk(widget.args.conversationIds.length) : l.as_title,
                      subtitle: currentName == null ? null : l.as_current(currentName),
                      focusNode: _titleFocus,
                      onClose: s.submitting ? null : () => Navigator.of(context).maybePop(),
                    ),
                    AssigneeSearchField(controller: _search, onChanged: ctrl.setQuery),
                    const SizedBox(height: AppSpacing.xs),
                    if (ctrl.showFilters)
                      AssigneeFilterChips(
                        filter: s.filter,
                        availableCount: ctrl.availableCount,
                        onChanged: ctrl.setFilter,
                      ),
                    if (s.takenLiveBy != null) AssignLiveBanner(name: s.takenLiveBy!),
                    Expanded(child: _list(context, s, scroll)),
                    AssignFooter(
                      note: _note,
                      label: label,
                      loading: s.submitting,
                      offline: s.offline,
                      onPrimary: s.selected == null ? null : () => _submit(),
                      onUnassign: !bulk && !unassigned && current.type != AssigneeType.ai
                          ? () => _submit(unassign: true)
                          : null,
                    ),
                    SizedBox(height: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text, [int? count]) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(
              text,
              style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
            ),
            if (count != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Text('$count', style: t.caption.copyWith(color: c.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, AssignState s, ScrollController scroll) {
    final c = context.colors;
    final l = context.l10n;
    final ctrl = _ctrl;
    final p = s.payload;

    if (p == null) {
      if (s.loadFailed) {
        return ListView(
          controller: scroll,
          children: [
            EmptyState(
              icon: s.offline ? AppIcons.wifiOff : AppIcons.alert,
              title: s.offline ? l.as_offline : l.as_load_error,
              actionLabel: l.as_retry,
              onAction: ctrl.load,
            ),
          ],
        );
      }
      return ListView(
        controller: scroll,
        children: [
          const SizedBox(height: AppSpacing.md),
          AppSkeleton.list(rows: 5),
        ],
      );
    }

    final q = ArabicNormalizer.normalize(s.query);
    final agents = ctrl.visibleAgents();
    final teams = ctrl.visibleTeams();
    final showMe = ctrl.showMe;
    final showAi = ctrl.showAi;
    final sel = s.selected?.key;
    final meId = p.me.id;

    // Suggested only on the unfiltered list (§5.5).
    final sug = p.suggested;
    final sugAgent = sug != null && sug.ref.type == AssigneeType.agent && q.isEmpty && s.filter == AssignFilter.all
        ? p.agentById(sug.ref.id)
        : null;

    void selectAgent(AgentAssignee a, {bool fromSuggestion = false}) =>
        ctrl.select(AgentTarget(a, isMe: a.id == meId), fromSuggestion: fromSuggestion);

    final children = <Widget>[
      if (sugAgent != null && sugAgent.assignable && !ctrl.isCurrent(sug!.ref))
        SuggestedAssigneeRow(
          suggestion: sug,
          agent: sugAgent,
          isMe: sugAgent.id == meId,
          selected: sel == 'agent:${sugAgent.id}',
          onTap: () => selectAgent(sugAgent, fromSuggestion: true),
        ),
      if (showMe || agents.isNotEmpty) ...[
        _sectionHeader(context, l.as_teammates, agents.length + (showMe ? 1 : 0)),
        if (showMe)
          AssigneeTile.agent(
            agent: p.me,
            isMe: true,
            selected: sel == 'agent:$meId',
            query: q,
            capacityErrorMax: s.capacityErrorKey == 'agent:$meId' ? s.capacityMax : null,
            onTap: () => selectAgent(p.me),
          ),
        for (final a in agents)
          AssigneeTile.agent(
            agent: a,
            selected: sel == 'agent:${a.id}',
            isCurrent: ctrl.isCurrent(AssigneeRef(AssigneeType.agent, a.id)),
            query: q,
            capacityErrorMax: s.capacityErrorKey == 'agent:${a.id}' ? s.capacityMax : null,
            onTap: () => selectAgent(a),
          ),
      ],
      if (teams.isNotEmpty) ...[
        _sectionHeader(context, l.as_teams, teams.length),
        for (final t in teams) ...[
          AssigneeTile.team(
            team: t,
            selected: sel == 'team:${t.id}',
            isCurrent: ctrl.isCurrent(AssigneeRef(AssigneeType.team, t.id)),
            query: q,
            expanded: s.expandedTeams.contains(t.id),
            onToggleExpand: t.members.isEmpty ? null : () => ctrl.toggleTeam(t.id),
            onTap: () => ctrl.select(TeamTarget(t)),
          ),
          if (t.members.isNotEmpty)
            TeamMembersExpansion(
              team: t,
              expanded: s.expandedTeams.contains(t.id),
              meId: meId,
              selectedKey: sel,
              query: q,
              isCurrent: (a) => ctrl.isCurrent(AssigneeRef(AssigneeType.agent, a.id)),
              onSelect: selectAgent,
            ),
        ],
      ],
      if (showAi) ...[
        _sectionHeader(context, l.as_ai_section),
        AssigneeTile.ai(
          ai: p.ai,
          selected: sel == 'ai:ai',
          isCurrent: ctrl.isCurrent(const AssigneeRef(AssigneeType.ai, 'ai')),
          onTap: () => ctrl.select(const AiTarget()),
        ),
      ],
    ];

    final empty = !showMe && agents.isEmpty && teams.isEmpty && !showAi;
    if (empty) {
      if (s.filter == AssignFilter.available && q.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyState(
              icon: AppIcons.users,
              title: l.as_none_available,
              actionLabel: l.as_show_all,
              actionVariant: AppButtonVariant.text,
              onAction: () => ctrl.setFilter(AssignFilter.all),
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
            child: Text(l.as_no_results(s.query.trim()), style: context.text.bodySmall.copyWith(color: c.textTertiary)),
          ),
        );
      }
    }

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      children: children,
    );
  }
}
