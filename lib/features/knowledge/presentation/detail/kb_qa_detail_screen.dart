import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/state/load_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../data/kb_api.dart';
import '../../domain/kb_entry.dart';
import '../kb_media_view.dart';
import 'kb_usage_card.dart';

enum _Menu { toggle, copy, delete }

/// Q&A detail `/knowledge/:id` (Knowledge Base spec §6.1).
class KbQaDetailScreen extends ConsumerStatefulWidget {
  const KbQaDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<KbQaDetailScreen> createState() => _KbQaDetailScreenState();
}

class _KbQaDetailScreenState extends ConsumerState<KbQaDetailScreen> {
  // Last known copy: reopening shows it at once and refreshes silently.
  late KbQa? _qa = MemoryCache.get<KbQa>('kb_qa:${widget.id}');
  Object? _error;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final qa = await ref.read(kbApiProvider).fetchQa(widget.id);
      MemoryCache.put('kb_qa:${widget.id}', qa);
      if (mounted) setState(() => _qa = qa);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (_qa != null) AppSnackbar.show(context, message: context.l10n.kb_error, kind: SnackKind.error);
    }
  }

  Future<void> _edit() async {
    await context.push('/knowledge/${widget.id}/edit');
    if (mounted) _load();
  }

  Future<void> _setEnabled(bool v) async {
    final qa = _qa;
    if (qa == null || _toggling) return;
    final l = context.l10n;
    setState(() {
      _toggling = true;
      _qa = qa.copyWith(enabled: v, status: v ? KbStatus.active : KbStatus.disabled);
    });
    Analytics.log('kb_toggle_enabled', {'type': 'qa'});
    try {
      await ref.read(kbApiProvider).setEnabled(qa.id, v);
      ref.read(knowledgeControllerProvider.notifier).applySaved(_qa!);
      if (mounted) AppSnackbar.show(context, message: v ? l.kb_enabled_done : l.kb_disabled_done, kind: SnackKind.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _qa = qa);
      AppSnackbar.show(context, message: _offline(e) ? l.kb_offline : l.kb_save_err, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  bool _offline(Object e) => e is KbApiException && e.isNetwork;

  Future<void> _delete() async {
    final qa = _qa;
    if (qa == null) return;
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.kb_delete_title(qa.question),
      body: l.kb_delete_body,
      confirmLabel: l.kb_delete,
      icon: AppIcons.delete,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(kbApiProvider).delete(qa.id);
      Analytics.log('kb_delete', {'type': 'qa'});
      ref.read(knowledgeControllerProvider.notifier).removeLocal(qa.id);
      MemoryCache.remove('kb_qa:${qa.id}');
      if (!mounted) return;
      final rootCtx = Navigator.of(context, rootNavigator: true).context;
      context.pop();
      if (rootCtx.mounted) AppSnackbar.show(rootCtx, message: l.kb_deleted, kind: SnackKind.success);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, message: _offline(e) ? l.kb_offline : l.kb_save_err, kind: SnackKind.error);
    }
  }

  void _menu(_Menu m) {
    final l = context.l10n;
    switch (m) {
      case _Menu.toggle:
        _setEnabled(!(_qa?.enabled ?? true));
      case _Menu.copy:
        Clipboard.setData(ClipboardData(text: _qa?.answer ?? ''));
        AppSnackbar.show(context, message: l.kb_copied, kind: SnackKind.success);
      case _Menu.delete:
        _delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final perms = ref.watch(knowledgeControllerProvider.select((s) => s.permissions));
    final qa = _qa;

    Widget body;
    if (qa == null && _error != null) {
      final e = _error;
      body = EmptyState(
        icon: e is KbApiException && e.isNetwork ? AppIcons.offline : AppIcons.error,
        title: l.kb_error,
        actionLabel: l.kb_retry,
        onAction: _load,
      );
    } else if (qa == null) {
      body = const Center(child: AppSpinner());
    } else {
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            _QuestionCard(qa: qa),
            const SizedBox(height: AppSpacing.md),
            _AnswerCard(qa: qa),
            const SizedBox(height: AppSpacing.md),
            if (qa.media.isNotEmpty) ...[
              KbMediaCard(media: qa.media),
              const SizedBox(height: AppSpacing.md),
            ],
            KbUsageCard(usage: qa.usage),
            if (qa.recentUses.isNotEmpty) _RecentUses(uses: qa.recentUses.take(5).toList()),
            const SizedBox(height: AppSpacing.md),
            _Meta(qa: qa),
            const SizedBox(height: AppSpacing.md),
            _Card(
              child: Row(
                children: [
                  Expanded(child: Text(l.kb_available_ai, style: context.text.listTitle)),
                  AppSwitch(
                    value: qa.enabled,
                    semanticLabel: l.kb_available_ai,
                    onChanged: perms.canEdit && !_toggling ? _setEnabled : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: l.kb_qa,
        background: c.backgroundMuted,
        actions: [
          if (qa != null && perms.canEdit) AppBarTextAction(label: l.kb_edit, onPressed: _edit),
          if (qa != null && (perms.canEdit || perms.canDelete))
            PopupMenuButton<_Menu>(
              icon: AppIcon(AppIcons.more, dp: 14, color: c.textPrimary),
              tooltip: l.common_more,
              onSelected: _menu,
              itemBuilder: (_) => [
                if (perms.canEdit) PopupMenuItem(value: _Menu.toggle, child: Text(qa.enabled ? l.kb_disable : l.kb_enable)),
                PopupMenuItem(value: _Menu.copy, child: Text(l.kb_copy_answer)),
                if (perms.canDelete) PopupMenuItem(value: _Menu.delete, child: Text(l.kb_delete, style: TextStyle(color: c.textError))),
              ],
            )
          else if (qa != null)
            AppIconButton(icon: AppIcons.copy, semanticLabel: l.kb_copy_answer, onPressed: () => _menu(_Menu.copy)),
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.qa});

  final KbQa qa;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(qa.question, style: t.h5.copyWith(fontWeight: FontWeight.w800)),
          if (qa.altPhrasings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.kb_alt_phrasings, style: t.caption.copyWith(color: c.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final p in qa.altPhrasings) _Chip(text: p)],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[AppIcon(icon, size: AppIconSize.xs, color: c.textSecondary), const SizedBox(width: 4)],
          Flexible(child: Text(text, style: context.text.chipLabel.copyWith(color: c.textSecondary))),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.qa});

  final KbQa qa;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.kb_answer, style: t.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: 6),
          SelectableText(qa.answer, style: t.bodyLarge.copyWith(fontSize: 15, height: 1.7)),
          if (qa.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in qa.tags) _Chip(text: tag.name, icon: AppIcons.tag)]),
          ],
        ],
      ),
    );
  }
}

class _RecentUses extends StatelessWidget {
  const _RecentUses({required this.uses});

  final List<KbRecentUse> uses;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
                child: Text(context.l10n.kb_recent_uses, style: t.caption.copyWith(color: c.textSecondary)),
              ),
              for (final u in uses)
                InkWell(
                  onTap: () => context.push(Routes.chat(u.conversationId, messageId: u.messageId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${u.customerName}: «${u.question}»',
                            style: t.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(AppFormat.relative(context, u.at), style: t.caption.copyWith(color: c.textTertiary)),
                        const SizedBox(width: AppSpacing.xs),
                        AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.qa});

  final KbQa qa;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final created = qa.createdAt;
    final updated = qa.updatedAt;
    if (created == null && updated == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        l.kb_meta(
          qa.createdBy?.name ?? '—',
          created == null ? '—' : AppFormat.date(context, created),
          qa.updatedBy?.name ?? qa.createdBy?.name ?? '—',
          updated == null ? '' : AppFormat.relative(context, updated),
        ),
        style: context.text.caption.copyWith(color: context.colors.textTertiary),
      ),
    );
  }
}
