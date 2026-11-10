import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// FAB → new outbound WhatsApp message from an approved template (§8.20).
Future<void> showNewMessageSheet(BuildContext context, WidgetRef ref) {
  final router = GoRouter.of(context);
  final l = context.l10n;
  return AppBottomSheet.showExpanded<void>(
    context,
    title: l.newmsg_title,
    subtitle: l.newmsg_subtitle,
    builder: (ctx, controller) => _NewMessageBody(
      controller: controller,
      onSent: (id) {
        Navigator.of(ctx).pop();
        router.push(Routes.chat(id));
      },
    ),
  );
}

class _NewMessageBody extends ConsumerStatefulWidget {
  const _NewMessageBody({required this.controller, required this.onSent});

  final ScrollController controller;
  final ValueChanged<String> onSent;

  @override
  ConsumerState<_NewMessageBody> createState() => _NewMessageBodyState();
}

class _NewMessageBodyState extends ConsumerState<_NewMessageBody> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  MessageTemplate? _template;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _phoneValid => _phone.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 8;

  void _send() {
    setState(() => _submitted = true);
    final template = _template;
    if (!_phoneValid || template == null) return;
    HapticFeedback.lightImpact();
    final id = ref
        .read(inboxProvider.notifier)
        .startConversation(name: _name.text.trim(), phone: _phone.text.trim(), template: template);
    widget.onSent(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final templates = ref.watch(templatesProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              AppTextField(
                label: l.newmsg_name,
                hint: l.newmsg_name_hint,
                controller: _name,
                prefixIcon: AppIcons.customer,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l.newmsg_phone,
                hint: l.newmsg_phone_hint,
                controller: _phone,
                prefixIcon: AppIcons.whatsapp,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.telephoneNumber],
                onChanged: (_) => setState(() {}),
                error: _submitted && !_phoneValid ? l.newmsg_phone_error : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Semantics(header: true, child: Text(l.newmsg_template, style: t.h6)),
              if (_submitted && _template == null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l.newmsg_template_error, style: t.bodySmall.copyWith(color: c.textError)),
              ],
              const SizedBox(height: AppSpacing.sm),
              for (final tp in templates) ...[
                AppRadioRow(
                  label: tp.category,
                  subtitle: tp.body,
                  selected: _template?.id == tp.id,
                  onTap: () => setState(() => _template = tp),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          child: AppButton(
            label: l.newmsg_send,
            icon: AppIcons.send,
            size: AppButtonSize.large,
            expand: true,
            onPressed: _send,
          ),
        ),
      ],
    );
  }
}
