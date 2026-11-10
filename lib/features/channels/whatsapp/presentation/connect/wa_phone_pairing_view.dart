import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/wa_connect_controller.dart';

/// Dial codes offered by the prefix selector (Gulf + MENA first).
const waDialCodes = <(String flag, String code)>[
  ('🇸🇦', '966'),
  ('🇦🇪', '971'),
  ('🇰🇼', '965'),
  ('🇶🇦', '974'),
  ('🇧🇭', '973'),
  ('🇴🇲', '968'),
  ('🇪🇬', '20'),
  ('🇯🇴', '962'),
  ('🇲🇦', '212'),
  ('🇩🇿', '213'),
  ('🇹🇳', '216'),
];

String waConnectErrorText(AppLocalizations l, String code) => switch (code) {
      'code_expired' => l.wa_code_expired,
      'number_taken' => l.wa_number_taken,
      'rate_limited' || 'too_many_requests' => l.wa_rate_limited,
      'multi_device_unsupported' => l.wa_multi_device,
      'invalid_phone' => l.wa_err_phone,
      'invalid_state' => l.wa_already_linked,
      'banned' => l.wa_banned,
      'network' => l.wa_network_error,
      _ => l.wa_connect_failed,
    };

/// Step 1 of phone pairing: E.164 field with a dial-code selector,
/// prefilled with the existing number on reconnect (WhatsApp spec §5.1).
class WaPhonePairingView extends ConsumerStatefulWidget {
  const WaPhonePairingView({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<WaPhonePairingView> createState() => _WaPhonePairingViewState();
}

class _WaPhonePairingViewState extends ConsumerState<WaPhonePairingView> {
  final _ctrl = TextEditingController();
  var _dial = waDialCodes.first;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final digits = (widget.initialPhone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      for (final d in waDialCodes) {
        if (digits.startsWith(d.$2)) {
          _dial = d;
          _ctrl.text = digits.substring(d.$2.length);
          break;
        }
      }
    }
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// National part without the trunk 0.
  String get _national => _ctrl.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
  bool get _valid => _national.length >= 7 && _national.length <= 12;
  String get _e164 => '+${_dial.$2}$_national';

  Future<void> _pickDial() async {
    final picked = await AppBottomSheet.show<(String, String)>(
      context,
      title: context.l10n.wa_by_phone,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final d in waDialCodes)
            AppRadioRow(
              label: '+${d.$2}',
              leading: Text(d.$1, style: const TextStyle(fontSize: 20)),
              selected: d == _dial,
              onTap: () => Navigator.of(ctx).pop(d),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _dial = picked);
  }

  void _submit() {
    setState(() => _touched = true);
    if (!_valid) return;
    FocusScope.of(context).unfocus();
    ref.read(waConnectControllerProvider.notifier).requestPairingCode(_e164);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(waConnectControllerProvider);
    final error = s.errorCode != null ? waConnectErrorText(l, s.errorCode!) : (_touched && !_valid ? l.wa_err_phone : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.wa_phone_tip, style: t.bodySmall.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        Text(l.wa_by_phone, style: t.inputLabel),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: c.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: c.border, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: s.loading ? null : _pickDial,
                  child: SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_dial.$1, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text('+${_dial.$2}', style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                          Icon(AppIcons.chevronDown, size: 14, color: c.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _ctrl,
                  hint: l.wa_phone_hint,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d ]')), LengthLimitingTextInputFormatter(15)],
                  enabled: !s.loading,
                  error: error,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (s.errorCode != null) ref.read(waConnectControllerProvider.notifier).editPhone();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: l.wa_get_code,
          size: AppButtonSize.large,
          expand: true,
          loading: s.loading,
          onPressed: s.loading ? null : _submit,
        ),
      ],
    );
  }
}
