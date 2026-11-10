import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../../domain/ai_agent_config.dart';
import '../ai_config_gate.dart';

/// "أساليب إعادة الصياغة للفريق" (AI Agent spec §4.8): the styles that feed
/// the Rewrite sheet's "أساليب فريقك" (spec 06 §5.4.2).
class TeamStylesScreen extends ConsumerWidget {
  const TeamStylesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final config = ref.watch(aiAgentControllerProvider).config;
    // "No styles" only once the config has loaded.
    if (config == null) return AiConfigGate(title: l.ai_team_styles, builder: (_) => const SizedBox.shrink());
    final styles = config.rewriteStyles;
    final canEdit = config.canEdit;

    Future<void> delete(RewriteStyle s) async {
      final ok = await AppDialog.confirm(
        context,
        title: l.ai_style_delete,
        body: s.name,
        confirmLabel: l.ai_style_delete,
        icon: AppIcons.delete,
      );
      if (!ok || !context.mounted) return;
      final done = await ref.read(aiAgentControllerProvider.notifier).removeStyle(s.id);
      if (!done && context.mounted) AppSnackbar.show(context, message: l.ai_save_failed, kind: SnackKind.error);
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.ai_team_styles,
        actions: [
          if (canEdit)
            AppIconButton(
              icon: AppIcons.plus,
              semanticLabel: l.ai_style_add,
              onPressed: () => _showAddSheet(context, ref),
            ),
        ],
      ),
      body: styles.isEmpty
          ? EmptyState(
              icon: AppIcons.wand,
              title: l.ai_styles_empty,
              actionLabel: canEdit ? l.ai_style_add : null,
              onAction: canEdit ? () => _showAddSheet(context, ref) : null,
            )
          : ListView(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
              children: [
                SettingsGroup(
                  children: [
                    for (final s in styles)
                      Dismissible(
                        key: ValueKey(s.id),
                        direction: canEdit ? DismissDirection.endToStart : DismissDirection.none,
                        confirmDismiss: (_) async {
                          await delete(s);
                          return false; // the list updates from the controller
                        },
                        background: Container(
                          color: c.errorContainer,
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsetsDirectional.only(end: AppSpacing.xl),
                          child: Icon(AppIcons.delete, color: c.textError),
                        ),
                        child: SettingsTile(
                          title: s.name,
                          subtitle: s.instruction,
                          icon: AppIcons.wand,
                          showChevron: false,
                          trailing: canEdit
                              ? AppIconButton(
                                  icon: AppIcons.delete,
                                  iconSize: 18,
                                  iconColor: c.textSecondary,
                                  semanticLabel: '${l.ai_style_delete} ${s.name}',
                                  onPressed: () => delete(s),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
                if (!canEdit)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(l.ai_readonly, style: t.caption.copyWith(color: c.textTertiary)),
                  ),
              ],
            ),
    );
  }

  static Future<void> _showAddSheet(BuildContext context, WidgetRef ref) {
    return AppBottomSheet.show<void>(
      context,
      title: context.l10n.ai_style_add,
      builder: (_) => const _AddStyleForm(),
    );
  }
}

class _AddStyleForm extends ConsumerStatefulWidget {
  const _AddStyleForm();

  @override
  ConsumerState<_AddStyleForm> createState() => _AddStyleFormState();
}

class _AddStyleFormState extends ConsumerState<_AddStyleForm> {
  final _name = TextEditingController();
  final _instruction = TextEditingController();
  bool _saving = false;

  bool get _valid {
    final n = _name.text.trim().length;
    final i = _instruction.text.trim().length;
    return n >= 1 && n <= 60 && i >= 5 && i <= 500;
  }

  @override
  void dispose() {
    _name.dispose();
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await ref.read(aiAgentControllerProvider.notifier).addStyle(_name.text.trim(), _instruction.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      messenger?.showSnackBar(SnackBar(content: Text(l.ai_save_failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: l.ai_style_name,
            maxLength: 60,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _instruction,
            label: l.ai_style_instruction,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: l.ai_save, expand: true, loading: _saving, onPressed: _valid && !_saving ? _save : null),
        ],
      ),
    );
  }
}
