import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../ai_agent/application/ai_agent_controller.dart';
import '../../../../ai_agent/domain/ai_agent_config.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';
import '../wa_save_feedback.dart';
import 'wa_message_preview.dart';
import '../widgets/wa_loading_body.dart';

const kWaMessageMax = 1024;
const kWaButtonMax = 20;

/// Tappable `{variable}` chips that insert at the cursor (§5.2, §5.3).
class WaVariableChips extends StatelessWidget {
  const WaVariableChips({super.key, required this.controller, required this.variables, this.enabled = true});

  final TextEditingController controller;
  final List<String> variables;
  final bool enabled;

  void _insert(String token) {
    final v = controller.value;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    final text = v.text.replaceRange(sel.start, sel.end, token);
    controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: sel.start + token.length));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final v in variables)
          Material(
            color: c.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
              side: BorderSide(color: c.primaryContainerBorder),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: enabled ? () => _insert('{$v}') : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('{$v}', style: t.tagLabel.copyWith(color: c.onPrimaryContainer)),
              ),
            ),
          ),
      ],
    );
  }
}

/// "تجاهل التغييرات؟" — true = leave.
Future<bool> waConfirmDiscard(BuildContext context) {
  final l = context.l10n;
  return AppDialog.confirm(
    context,
    title: l.wa_discard_title,
    body: l.wa_discard_body,
    confirmLabel: l.wa_discard,
    cancelLabel: l.wa_keep,
    severity: DialogSeverity.warning,
  );
}

/// Switch row used at the top of both editors.
class WaEditorSwitchRow extends StatelessWidget {
  const WaEditorSwitchRow({super.key, required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SettingsGroup(
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: context.text.listTitle.copyWith(fontSize: 14.5))),
                    AppSwitch(value: value, semanticLabel: title, onChanged: onChanged),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

/// Section label inside the editors.
class WaEditorLabel extends StatelessWidget {
  const WaEditorLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 22, end: 22, top: AppSpacing.xl, bottom: 6),
        child: Semantics(header: true, child: Text(text, style: context.text.inputLabel.copyWith(color: context.colors.textSecondary))),
      );
}

/// Welcome message editor (WhatsApp spec §5.2).
class WaWelcomeEditorScreen extends ConsumerStatefulWidget {
  const WaWelcomeEditorScreen({super.key});

  @override
  ConsumerState<WaWelcomeEditorScreen> createState() => _WaWelcomeEditorScreenState();
}

