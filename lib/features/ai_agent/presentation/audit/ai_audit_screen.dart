import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/state/load_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/ai_agent_controller.dart';
import '../../domain/ai_agent_config.dart';

/// Wire field key → readable label for the change log.
String aiFieldLabel(AppLocalizations l, String key) => switch (key) {
      'mode' => l.ai_mode,
      'tone' => l.ai_tone,
      'hours' => l.ai_hours,
      'handoff' => l.ai_handoff,
      'language' => l.ai_language,
      'channels' => l.ai_channels,
      'custom_instructions' => l.ai_instructions,
      'allow_outside_kb' => l.ai_outside_kb,
      'confidence_threshold' => l.ai_confidence,
      'auto_reply_delay_seconds' => l.ai_delay,
      'enabled' => l.ai_master_switch,
      'use_customer_name' => l.ai_use_name,
      _ => key,
    };

/// Read-only change log (AI Agent spec §4.8): who changed what, when.
class AiAuditScreen extends ConsumerStatefulWidget {
  const AiAuditScreen({super.key});

  @override
  ConsumerState<AiAuditScreen> createState() => _AiAuditScreenState();
}

class _AiAuditScreenState extends ConsumerState<AiAuditScreen> {
  static const _cacheKey = 'ai_audit';

  final _rows = <AiAuditEntry>[];
  final _scroll = ScrollController();
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _done = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _more();
    });
    // Reopening shows the last first page at once, then refreshes quietly.
    final cached = MemoryCache.get<(List<AiAuditEntry>, String?)>(_cacheKey);
    if (cached != null) {
      _rows.addAll(cached.$1);
      _cursor = cached.$2;
      _done = cached.$2 == null;
      _loading = false;
    }
    _load(silent: cached != null);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// [silent]: keep the rows on screen (reopen / pull to refresh); a failure
  /// then only shows a snackbar.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final (rows, next) = await ref.read(aiAgentApiProvider).audit();
      MemoryCache.put(_cacheKey, (rows, next));
      if (!mounted) return;
      setState(() {
        _rows
          ..clear()
          ..addAll(rows);
        _cursor = next;
        _done = next == null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _rows.isNotEmpty) {
        AppSnackbar.show(context, message: context.l10n.ai_load_error, kind: SnackKind.error);
        return;
      }
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _more() async {
    if (_loadingMore || _done || _loading || _cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final (rows, next) = await ref.read(aiAgentApiProvider).audit(cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _rows.addAll(rows);
        _cursor = next;
        _done = next == null;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _when(BuildContext context, DateTime at) {
    final now = DateTime.now();
    final loc = context.localeName;
    final time = intl.DateFormat('HH:mm').format(at);
    if (now.difference(at).inDays < 1 && now.day == at.day) return time;
    return '${at.day} ${intl.DateFormat('MMMM', loc).format(at)} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    Widget body;
    if (_loading) {
      body = AppSkeleton(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (var i = 0; i < 6; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    SkeletonBox(width: 36, height: 36, circle: true),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: SkeletonBox(height: 12)),
                  ],
                ),
              ),
          ],
        ),
      );
    } else if (_error != null) {
      body = EmptyState(icon: AppIcons.wifiOff, title: l.ai_load_error, actionLabel: l.ai_retry, onAction: _load);
    } else if (_rows.isEmpty) {
      body = EmptyState(icon: AppIcons.history, title: l.ai_audit_empty);
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: _rows.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => Divider(height: 1, color: c.divider, indent: 64),
          itemBuilder: (context, i) {
            if (i >= _rows.length) {
              return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: AppSpinner()));
            }
            final r = _rows[i];
            final fields = r.changes.map((k) => aiFieldLabel(l, k)).join('، ');
            return ListTile(
              leading: AppAvatar(name: r.actorName, id: r.actorName, size: AppAvatarSize.sm),
              title: Text(r.actorName, style: t.listTitle),
              subtitle: Text(l.ai_audit_row(fields), style: t.bodySmall.copyWith(color: c.textSecondary)),
              trailing: Text(_when(context, r.at), style: t.caption.copyWith(color: c.textTertiary)),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(title: l.ai_audit),
      body: SafeArea(top: false, child: body),
    );
  }
}
