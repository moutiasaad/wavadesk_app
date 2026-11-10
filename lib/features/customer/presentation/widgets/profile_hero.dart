import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../chat/presentation/widgets/context_strip.dart'
    show DashedRRectPainter;
import '../../../conversations/domain/relative_time_formatter.dart';
import '../../domain/contact.dart';
import '../../domain/local_time_formatter.dart';

/// Name shown for a contact; anonymous visitors read "زائر #{id}" (§6).
String profileDisplayName(Contact c, AppLocalizations l) =>
    c.isUnknown ? l.profile_visitor(c.shortId) : c.name!.trim();

/// Copies [value] with haptic + "تم النسخ" (§5.1, §5.6).
void profileCopy(BuildContext context, String value) {
  Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.selectionClick();
  AppSnackbar.show(
    context,
    message: context.l10n.profile_copied,
    kind: SnackKind.success,
  );
}

/// Section title: `h6` 13/800, top 16 / bottom 8, optional trailing text
/// button (§4).
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: t.h6.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                textStyle: t.buttonSmall,
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Hero (§5.1): avatar 76, name, primary identifier (LTR, long-press copy),
/// city / local-time line, VIP / blocked chips, tags + "+ وسم", edit pencil.
class ProfileHero extends ConsumerWidget {
  const ProfileHero({
    super.key,
    required this.contact,
    required this.onAddTag,
    this.onEdit,
    this.onAddDetails,
  });

  final Contact contact;
  final VoidCallback? onAddTag;

  /// Null hides the pencil (no `can_edit`).
  final VoidCallback? onEdit;

  /// Unknown visitor: "أضف بيانات العميل".
  final VoidCallback? onAddDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ct = contact;
    final name = profileDisplayName(ct, l);
    final id = ct.primaryIdentifier;

    String? secondary;
    if (ct.isUnknown) {
      final parts = [?ct.visitorBrowser, ?ct.visitorPage];
      secondary = parts.isEmpty ? null : parts.join(' · ');
    } else {
      final local = LocalTimeFormatter.differsFromDevice(ct.timezone)
          ? LocalTimeFormatter.localTime(ct.timezone)
          : null;
      final parts = [
        if (ct.city != null && ct.city!.trim().isNotEmpty) ct.city!,
        if (local != null)
          l.profile_local_time(RelativeTimeFormatter.clock12(local, l)),
      ];
      secondary = parts.isEmpty ? null : parts.join(' · ');
    }

    final avatar = ExcludeSemantics(
      child: GestureDetector(
        onTap: ct.avatarUrl == null
            ? null
            : () => _openPhoto(context, ct.avatarUrl!),
        child: AppAvatar(
          name: name,
          id: ct.id,
          imageUrl: ct.avatarUrl,
          size: AppAvatarSize.xl,
          ringColor: c.surfaceElevated,
        ),
      ),
    );

    // Full width so the hero stays centred in the sheet too (the Stack would
    // otherwise shrink to its content and sit at the start edge).
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              avatar,
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  name,
                  style: t.h3,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              if (id != null)
                GestureDetector(
                  onLongPress: () => profileCopy(context, id),
                  child: Text(
                    ltr(id),
                    style: t.bodyMedium.copyWith(color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (secondary != null) ...[
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: t.caption.copyWith(color: c.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
              if (ct.isUnknown && onAddDetails != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.profile_add_details,
                  icon: AppIcons.edit,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  onPressed: onAddDetails,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (ct.isVip)
                    _Chip(
                      label: l.profile_vip,
                      icon: AppIcons.star,
                      bg: c.warningContainer,
                      fg: c.textWarning,
                    ),
                  if (ct.isBlocked)
                    _Chip(
                      label: l.profile_blocked,
                      icon: AppIcons.block,
                      bg: c.errorContainer,
                      fg: c.textError,
                    ),
                  for (final tag in ct.tags)
                    if (!(ct.isVip && tag.id == 'vip'))
                      tag.system
                          ? _Chip(
                              label: tag.name,
                              bg: c.primaryContainer,
                              fg: c.onPrimaryContainer,
                            )
                          : _Chip(
                              label: tag.name,
                              bg: c.surface,
                              fg: c.textPrimary,
                              border: c.border,
                            ),
                  if (onAddTag != null) _AddTagChip(onTap: onAddTag!),
                ],
              ),
            ],
          ),
        ),
        if (onEdit != null)
          PositionedDirectional(
            top: -6,
            end: -6,
            child: AppIconButton(
              icon: AppIcons.edit,
              size: 36,
              iconSize: 18,
              iconColor: c.textSecondary,
              semanticLabel: l.profile_edit_contact,
              onPressed: onEdit,
            ),
          ),
      ],
    );
  }

  void _openPhoto(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.border,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 26),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: border == null ? null : Border.all(color: border!),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon, size: AppIconSize.xs, color: fg),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: context.text.chipLabel.copyWith(fontSize: 12, color: fg),
        ),
      ],
    ),
  );
}

/// Dashed "+ وسم" chip (opens the tag editor). Padded to a 48dp hit area.
class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: c.borderStrong,
            radius: AppRadius.full,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 26),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Text(
              context.l10n.profile_add_tag,
              style: context.text.chipLabel.copyWith(
                fontSize: 12,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
