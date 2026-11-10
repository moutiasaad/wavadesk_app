import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/contact.dart';
import 'profile_hero.dart';

/// Quick actions (§5.2): اتصال · واتساب · ملاحظة · حظر/إلغاء الحظر. Tiles
/// 48 circles + caption 12/700; disabled 40%. The block tile is hidden
/// without `can_block` (row of 3).
class ProfileQuickActions extends StatelessWidget {
  const ProfileQuickActions({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onWhatsapp,
    required this.onNote,
    required this.onBlockToggle,
    this.offline = false,
  });

  final Contact contact;
  final VoidCallback onCall;
  final VoidCallback onWhatsapp;
  final VoidCallback onNote;
  final VoidCallback onBlockToggle;

  /// Network-dependent actions (note, block) disabled offline.
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final ct = contact;
    final name = profileDisplayName(ct, l);
    final hasPhone = ct.phone != null && ct.phone!.trim().isNotEmpty;
    final hasWa = hasPhone || ct.channels.any((x) => x.channel.name == 'whatsapp');

    // WhatsApp tile: spec values (§5.2, §12).
    final waBg = c.isDark ? const Color(0x2625D366) : const Color(0xFFE8F9EF);
    final waFg = c.isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    void log(String action) => Analytics.log('profile_quick_action', {'action': action});

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Tile(
            icon: AppIcons.call,
            label: l.profile_call,
            semantics: hasPhone ? l.profile_action_call_a11y(name) : '${l.profile_action_call_a11y(name)}، ${l.profile_disabled_no_phone}',
            bg: c.primaryContainer,
            fg: c.primary,
            onTap: hasPhone
                ? () {
                    log('call');
                    onCall();
                  }
                : null,
          ),
        ),
        Expanded(
          child: _Tile(
            icon: AppIcons.whatsapp,
            label: l.profile_whatsapp,
            semantics: hasWa ? l.profile_action_whatsapp_a11y(name) : '${l.profile_action_whatsapp_a11y(name)}، ${l.profile_disabled_no_phone}',
            bg: waBg,
            fg: waFg,
            onTap: hasWa
                ? () {
                    log('whatsapp');
                    onWhatsapp();
                  }
                : null,
          ),
        ),
        Expanded(
          child: _Tile(
            icon: AppIcons.note,
            label: l.profile_note,
            semantics: l.profile_action_note_a11y(name),
            bg: c.surfaceVariant,
            fg: c.textPrimary,
            onTap: offline
                ? null
                : () {
                    log('note');
                    onNote();
                  },
          ),
        ),
        if (ct.permissions.canBlock)
          Expanded(
            child: _Tile(
              icon: ct.isBlocked ? AppIcons.unblock : AppIcons.block,
              label: ct.isBlocked ? l.profile_unblock : l.profile_block,
              semantics: ct.isBlocked ? l.profile_action_unblock_a11y(name) : l.profile_action_block_a11y(name),
              bg: c.errorContainer,
              fg: c.error,
              labelColor: c.textError,
              onTap: offline
                  ? null
                  : () {
                      log('block');
                      onBlockToggle();
                    },
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.semantics,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String semantics;
  final Color bg;
  final Color fg;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  void _set(bool v) {
    if (AppMotion.reduced(context)) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semantics,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onTap!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: widget.bg, shape: BoxShape.circle),
                    child: AppIcon(widget.icon, color: widget.fg),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.label,
                    style: context.text.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: widget.labelColor ?? context.colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
