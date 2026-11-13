import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wd_api.dart';
import '../../core/api/wd_api_provider.dart';
import '../../core/data/data.dart';
import '../../core/data/team_directory.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import 'channels_screen.dart' show webPanelPage;
import 'widgets/account_sheets.dart' show openExternal;

/// "+" on the Team screen (admins): add a user or create a team, the same
/// two forms as the web Users / Teams pages.
Future<void> showTeamAddMenu(BuildContext context) async {
  final l = context.l10n;
  final c = context.colors;
  final dir = ProviderScope.containerOf(context).read(teamDirectoryProvider);
  final seats = dir.seatsMax == null ? null : l.team_seats(dir.seatsUsed, dir.seatsMax!);
  final pick = await AppBottomSheet.show<int>(
    context,
    title: l.team_add,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Still tappable when blocked: the tap explains why (plan limit).
        Opacity(
          opacity: dir.canAddUser ? 1 : 0.5,
          child: SettingsTile(
            icon: AppIcons.assign,
            iconBackground: c.primaryContainer,
            iconColor: c.primary,
            title: l.team_add_user,
            subtitle: !dir.canAddUser
                ? l.team_seats_full(dir.seatsMax ?? dir.seatsUsed)
                : (seats == null ? l.team_add_user_sub : '${l.team_add_user_sub} · $seats'),
            onTap: () => Navigator.pop(ctx, 0),
          ),
        ),
        Opacity(
          opacity: dir.teamsEnabled ? 1 : 0.5,
          child: SettingsTile(
            icon: AppIcons.team,
            iconBackground: c.infoContainer,
            iconColor: c.info,
            title: l.team_add_team,
            subtitle: dir.teamsEnabled ? l.team_add_team_sub : l.team_teams_not_in_plan,
            onTap: () => Navigator.pop(ctx, 1),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
  if (pick == null || !context.mounted) return;
  if (pick == 0 && !dir.canAddUser) {
    await _showUpgrade(context, l.team_seats_full(dir.seatsMax ?? dir.seatsUsed));
    return;
  }
  if (pick == 1 && !dir.teamsEnabled) {
    await _showUpgrade(context, l.team_teams_not_in_plan);
    return;
  }
  if (pick == 0) {
    await AppBottomSheet.showExpanded<void>(
      context,
      title: l.team_add_user,
      builder: (ctx, controller) => _AddUserForm(controller: controller),
    );
  } else {
    await AppBottomSheet.showExpanded<void>(
      context,
      title: l.team_add_team,
      builder: (ctx, controller) => _CreateTeamForm(controller: controller),
    );
  }
}

/// Plan limit reached: say so and offer the web billing page.
Future<void> _showUpgrade(BuildContext context, String body) async {
  final l = context.l10n;
  final go = await AppDialog.confirm(
    context,
    title: l.team_limit_title,
    body: body,
    confirmLabel: l.team_upgrade,
    cancelLabel: l.common_cancel,
    icon: AppIcons.lock,
  );
  if (go && context.mounted) {
    final role = ProviderScope.containerOf(context).read(currentAgentProvider).role;
    await openExternal(context, webPanelPage(role, 'billing'));
  }
}

/// Field errors from a 422 `details` map ({field: [message]}).
String? _fieldError(Map<String, dynamic> details, String field) {
  final v = details[field];
  if (v is List && v.isNotEmpty) return '${v.first}';
  return null;
}

Widget _sectionLabel(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(text, style: context.text.h6.copyWith(fontWeight: FontWeight.w800)),
    );

/// Multi-select chip (teams / members).
class _PickChip extends StatelessWidget {
  const _PickChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? c.primaryContainer : c.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: selected ? c.primary : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[AppIcon(AppIcons.check, dp: 14, color: c.primary), const SizedBox(width: 5)],
              Text(
                label,
                style: context.text.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? c.primary : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Add user ----------------------------------------------------------------

class _AddUserForm extends ConsumerStatefulWidget {
  const _AddUserForm({required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<_AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends ConsumerState<_AddUserForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AgentRole _role = AgentRole.agent;
  final Set<String> _teams = {};
  bool _saving = false;
  Map<String, dynamic> _errors = const {};
  String? _formError;

  /// Set once created: the sign-in details are shown instead of the form.
  ({String name, String email, String password, bool emailed})? _created;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final local = <String, dynamic>{
      if (name.isEmpty) 'name': [l.team_err_required],
      if (email.isEmpty) 'email': [l.team_err_required],
    };
    if (local.isNotEmpty) {
      setState(() => _errors = local);
      return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
      _formError = null;
    });
    try {
      final r = await ref.read(wdApiRequiredProvider).post('team/users', body: {
        'name': name,
        'email': email,
        'role': _role.name,
        if (_password.text.isNotEmpty) 'password': _password.text,
        'team_ids': _teams.toList(),
      });
      final d = r.map;
      HapticFeedback.lightImpact();
      await ref.read(teamDirectoryProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _created = (
          name: '${d['name'] ?? name}',
          email: '${d['email'] ?? email}',
          password: '${d['temporary_password'] ?? ''}',
          emailed: d['password_emailed'] == true,
        );
      });
    } on WdApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.status == 422 && e.details.isNotEmpty) {
          _errors = e.details;
        } else if (e.code == 'plan_limit') {
          _formError = l.team_err_limit;
          ref.read(teamDirectoryProvider.notifier).refresh();
        } else {
          _formError = e.message ?? l.team_err_generic;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    if (created != null) return _credentials(context, created);

    final l = context.l10n;
    final c = context.colors;
    final dir = ref.watch(teamDirectoryProvider);

    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        AppTextField(
          label: l.team_f_name,
          controller: _name,
          error: _fieldError(_errors, 'name'),
          maxLength: 150,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() => _errors = {..._errors}..remove('name')),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l.team_f_email,
          controller: _email,
          error: _fieldError(_errors, 'email'),
          enabled: !_saving,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _errors = {..._errors}..remove('email')),
        ),
        _sectionLabel(context, l.team_f_role),
        AppSegmented<AgentRole>(
          height: 40,
          selected: _role,
          onChanged: _saving ? (_) {} : (r) => setState(() => _role = r),
          segments: [
            for (final r in const [AgentRole.agent, AgentRole.supervisor, AgentRole.admin])
              AppSegment(value: r, label: r.label(l)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: l.team_f_password,
          controller: _password,
          error: _fieldError(_errors, 'password'),
          helper: l.team_f_password_help,
          enabled: !_saving,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _errors = {..._errors}..remove('password')),
        ),
        if (dir.teamsEnabled && dir.teams.isNotEmpty) ...[
          _sectionLabel(context, l.team_f_teams),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in dir.teams)
                _PickChip(
                  label: t.name,
                  selected: _teams.contains(t.id),
                  onTap: () => setState(() => _teams.contains(t.id) ? _teams.remove(t.id) : _teams.add(t.id)),
                ),
            ],
          ),
        ],
        if (_formError != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(_formError!, style: context.text.bodySmall.copyWith(color: c.error)),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: l.team_create_user_btn, onPressed: _saving ? null : _submit, loading: _saving, expand: true),
      ],
    );
  }

  Widget _credentials(BuildContext context, ({String name, String email, String password, bool emailed}) u) {
    final l = context.l10n;
    final c = context.colors;
    final t = context.text;
    final details = '${l.team_f_email}: ${u.email}\n${l.team_f_password_short}: ${u.password}';
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.successContainer, shape: BoxShape.circle),
            child: AppIcon(AppIcons.check, dp: 28, color: c.success),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l.team_user_created(u.name), style: t.h5, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          u.emailed ? '${l.team_user_created_pw} ${l.team_user_created_emailed}' : l.team_user_created_pw,
          style: t.bodySmall.copyWith(color: c.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: SelectableText(details, textDirection: TextDirection.ltr, style: t.bodyMedium),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l.team_copy_credentials,
          icon: AppIcons.copy,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: details));
            AppSnackbar.show(context, message: l.team_copied, kind: SnackKind.success);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: l.common_done, expand: true, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

