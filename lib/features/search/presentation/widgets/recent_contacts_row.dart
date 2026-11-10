import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// "آخر من تواصلت معهم": avatars 50 + channel badge + first name (§5).
class RecentContactsRow extends StatelessWidget {
  const RecentContactsRow({super.key, required this.customers, required this.onTap});

  final List<Customer> customers;
  final ValueChanged<Customer> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (customers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 22, AppSpacing.screenH, AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(
              context.l10n.search_recent_contacts,
              style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
            ),
          ),
        ),
        SizedBox(
          height: 80 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            itemCount: customers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) {
              final cu = customers[i];
              final first = cu.name.split(' ').first;
              return Semantics(
                button: true,
                label: cu.name,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => onTap(cu),
                  child: SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        AppAvatar(
                          name: cu.name,
                          id: cu.id,
                          imageUrl: cu.avatarUrl,
                          channel: cu.channel,
                          size: AppAvatarSize.lg,
                          ringColor: c.background,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          first,
                          style: t.caption.copyWith(color: c.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
