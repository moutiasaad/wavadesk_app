import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/customer_profile_controller.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';

typedef _MergeChoice = ({String intoId, Map<String, String> fieldChoices});

/// دمج مع عميل آخر (Profile spec §7.6, admin): search → preview with a
/// radio per conflicting field → دمج → irreversible confirm → merge.
Future<void> showMergeContactSheet(BuildContext context, WidgetRef ref, {required String contactId}) async {
  final from = ref.read(customerProfileControllerProvider(contactId)).contact;
  if (from == null) return;
  final l = context.l10n;
  final choice = await AppBottomSheet.showExpanded<_MergeChoice>(
    context,
    title: l.merge_title,
    builder: (ctx, controller) => _MergeBody(from: from, controller: controller),
  );
  if (choice == null || !context.mounted) return;

  final ok = await AppDialog.confirm(
    context,
    title: l.merge_confirm_title,
    body: l.merge_confirm_body,
    confirmLabel: l.merge_action,
    icon: AppIcons.error,
  );
  if (!ok || !context.mounted) return;

  // From the full-screen profile, land on the surviving contact.
  var fromScreen = false;
  try {
    fromScreen = GoRouterState.of(context).uri.path.startsWith('/contacts/');
  } catch (_) {}

  try {
    await ref
        .read(customerProfileControllerProvider(contactId).notifier)
        .merge(intoId: choice.intoId, fieldChoices: choice.fieldChoices);
    if (!context.mounted) return;
    AppSnackbar.show(context, message: l.merge_done, kind: SnackKind.success);
    if (fromScreen) {
      context.pushReplacement(Routes.contact(choice.intoId));
    } else {
      Navigator.of(context).maybePop();
    }
  } catch (_) {
    if (context.mounted) AppSnackbar.show(context, message: l.merge_failed, kind: SnackKind.error);
  }
}

class _MergeBody extends ConsumerStatefulWidget {
  const _MergeBody({required this.from, required this.controller});

  final Contact from;
  final ScrollController controller;

  @override
  ConsumerState<_MergeBody> createState() => _MergeBodyState();
}

class _MergeBodyState extends ConsumerState<_MergeBody> {
  String _query = '';
  Contact? _target;

  /// field → 'from' (this contact) | 'into' (target).
  final Map<String, String> _choices = {};

  List<(String, String, String?, String?)> _fields(AppLocalizations l, Contact a, Contact b) => [
        ('name', l.merge_field_name, a.name, b.name),
        ('phone', l.merge_field_phone, a.phone, b.phone),
        ('email', l.merge_field_email, a.email, b.email),
        ('city', l.merge_field_city, a.city, b.city),
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final target = _target;

    if (target == null) {
      final results = ref.read(contactsRepositoryProvider).search(_query, excludeId: widget.from.id);
      return ListView(
        controller: widget.controller,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          AppSearchField(
            hint: l.merge_search,
            showCancel: false,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(l.merge_no_results, textAlign: TextAlign.center, style: t.bodySmall.copyWith(color: c.textTertiary)),
            ),
          for (final r in results)
            InkWell(
              onTap: () => setState(() {
                _target = r;
                _choices.clear();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    AppAvatar(name: r.name ?? '?', id: r.id, size: AppAvatarSize.md, ringColor: c.surfaceElevated),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name ?? l.merge_unnamed, style: t.listTitle),
                          if (r.primaryIdentifier != null)
                            Text(
                              r.primaryIdentifier!,
                              textDirection: TextDirection.ltr,
                              style: t.bodySmall.copyWith(color: c.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    final fields = _fields(l, widget.from, target);
    final conflicts = [for (final f in fields) if (f.$3 != null && f.$4 != null && f.$3 != f.$4) f];
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              // Preview card: target that survives.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    AppAvatar(name: target.name ?? '?', id: target.id, size: AppAvatarSize.md, ringColor: c.surface),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.merge_into_label, style: t.caption.copyWith(color: c.textSecondary)),
                          Text(target.name ?? l.merge_unnamed, style: t.listTitle),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _target = null),
                      style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: t.buttonSmall, minimumSize: const Size(48, 48)),
                      child: Text(l.merge_change),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (conflicts.isEmpty)
                Text(l.merge_no_conflicts, style: t.bodySmall.copyWith(color: c.textSecondary))
              else ...[
                Text(l.merge_choose_values, style: t.h6),
                const SizedBox(height: AppSpacing.sm),
                for (final f in conflicts) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                    child: Text(f.$2, style: t.caption.copyWith(color: c.textSecondary)),
                  ),
                  AppRadioRow(
                    label: f.$3!,
                    subtitle: l.merge_this_contact,
                    selected: _choices[f.$1] == 'from',
                    onTap: () => setState(() => _choices[f.$1] = 'from'),
                  ),
                  AppRadioRow(
                    label: f.$4!,
                    subtitle: l.merge_other_contact,
                    selected: (_choices[f.$1] ?? 'into') == 'into',
                    onTap: () => setState(() => _choices[f.$1] = 'into'),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          child: AppButton(
            label: l.merge_action,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.of(context).pop<_MergeChoice>((
              intoId: target.id,
              fieldChoices: {for (final f in conflicts) f.$1: _choices[f.$1] ?? 'into'},
            )),
          ),
        ),
      ],
    );
  }
}