// ---- Create team ---------------------------------------------------------------

class _CreateTeamForm extends ConsumerStatefulWidget {
  const _CreateTeamForm({required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<_CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends ConsumerState<_CreateTeamForm> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _pool = false;
  final Set<String> _members = {};
  bool _saving = false;
  Map<String, dynamic> _errors = const {};
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _errors = {'name': [l.team_err_required]});
      return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
      _formError = null;
    });
    try {
      final desc = _description.text.trim();
      await ref.read(wdApiRequiredProvider).post('team/teams', body: {
        'name': name,
        'description': desc.isEmpty ? null : desc,
        'receives_pool': _pool,
        'member_ids': _members.toList(),
      });
      HapticFeedback.lightImpact();
      await ref.read(teamDirectoryProvider.notifier).refresh();
      if (!mounted) return;
      AppSnackbar.show(context, message: l.team_team_created(name), kind: SnackKind.success);
      Navigator.of(context).pop();
    } on WdApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.status == 422 && e.details.isNotEmpty) {
          _errors = e.details;
        } else if (e.code == 'module_unavailable') {
          _formError = l.team_teams_not_in_plan;
          ref.read(teamDirectoryProvider.notifier).refresh();
        } else {
          _formError = e.message ?? l.team_err_generic;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = context.text;
    final members = ref.watch(teamDirectoryProvider).members;

    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        AppTextField(
          label: l.team_f_team_name,
          controller: _name,
          error: _fieldError(_errors, 'name'),
          maxLength: 100,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _errors = {..._errors}..remove('name')),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: l.team_f_description,
          controller: _description,
          error: _fieldError(_errors, 'description'),
          maxLength: 250,
          minLines: 2,
          maxLines: 4,
          enabled: !_saving,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.team_f_pool, style: t.listTitle),
                  Text(l.team_f_pool_help, style: t.bodySmall.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppSwitch(
              value: _pool,
              semanticLabel: l.team_f_pool,
              onChanged: _saving ? null : (v) => setState(() => _pool = v),
            ),
          ],
        ),
        if (members.isNotEmpty) ...[
          _sectionLabel(context, l.team_f_members),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in members)
                _PickChip(
                  label: m.name,
                  selected: _members.contains(m.id),
                  onTap: () => setState(() => _members.contains(m.id) ? _members.remove(m.id) : _members.add(m.id)),
                ),
            ],
          ),
        ],
        if (_formError != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(_formError!, style: t.bodySmall.copyWith(color: c.error)),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: l.team_create_team_btn, onPressed: _saving ? null : _submit, loading: _saving, expand: true),
      ],
    );
  }
}
