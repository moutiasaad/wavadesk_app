import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';
import '../wa_save_feedback.dart';
import 'wa_message_preview.dart';
import 'wa_welcome_editor_screen.dart';
import '../widgets/wa_loading_body.dart';

/// Away message editor (WhatsApp spec §5.3). Read-only with a banner while
/// the AI answers after hours.
class WaAwayEditorScreen extends ConsumerStatefulWidget {
  const WaAwayEditorScreen({super.key});

  @override
  ConsumerState<WaAwayEditorScreen> createState() => _WaAwayEditorScreenState();
}

class _WaAwayEditorScreenState extends ConsumerState<WaAwayEditorScreen> {
  WaAway? _initial;
  late bool _enabled;
  late WaAwayWhen _when;
  late int _cooldown;
  final _text = TextEditingController();
  bool _saving = false;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _seed(WaAway a) {
    _initial = a;
    _enabled = a.enabled;
    _when = a.when;
    _cooldown = a.cooldownHours.clamp(1, 24);
    _text.text = a.text;
  }

  WaAway get _current => _initial!.copyWith(enabled: _enabled, text: _text.text.trim(), when: _when, cooldownHours: _cooldown);

  bool get _dirty {
    final a = _current;
    final b = _initial!;
    return a.enabled != b.enabled || a.text != b.text.trim() || a.when != b.when || a.cooldownHours != b.cooldownHours.clamp(1, 24);
  }

  String? get _textError {
    final n = _text.text.trim().length;
    return n < 1 || n > kWaMessageMax ? context.l10n.wa_err_text : null;
  }

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_textError != null) return;
    final a = _current;
    setState(() => _saving = true);
    final res = await saveWaChange(context, ref, (c) => c.saveAway(a));
    if (!mounted) return;
    setState(() => _saving = false);
    if (res == WaSaveResult.saved) {
      Analytics.log('wa_auto_edit_save', {'kind': 'away', 'has_buttons': false, 'trigger': a.when.wire});
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
      return Scaffold(backgroundColor: c.backgroundMuted, appBar: AppBarStandard(title: l.wa_away), body: const WaLoadingBody());
    }
    if (_initial == null) _seed(ch.away);
    final aiHandles = ch.away.handledByAi;
    final canEdit = ch.permissions.canEditAuto && !aiHandles;
    final dirty = _dirty;
    final valid = _textError == null;

    return PopScope(
      canPop: !dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await waConfirmDiscard(context) && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(
          title: l.wa_away,
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
              if (aiHandles)
                Container(
                  margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Row(
                    children: [
                      Icon(AppIcons.sparkle, size: 16, color: c.textInfo),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(l.wa_away_ai_banner, style: t.bodySmall)),
                      AppButton(
                        label: l.wa_go_ai,
                        size: AppButtonSize.small,
                        variant: AppButtonVariant.text,
                        onPressed: () => context.push(Routes.aiAgent),
                      ),
                    ],
                  ),
                ),
              Opacity(
                opacity: aiHandles ? 0.55 : 1,
                child: IgnorePointer(
                  ignoring: aiHandles,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WaEditorSwitchRow(
                        title: l.wa_away_enable,
                        value: _enabled && !aiHandles,
                        onChanged: canEdit ? (v) => setState(() => _enabled = v) : null,
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
                            WaVariableChips(controller: _text, variables: const ['وقت_العودة', 'اسم_العميل'], enabled: canEdit),
                          ],
                        ),
                      ),
                      WaEditorLabel(l.wa_send_when),
                      SettingsGroup(
                        children: [
                          AppRadioRow(
                            label: l.wa_away_outside,
                            selected: _when == WaAwayWhen.outsideHours,
                            onTap: () => canEdit ? setState(() => _when = WaAwayWhen.outsideHours) : null,
                          ),
                          AppRadioRow(
                            label: l.wa_away_team,
                            selected: _when == WaAwayWhen.teamAway,
                            onTap: () => canEdit ? setState(() => _when = WaAwayWhen.teamAway) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
                            child: Row(
                              children: [
                                Expanded(child: Text(l.wa_away_cooldown('$_cooldown'), style: t.bodyMedium)),
                                _Stepper(
                                  value: _cooldown,
                                  min: 1,
                                  max: 24,
                                  enabled: canEdit,
                                  onChanged: (v) => setState(() => _cooldown = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      WaEditorLabel(l.wa_preview),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: WaMessagePreview(text: _text.text.trim()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged, this.enabled = true});

  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: AppIcons.minus,
            size: 36,
            iconSize: 16,
            semanticLabel: '-',
            onPressed: enabled && value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text('$value', textAlign: TextAlign.center, style: context.text.buttonMedium, semanticsLabel: l.wa_away_cooldown('$value')),
          ),
          AppIconButton(
            icon: AppIcons.plus,
            size: 36,
            iconSize: 16,
            semanticLabel: '+',
            onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