class _WaWelcomeEditorScreenState extends ConsumerState<WaWelcomeEditorScreen> {
  WaWelcome? _initial;
  late bool _enabled;
  late WaWelcomeTrigger _trigger;
  final _text = TextEditingController();
  final List<TextEditingController> _buttons = [];
  bool _saving = false;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
  }

  void _seed(WaWelcome w) {
    _initial = w;
    _enabled = w.enabled;
    _trigger = w.trigger;
    _text.text = w.text;
    for (final b in w.buttons.take(3)) {
      _buttons.add(TextEditingController(text: b)..addListener(_changed));
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _text.dispose();
    for (final b in _buttons) {
      b.dispose();
    }
    super.dispose();
  }

  WaWelcome get _current => _initial!.copyWith(
        enabled: _enabled,
        text: _text.text.trim(),
        trigger: _trigger,
        buttons: [for (final b in _buttons) if (b.text.trim().isNotEmpty) b.text.trim()],
      );

  bool get _dirty {
    final a = _current;
    final b = _initial!;
    return a.enabled != b.enabled || a.text != b.text.trim() || a.trigger != b.trigger || a.buttons.join('\u0001') != b.buttons.join('\u0001');
  }

  String? get _textError {
    final n = _text.text.trim().length;
    return n < 1 || n > kWaMessageMax ? context.l10n.wa_err_text : null;
  }

  bool get _buttonsValid => _buttons.every((b) => b.text.trim().length <= kWaButtonMax);

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_textError != null || !_buttonsValid) return;
    final w = _current;
    setState(() => _saving = true);
    final res = await saveWaChange(context, ref, (c) => c.saveWelcome(w));
    if (!mounted) return;
    setState(() => _saving = false);
    if (res == WaSaveResult.saved) {
      Analytics.log('wa_auto_edit_save', {'kind': 'welcome', 'has_buttons': w.buttons.isNotEmpty, 'trigger': w.trigger.wire});
      HapticFeedback.lightImpact();
      AppSnackbar.show(context, message: context.l10n.wa_saved, kind: SnackKind.success);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final ch = ref.watch(whatsAppChannelControllerProvider).channel;
    if (ch == null) {
      return Scaffold(backgroundColor: c.backgroundMuted, appBar: AppBarStandard(title: l.wa_welcome), body: const WaLoadingBody());
    }
    if (_initial == null) _seed(ch.welcome);
    final canEdit = ch.permissions.canEditAuto;
    final ai = ref.watch(aiAgentControllerProvider).config;
    final aiAuto = ai != null && ai.enabled && ai.mode == AiMode.auto;
    final dirty = _dirty;
    final valid = _textError == null && _buttonsValid;

    return PopScope(
      canPop: !dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await waConfirmDiscard(context) && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(
          title: l.wa_welcome,
          background: c.backgroundMuted,
          actions: [
            if (canEdit)
              _saving
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: AppSpinner(size: 18, delayed: false))
                  : Semantics(
                      hint: valid ? null : l.wa_save_disabled,
                      child: AppBarTextAction(label: l.wa_save, onPressed: dirty && valid ? _save : null),
                    ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              WaEditorSwitchRow(
                title: l.wa_welcome_enable,
                value: _enabled,
                onChanged: canEdit ? (v) => setState(() => _enabled = v) : null,
              ),
              if (aiAuto)
                Container(
                  margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Row(
                    children: [
                      AppIcon(AppIcons.ai, size: AppIconSize.sm, color: c.textInfo),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(l.wa_ai_after_welcome, style: t.bodySmall)),
                    ],
                  ),
                ),
              WaEditorLabel(l.wa_message),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _text,
                      hint: l.wa_message_hint,
                      minLines: 4,
                      maxLines: 10,
                      maxLength: kWaMessageMax,
                      enabled: canEdit,
                      keyboardType: TextInputType.multiline,
                      error: _touched ? _textError : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    WaVariableChips(controller: _text, variables: const ['اسم_العميل', 'اسم_المتجر'], enabled: canEdit),
                  ],
                ),
              ),
              WaEditorLabel(l.wa_welcome_when),
              SettingsGroup(
                children: [
                  for (final (tr, label) in [
                    (WaWelcomeTrigger.firstMessage, l.wa_trigger_first),
                    (WaWelcomeTrigger.newConversation, l.wa_trigger_new),
                    (WaWelcomeTrigger.after24h, l.wa_trigger_24h),
                  ])
                    AppRadioRow(label: label, selected: _trigger == tr, onTap: canEdit ? () => setState(() => _trigger = tr) : () {}),
                ],
              ),
              WaEditorLabel(l.wa_buttons),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.wa_buttons_hint, style: t.caption.copyWith(color: c.textTertiary)),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < _buttons.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _buttons[i],
                                hint: l.wa_button_hint,
                                maxLength: kWaButtonMax,
                                enabled: canEdit,
                                error: _buttons[i].text.trim().length > kWaButtonMax ? l.wa_err_button : null,
                              ),
                            ),
                            if (canEdit)
                              AppIconButton(
                                icon: AppIcons.close,
                                semanticLabel: l.wa_delete,
                                onPressed: () => setState(() => _buttons.removeAt(i).dispose()),
                              ),
                          ],
                        ),
                      ),
                    if (canEdit && _buttons.length < 3)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton(
                          label: l.wa_button_add,
                          variant: AppButtonVariant.tonal,
                          size: AppButtonSize.small,
                          onPressed: () => setState(() => _buttons.add(TextEditingController()..addListener(_changed))),
                        ),
                      ),
                  ],
                ),
              ),
              WaEditorLabel(l.wa_preview),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: WaMessagePreview(
                  text: _text.text.trim(),
                  buttons: [for (final b in _buttons) b.text],
                  numberedButtons: !ch.isCloud,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
