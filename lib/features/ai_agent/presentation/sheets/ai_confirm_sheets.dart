import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// §6.1 — turning the AI off. True = confirmed.
Future<bool> showAiOffConfirm(BuildContext context, {required int handling}) async {
  final l = context.l10n;
  final ok = await AppBottomSheet.show<bool>(
    context,
    builder: (ctx) {
      final c = ctx.colors;
      final t = ctx.text;
      return _ConfirmBody(
        icon: AppIcons.warning,
        iconColor: c.textWarning,
        iconBackground: c.warningContainer,
        title: l.ai_off_title,
        body: [
          Text(l.ai_off_body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
          if (handling > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l.ai_off_handling('$handling'), style: t.caption.copyWith(color: c.textTertiary)),
          ],
        ],
        actions: [
          AppButton(
            label: l.ai_off_confirm,
            variant: AppButtonVariant.destructiveFilled,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.ai_cancel,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

enum ReadinessBlockerChoice { addAnswers, enableSuggest }

/// §6.2 — enabling without a knowledge base.
Future<ReadinessBlockerChoice?> showReadinessBlocker(BuildContext context) {
  final l = context.l10n;
  return AppBottomSheet.show<ReadinessBlockerChoice>(
    context,
    builder: (ctx) {
      final c = ctx.colors;
      final t = ctx.text;
      return _ConfirmBody(
        icon: AppIcons.kb,
        iconColor: c.primary,
        iconBackground: c.primaryContainer,
        title: l.ai_kb_first_title,
        body: [Text(l.ai_kb_first_body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center)],
        actions: [
          AppButton(
            label: l.ai_kb_add,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(ReadinessBlockerChoice.addAnswers),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.ai_enable_suggest,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(ReadinessBlockerChoice.enableSuggest),
          ),
        ],
      );
    },
  );
}

/// §6.3 — first switch to auto-reply / after-hours. True = enable.
Future<bool> showAutoReplyConfirm(BuildContext context, {required bool tested, required VoidCallback onTryNow}) async {
  final ok = await AppBottomSheet.show<bool>(context, builder: (_) => _AutoReplyBody(tested: tested, onTryNow: onTryNow));
  return ok ?? false;
}

class _AutoReplyBody extends StatefulWidget {
  const _AutoReplyBody({required this.tested, required this.onTryNow});

  final bool tested;
  final VoidCallback onTryNow;

  @override
  State<_AutoReplyBody> createState() => _AutoReplyBodyState();
}

class _AutoReplyBodyState extends State<_AutoReplyBody> {
  late bool _checked = widget.tested;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    Widget bullet(String s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.check, dp: 18, color: c.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(s, style: t.bodySmall)),
            ],
          ),
        );
    return _ConfirmBody(
      icon: AppIcons.ai,
      iconColor: c.primary,
      iconBackground: c.primaryContainer,
      title: l.ai_auto_title,
      body: [
        bullet(l.ai_auto_b1),
        bullet(l.ai_auto_b2),
        bullet(l.ai_auto_b3),
        const SizedBox(height: AppSpacing.sm),
        MergeSemantics(
          child: InkWell(
            onTap: () => setState(() => _checked = !_checked),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
              child: Row(
                children: [
                  Checkbox(value: _checked, onChanged: (v) => setState(() => _checked = v ?? false)),
                  Expanded(child: Text(l.ai_auto_tested, style: t.bodyMedium)),
                ],
              ),
            ),
          ),
        ),
      ],
      actions: [
        AppButton(
          label: l.ai_auto_confirm,
          expand: true,
          onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
        ),
        if (!widget.tested) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.ai_auto_try,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop(false);
              widget.onTryNow();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l.ai_cancel,
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

/// §6.4 — answering outside the knowledge base. True = allow.
Future<bool> showOutsideKbConfirm(BuildContext context) {
  final l = context.l10n;
  return AppDialog.confirm(
    context,
    title: l.ai_outside_title,
    body: l.ai_outside_body,
    confirmLabel: l.ai_allow,
    icon: AppIcons.warning,
    severity: DialogSeverity.destructive,
  );
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final List<Widget> body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: AppIcon(icon, size: AppIconSize.lg, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(header: true, child: Text(title, style: t.h5, textAlign: TextAlign.center)),
          const SizedBox(height: AppSpacing.sm),
          ...body,
          const SizedBox(height: AppSpacing.lg),
          ...actions,
        ],
      ),
    );
  }
}
