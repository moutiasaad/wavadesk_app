import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/load_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../data/kb_api.dart';
import '../../domain/kb_entry.dart';
import '../../domain/kb_subtitle_formatter.dart';
import '../widgets/kb_entry_tile.dart';

String kbRefreshLabel(AppLocalizations l, KbRefresh r) => switch (r) {
      KbRefresh.weekly => l.kb_weekly,
      KbRefresh.monthly => l.kb_monthly,
      KbRefresh.manual => l.kb_manual,
    };

/// Link detail `/knowledge/links/:id` (Knowledge Base spec §6.3).
class KbLinkDetailScreen extends ConsumerStatefulWidget {
  const KbLinkDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<KbLinkDetailScreen> createState() => _KbLinkDetailScreenState();
}

class _KbLinkDetailScreenState extends ConsumerState<KbLinkDetailScreen> {
  late KbLink? _link = MemoryCache.get<KbLink>('kb_link:${widget.id}');
  Object? _error;
  bool _recrawling = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _poll?.cancel();
    try {
      final l = await ref.read(kbApiProvider).link(widget.id);
      MemoryCache.put('kb_link:${widget.id}', l);
      if (!mounted) return;
      setState(() {
        _link = l;
        _error = null;
      });
      if (l.status == KbStatus.processing) _poll = Timer(const Duration(seconds: 3), _load);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    final l = context.l10n;
    final msg = e is KbApiException && e.isNotSupported ? l.kb_web_only : (e is KbApiException && e.isNetwork ? l.kb_offline : l.kb_save_err);
    AppSnackbar.show(context, message: msg, kind: SnackKind.error);
  }

  Future<void> _recrawl() async {
    setState(() => _recrawling = true);
    try {
      final next = await ref.read(kbApiProvider).recrawl(widget.id);
      if (!mounted) return;
      setState(() => _link = next);
      AppSnackbar.show(context, message: context.l10n.kb_recrawl_started, kind: SnackKind.success);
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _recrawling = false);
    }
  }

  Future<void> _patch({KbRefresh? refresh, List<KbLinkPage>? pages}) async {
    final before = _link;
    if (before == null) return;
    setState(() => _link = before.copyWith(refresh: refresh, pages: pages));
    try {
      final next = await ref.read(kbApiProvider).patchLink(widget.id, refresh: refresh, pages: pages);
      if (mounted) setState(() => _link = next);
    } catch (e) {
      if (mounted) setState(() => _link = before);
      _fail(e);
    }
  }

  Future<void> _pickRefresh() async {
    final link = _link;
    if (link == null) return;
    final l = context.l10n;
    final picked = await AppBottomSheet.show<KbRefresh>(
      context,
      title: l.kb_auto_refresh,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in KbRefresh.values)
            AppRadioRow(label: kbRefreshLabel(l, r), selected: r == link.refresh, onTap: () => Navigator.of(ctx).pop(r)),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
    if (picked != null && picked != link.refresh) _patch(refresh: picked);
  }

  Future<void> _delete() async {
    final link = _link;
    if (link == null) return;
    final l = context.l10n;
    final ok = await AppDialog.confirm(context, title: l.kb_delete_title(link.title), body: l.kb_delete_body, confirmLabel: l.kb_delete, icon: AppIcons.delete);
    if (!ok || !mounted) return;
    try {
      await ref.read(kbApiProvider).delete(link.id);
      Analytics.log('kb_delete', {'type': 'link'});
      ref.read(knowledgeControllerProvider.notifier).removeLocal(link.id);
      if (mounted) context.pop();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final perms = ref.watch(knowledgeControllerProvider.select((s) => s.permissions));
    final link = _link;

    Widget body;
    if (link == null && _error != null) {
      final e = _error;
      final ns = e is KbApiException && e.isNotSupported;
      body = EmptyState(icon: ns ? AppIcons.globe : AppIcons.alert, title: ns ? l.kb_web_only : l.kb_error, actionLabel: ns ? null : l.kb_retry, onAction: ns ? null : _load);
    } else if (link == null) {
      body = const Center(child: AppSpinner());
    } else {
      final v = KbTypeVisual.of(context, KbType.link);
      body = ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          _box(
            context,
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: v.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(v.icon, size: 24, color: v.foreground),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.title, style: t.listTitle),
                      Text(link.domain, style: t.bodySmall.copyWith(color: c.textSecondary), textDirection: TextDirection.ltr),
                      const SizedBox(height: 2),
                      if (link.status == KbStatus.processing)
                        Row(children: [
                          AppSpinner(size: 12, color: c.textInfo, delayed: false),
                          const SizedBox(width: 6),
                          Text(l.kb_processing, style: t.caption.copyWith(color: c.textInfo)),
                        ])
                      else
                        Text(
                          link.lastCrawledAt == null ? l.kb_never_crawled : l.kb_last_crawl(AppFormat.relative(context, link.lastCrawledAt!)),
                          style: t.caption.copyWith(color: c.textTertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _box(
            context,
            Column(
              children: [
                SettingsTile(
                  icon: AppIcons.regenerate,
                  title: l.kb_recrawl,
                  trailing: _recrawling ? const AppSpinner(size: 18, delayed: false) : null,
                  onTap: perms.canEdit && !_recrawling ? _recrawl : null,
                ),
                Divider(height: 1, color: c.divider),
                SettingsTile(
                  icon: AppIcons.clock,
                  title: l.kb_auto_refresh,
                  value: kbRefreshLabel(l, link.refresh),
                  onTap: perms.canEdit ? _pickRefresh : null,
                ),
              ],
            ),
            padding: EdgeInsets.zero,
          ),
          if (link.pages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, AppSpacing.lg, 6, 6),
              child: Text('${l.kb_link_pages} · ${link.pages.length}', style: t.caption.copyWith(color: c.textSecondary)),
            ),
            _box(
              context,
              Column(
                children: [
                  for (var i = 0; i < link.pages.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.divider),
                    _pageRow(context, link, link.pages[i], perms.canEdit),
                  ],
                ],
              ),
              padding: EdgeInsets.zero,
            ),
          ],
          if (perms.canDelete) ...[
            const SizedBox(height: AppSpacing.md),
            _box(
              context,
              SettingsTile(
                icon: AppIcons.delete,
                iconColor: c.textError,
                iconBackground: c.errorContainer,
                title: l.kb_delete,
                destructive: true,
                showChevron: false,
                onTap: _delete,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: link?.title ?? l.kb_links, background: c.backgroundMuted),
      body: SafeArea(top: false, child: body),
    );
  }

  Widget _pageRow(BuildContext context, KbLink link, KbLinkPage p, bool canEdit) {
    final c = context.colors;
    final t = context.text;
    void toggle(bool v) => _patch(pages: [for (final x in link.pages) x.id == p.id ? x.copyWith(enabled: v) : x]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: t.listTitle.copyWith(fontSize: 14, color: p.enabled ? c.textPrimary : c.textSecondary)),
                Text(KbSubtitleFormatter.ltr(p.path), style: t.caption.copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          AppSwitch(value: p.enabled, semanticLabel: p.title, onChanged: canEdit ? toggle : null),
        ],
      ),
    );
  }

  Widget _box(BuildContext context, Widget child, {EdgeInsets padding = const EdgeInsets.all(AppSpacing.lg)}) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
