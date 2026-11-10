import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../domain/contact.dart';
import '../../domain/contact_attribute.dart';
import '../../domain/local_time_formatter.dart';
import 'profile_hero.dart';

/// Contact info (§5.6): grouped card with compact rows (icon 34, label on
/// top, value below). Empty values read "غير محدد" and open the editor.
/// Max 6 rows, then "عرض كل المعلومات".
class ProfileInfoSection extends StatefulWidget {
  const ProfileInfoSection({
    super.key,
    required this.contact,
    required this.onCall,
    this.onEdit,
    this.filledOnly = false,
  });

  final Contact contact;
  final VoidCallback onCall;

  /// Null without `can_edit`.
  final VoidCallback? onEdit;

  /// Over the chat (sheet): only rows with a value; nothing when all empty.
  final bool filledOnly;

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.ltr = false,
    this.onTap,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool ltr;
  final VoidCallback? onTap;
  final bool copyable;
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {
  bool _all = false;

  List<_InfoRow> _rows(BuildContext context) {
    final l = context.l10n;
    final ct = widget.contact;
    final local = LocalTimeFormatter.localTime(ct.timezone);
    String? lang(String? code) => switch (code) {
      'ar' => l.profile_lang_ar,
      'en' => l.profile_lang_en,
      null => null,
      final v => v,
    };
    final createdParts = [
      if (ct.createdViaChannel != null) ct.createdViaChannel!.label(l),
      ?ct.createdViaAgent,
      RelativeTimeFormatter.dayMonth(ct.createdAt, DateTime.now(), context.localeName),
    ];
    return [
      _InfoRow(
        icon: AppIcons.call,
        label: l.profile_phone,
        value: ct.phone,
        ltr: true,
        copyable: true,
        onTap: ct.phone == null ? widget.onEdit : widget.onCall,
      ),
      _InfoRow(
        icon: AppIcons.mail,
        label: l.profile_email,
        value: ct.email,
        ltr: true,
        copyable: true,
        onTap: ct.email == null ? widget.onEdit : () => launchUrl(Uri(scheme: 'mailto', path: ct.email)),
      ),
      _InfoRow(
        icon: AppIcons.location,
        label: l.profile_city,
        value: [?ct.city, ?ct.country].join('، ').trim().isEmpty ? null : [?ct.city, ?ct.country].join('، '),
        onTap: ct.city == null ? widget.onEdit : null,
      ),
      _InfoRow(
        icon: AppIcons.globe,
        label: l.profile_language,
        value: lang(ct.language),
        onTap: ct.language == null ? widget.onEdit : null,
      ),
      _InfoRow(
        icon: AppIcons.clock,
        label: l.profile_timezone,
        value: ct.timezone == null
            ? null
            : local == null
            ? ct.timezone
            : l.profile_tz_value(ct.timezone!, RelativeTimeFormatter.clock12(local, l)),
        ltr: true,
      ),
      for (final a in ct.attributes)
        _InfoRow(
          icon: AppIcons.tag,
          label: a.label,
          value: a.isEmpty ? null : a.display(yes: l.profile_attr_yes, no: l.profile_attr_no),
          ltr: a.type == AttributeType.url || a.type == AttributeType.number,
          onTap: a.isEmpty
              ? widget.onEdit
              : a.type == AttributeType.url
              ? () => launchUrl(Uri.parse('${a.value}'), mode: LaunchMode.externalApplication)
              : null,
        ),
      _InfoRow(icon: AppIcons.user, label: l.profile_added_by, value: createdParts.join(' · ')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final all = _rows(context);
    final rows = widget.filledOnly ? all.where((r) => r.value != null).toList() : all;
    if (rows.isEmpty) return const SizedBox.shrink();
    final shown = _all ? rows : rows.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(title: l.profile_info),
        AnimatedSize(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          alignment: AlignmentDirectional.topStart,
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
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 60, color: c.divider),
                    _row(context, shown[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (rows.length > 6 && !_all)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                textStyle: t.buttonSmall,
                minimumSize: const Size(48, 40),
              ),
              onPressed: () => setState(() => _all = true),
              child: Text(l.profile_all_info),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, _InfoRow r) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final empty = r.value == null || r.value!.trim().isEmpty;
    return InkWell(
      onTap: r.onTap,
      onLongPress: !empty && r.copyable ? () => profileCopy(context, r.value!) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(10)),
              child: Icon(r.icon, size: 17, color: c.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.label, style: t.caption.copyWith(color: c.textSecondary)),
                  Text(
                    empty ? l.profile_not_set : (r.ltr ? ltr(r.value!) : r.value!),
                    style: empty
                        ? t.bodyMedium.copyWith(color: c.textTertiary)
                        : t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
