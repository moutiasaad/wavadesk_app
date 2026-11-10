import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/presence_controller.dart';
import '../../domain/viewer_text_formatter.dart';
import 'claim_waiting_tag.dart';
import '../../../../core/utils/span_format.dart';

/// Viewing row (Claim spec §4.2): viewer avatars (sm, max 3, overlap −8,
/// `+n`) + text (first name bold) · waiting tag at the end. Tap → popover
/// listing viewers with "منذ {n} ث". At large text the tag wraps under.
class ClaimViewingRow extends ConsumerWidget {
  const ClaimViewingRow({super.key, required this.conversationId, required this.waitingSince, this.slaSeconds = 300});

  final String conversationId;
  final DateTime? waitingSince;
  final int slaSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final viewers = ref.watch(presenceControllerProvider(conversationId));
    final text = ViewerTextFormatter.format([for (final v in viewers) v.agent], context.l10n);
    final tag = ClaimWaitingTag(since: waitingSince, slaSeconds: slaSeconds);
    final style = t.caption.copyWith(fontSize: 12.5, color: c.textSecondary);
    final large = MediaQuery.textScalerOf(context).scale(10) > 15;

    Widget label = _BoldNameText(
      text: text,
      style: style,
      boldStyle: style.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
    );

    final avatars = AnimatedSwitcher(
      duration: AppMotion.fast,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: child),
      ),
      child: viewers.isEmpty
          ? const SizedBox.shrink(key: ValueKey('none'))
          : _AvatarStack(key: ValueKey(viewers.map((v) => v.agent.id).join(',')), viewers: viewers),
    );

    final row = viewers.isEmpty
        // Nobody viewing: just the waiting tag, start-aligned, with label.
        ? Row(
            children: [
              tag,
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: label),
            ],
          )
        : large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  avatars,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: label),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              tag,
            ],
          )
        : Row(
            children: [
              avatars,
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: label),
              const SizedBox(width: AppSpacing.sm),
              tag,
            ],
          );

    return Semantics(
      button: viewers.isNotEmpty,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: viewers.isEmpty ? null : () => _showViewers(context, viewers),
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 28), child: row),
      ),
    );
  }

  /// Small popover above the row (`surfaceElevated`, radius 14).
  void _showViewers(BuildContext context, List<ViewerPresence> viewers) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final l = context.l10n;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l.common_close,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.fast,
      pageBuilder: (ctx, _, _) {
        final c = ctx.colors;
        return Stack(
          children: [
            PositionedDirectional(
              start: AppSpacing.lg,
              bottom: MediaQuery.sizeOf(ctx).height - origin.dy + AppSpacing.xs,
              child: Material(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: ctx.shadows.medium,
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final v in viewers)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              AppAvatar(
                                name: v.agent.name,
                                id: v.agent.id,
                                presence: v.agent.presence,
                                size: AppAvatarSize.sm,
                                ringColor: c.surfaceElevated,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(v.agent.name, style: ctx.text.listTitle.copyWith(fontSize: 14))),
                              Text(_since(ctx, v.since), style: ctx.text.caption.copyWith(color: c.textTertiary)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: a, child: child),
    );
  }

  static String _since(BuildContext context, DateTime since) {
    final s = DateTime.now().difference(since).inSeconds;
    final l = context.l10n;
    return s < 60 ? l.claim_viewing_since_sec(s) : l.claim_viewing_since_min(SpanFormat.compact(s, l));
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({super.key, required this.viewers});

  final List<ViewerPresence> viewers;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = viewers.take(3).toList();
    final extra = viewers.length - shown.length;
    const size = 28.0;
    const overlap = 8.0;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: size + (count - 1) * (size - overlap),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 2),
                ),
                child: AppAvatar(
                  name: shown[i].agent.name,
                  id: shown[i].agent.id,
                  presence: shown[i].agent.presence,
                  size: AppAvatarSize.sm,
                ),
              ),
            ),
          if (extra > 0)
            PositionedDirectional(
              start: shown.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 2),
                ),
                child: Text('+$extra', style: context.text.caption.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoldNameText extends StatelessWidget {
  const _BoldNameText({required this.text, required this.style, required this.boldStyle});

  final ViewerText text;
  final TextStyle style;
  final TextStyle boldStyle;

  @override
  Widget build(BuildContext context) {
    final name = text.boldName;
    final i = name == null ? -1 : text.text.indexOf(name);
    if (i < 0) return Text(text.text, style: style);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.text.substring(0, i)),
          TextSpan(text: name, style: boldStyle),
          TextSpan(text: text.text.substring(i + name!.length)),
        ],
      ),
      style: style,
    );
  }
}
