import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/customer_profile_controller.dart';
import 'customer_profile_view.dart';
import 'dialogs/erase_contact_dialog.dart';
import 'sheets/merge_contact_sheet.dart';
import 'widgets/profile_hero.dart';

/// Full-screen profile `/contacts/:contactId` (Profile spec §2, §3): from
/// search, notifications, deep links or "فتح كصفحة".
class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key, required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _ProfileScreenBody(contactId: contactId);
}

class _ProfileScreenBody extends ConsumerStatefulWidget {
  const _ProfileScreenBody({required this.contactId});

  final String contactId;

  @override
  ConsumerState<_ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends ConsumerState<_ProfileScreenBody> {
  bool _heroVisible = true;

  void _menu() {
    final contact = ref.read(customerProfileControllerProvider(widget.contactId)).contact;
    if (contact == null) return;
    final l = context.l10n;
    final p = contact.permissions;
    AppBottomSheet.show<void>(
      context,
      showClose: false,
      builder: (ctx) => Column(
        children: [
          if (p.canEdit)
            SheetActionRow(
              icon: AppIcons.edit,
              label: l.profile_edit,
              onTap: () {
                Navigator.pop(ctx);
                context.push(Routes.editContact(widget.contactId));
              },
            ),
          if (p.canMerge)
            SheetActionRow(
              icon: AppIcons.transfer,
              label: l.profile_merge,
              onTap: () {
                Navigator.pop(ctx);
                showMergeContactSheet(context, ref, contactId: widget.contactId);
              },
            ),
          if (p.canDelete)
            SheetActionRow(
              icon: AppIcons.delete,
              label: l.profile_erase,
              destructive: true,
              onTap: () {
                Navigator.pop(ctx);
                showEraseContactDialog(context, ref, contactId: widget.contactId);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final contact = ref.watch(customerProfileControllerProvider(widget.contactId).select((s) => s.contact));
    // Title = contact name only after scrolling past the hero (§3).
    final title = !_heroVisible && contact != null ? profileDisplayName(contact, l) : '';

    return Scaffold(
      backgroundColor: c.backgroundMuted,
      appBar: AppBarStandard(
        title: title,
        background: c.backgroundMuted,
        scrolledUnder: !_heroVisible,
        actions: [
          if (contact != null)
            AppIconButton(icon: AppIcons.more, semanticLabel: l.profile_more_actions, onPressed: _menu),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: CustomerProfileView(
            contactId: widget.contactId,
            container: 'screen',
            onHeroVisibilityChanged: (v) => setState(() => _heroVisible = v),
          ),
        ),
      ),
    );
  }
}
