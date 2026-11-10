import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../conversations/domain/relative_time_formatter.dart';
import '../../../data/kb_editor_api.dart';

/// "سجل التغييرات" (Add Answer spec §4.10): who / when / summary, with
/// "استعادة هذه النسخة" on every version except the current one.
Future<void> showVersionsSheet(
  BuildContext context, {
  required Future<List<KbVersion>> Function() load,
  required Future<bool> Function(int version) onRestore,
}) {
  return AppBottomSheet.showExpanded<void>(
    context,
    title: context.l10n.kbe_history,
    initialSize: 0.6,
    builder: (ctx, controller) => _Versions(load: load, onRestore: onRestore, controller: controller),
  );
}

class _Versions extends StatefulWidget {
  const _Versions({required this.load, required this.onRestore, required this.controller});

  final Future<List<KbVersion>> Function() load;
  final Future<bool> Function(int version) onRestore;
  final ScrollController controller;

  @override
  State<_Versions> createState() => _VersionsState();
}

class _VersionsState extends State<_Versions> {
  late Future<List<KbVersion>> _future = widget.load();
  int? _restoring;

  Future<void> _restore(int v) async {
    setState(() => _restoring = v);
    final ok = await widget.onRestore(v);
    if (!mounted) return;
    final l = context.l10n;
    if (ok) {
      Navigator.of(context).pop();
      AppSnackbar.show(context, message: l.kbe_restored, kind: SnackKind.success);
    } else {
      setState(() => _restoring = null);
      AppSnackbar.show(context, message: l.kbe_restore_failed, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return FutureBuilder<List<KbVersion>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: AppSpinner());
        }
        if (snap.hasError) {
          return EmptyState(
            icon: AppIcons.alert,
            title: l.kbe_load_error,
            actionLabel: l.kbe_retry,
            onAction: () => setState(() => _future = widget.load()),
          );
        }
        final list = snap.data!;
        if (list.length <= 1) {
          return EmptyState(icon: AppIcons.history, title: l.kbe_versions_empty);
        }
        final newest = list.map((v) => v.version).reduce((a, b) => a > b ? a : b);
        return ListView.separated(
          controller: widget.controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          itemCount: list.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
          itemBuilder: (_, i) {
            final v = list[i];
            final current = v.version == newest;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l.kbe_version_n('${v.version}'), style: t.listTitle),
                      if (current) ...[
                        const SizedBox(width: AppSpacing.sm),
                        StatusBadge(label: l.kbe_version_current, foreground: c.textSuccess, background: c.successContainer, compact: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${v.by?.name ?? '—'} · ${RelativeTimeFormatter.format(v.at, DateTime.now(), l, context.localeName)}',
                    style: t.bodySmall.copyWith(color: c.textSecondary),
                  ),
                  if (v.summary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(v.summary, style: t.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  if (!current)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        label: l.kbe_restore,
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.small,
                        loading: _restoring == v.version,
                        onPressed: _restoring == null ? () => _restore(v.version) : null,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
