import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/identifier.dart';
import '../application/customer_profile_controller.dart';
import '../data/contacts_repository.dart';
import '../domain/contact.dart';
import '../domain/contact_attribute.dart';

/// تعديل بيانات العميل (Profile spec §7.1).
class EditContactScreen extends ConsumerStatefulWidget {
  const EditContactScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends ConsumerState<EditContactScreen> {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _e164 = RegExp(r'^\+[1-9]\d{8,14}$');

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _city = TextEditingController();
  final Map<String, TextEditingController> _attrText = {};

  Contact? _original;
  String? _language;
  List<ContactAttribute> _attributes = const [];
  String? _phoneError;
  String? _emailError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _phone, _emailCtrl, _city]) {
      c.addListener(_rebuild);
    }
    final contact = ref.read(customerProfileControllerProvider(widget.contactId)).contact;
    if (contact != null) _init(contact);
  }

  void _rebuild() => setState(() {});

  void _init(Contact c) {
    _original = c;
    _name.text = c.name ?? '';
    _phone.text = c.phone ?? '';
    _emailCtrl.text = c.email ?? '';
    _city.text = c.city ?? '';
    _language = c.language;
    _attributes = [...c.attributes];
    for (final a in _attributes) {
      if (_isTextual(a.type)) {
        _attrText[a.key] = TextEditingController(text: a.value == null ? '' : '${a.value}')..addListener(_onAttrText(a.key));
      }
    }
  }

  static bool _isTextual(AttributeType t) =>
      t == AttributeType.text || t == AttributeType.number || t == AttributeType.url || t == AttributeType.select;

  VoidCallback _onAttrText(String key) => () {
        final ctrl = _attrText[key]!;
        setState(() {
          _attributes = [
            for (final a in _attributes)
              if (a.key != key)
                a
              else
                a.withValue(a.type == AttributeType.number
                    ? (ctrl.text.trim().isEmpty ? null : num.tryParse(ctrl.text.trim()) ?? ctrl.text.trim())
                    : (ctrl.text.trim().isEmpty ? null : ctrl.text.trim())),
          ];
        });
      };

  @override
  void dispose() {
    for (final c in [_name, _phone, _emailCtrl, _city, ..._attrText.values]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Change tracking ------------------------------------------------------------

  String? _norm(String s) => s.trim().isEmpty ? null : s.trim();

  int get _fieldsChanged {
    final o = _original;
    if (o == null) return 0;
    var n = 0;
    if (_norm(_name.text) != o.name) n++;
    if (_norm(_phone.text) != o.phone) n++;
    if (_norm(_emailCtrl.text) != o.email) n++;
    if (_norm(_city.text) != o.city) n++;
    if (_language != o.language) n++;
    for (final a in _attributes) {
      final before = o.attributes.where((x) => x.key == a.key).firstOrNull;
      if ('${before?.value}' != '${a.value}') n++;
    }
    return n;
  }

  bool get _changed => _fieldsChanged > 0;

  // ---- Actions ------------------------------------------------------------------------

  Future<void> _save() async {
    final l = context.l10n;
    String? phone = _norm(_phone.text);
    String? email = _norm(_emailCtrl.text);
    setState(() {
      _phoneError = null;
      _emailError = null;
    });
    if (phone != null) {
      phone = Identifier.normalizePhone(phone);
      if (!_e164.hasMatch(phone)) {
        setState(() => _phoneError = l.edit_phone_invalid);
        return;
      }
    }
    if (email != null && !_email.hasMatch(email)) {
      setState(() => _emailError = l.edit_email_invalid);
      return;
    }
    setState(() => _saving = true);
    final n = _fieldsChanged;
    try {
      await ref.read(customerProfileControllerProvider(widget.contactId).notifier).update(
            ContactEdit(
              name: _norm(_name.text),
              phone: phone,
              email: email,
              city: _norm(_city.text),
              language: _language,
              attributes: _attributes,
            ),
            fieldsChanged: n,
          );
      if (!mounted) return;
      _original = null; // allow pop without the discard dialog
      Navigator.of(context).pop();
      AppSnackbar.show(context, message: l.edit_saved, kind: SnackKind.success);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(context, message: l.edit_failed, kind: SnackKind.error);
      }
    }
  }

  /// "تجاهل التغييرات؟" — تجاهل (destructive) / متابعة التعديل (§7.1).
  Future<bool> _confirmDiscard() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (ctx) {
        final c = ctx.colors;
        final t = ctx.text;
        final width = MediaQuery.sizeOf(ctx).width - 48;
        return Dialog(
          backgroundColor: c.surfaceElevated,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width.clamp(0, 360)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: c.warningContainer, shape: BoxShape.circle),
                    child: AppIcon(AppIcons.error, color: c.textWarning),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(header: true, child: Text(l.edit_discard_title, style: t.h4, textAlign: TextAlign.center)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l.edit_discard_body, style: t.bodyMedium.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: l.edit_discard,
                    variant: AppButtonVariant.destructiveFilled,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l.edit_keep,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return ok ?? false;
  }

  Future<void> _pickLanguage() async {
    final l = context.l10n;
    final picked = await AppBottomSheet.show<String>(
      context,
      title: l.edit_language,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            for (final (code, label) in [('ar', 'العربية'), ('en', 'English'), ('', l.edit_not_set)])
              AppRadioRow(
                label: label,
                selected: (_language ?? '') == code,
                onTap: () => Navigator.pop(ctx, code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _language = picked.isEmpty ? null : picked);
  }

  Future<void> _pickDate(ContactAttribute a) async {
    final initial = DateTime.tryParse('${a.value}') ?? DateTime(1995);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final iso = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    setState(() => _attributes = [for (final x in _attributes) x.key == a.key ? x.withValue(iso) : x]);
  }

  // ---- Build --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    // Contact may arrive after the screen opens (deep link).
    final contact = ref.watch(customerProfileControllerProvider(widget.contactId)).contact;
    if (_original == null && contact != null && _name.text.isEmpty && !_saving) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _original == null) setState(() => _init(contact));
      });
    }

    final languageLabel = switch (_language) {
      'ar' => 'العربية',
      'en' => 'English',
      _ => l.edit_not_set,
    };

    Widget gap() => const SizedBox(height: AppSpacing.lg);

    Widget attributeField(ContactAttribute a) {
      switch (a.type) {
        case AttributeType.bool:
          return Row(
            children: [
              Expanded(child: Text(a.label, style: t.inputLabel)),
              AppSwitch(
                value: a.value == true || a.value == 'true',
                semanticLabel: a.label,
                onChanged: (v) => setState(() => _attributes = [for (final x in _attributes) x.key == a.key ? x.withValue(v) : x]),
              ),
            ],
          );
        case AttributeType.date:
          return _PickerRow(
            label: a.label,
            value: a.isEmpty ? l.edit_not_set : a.display(yes: '', no: ''),
            empty: a.isEmpty,
            icon: AppIcons.clock,
            onTap: () => _pickDate(a),
          );
        case AttributeType.text || AttributeType.number || AttributeType.url || AttributeType.select:
          return AppTextField(
            label: a.label,
            controller: _attrText[a.key],
            keyboardType: switch (a.type) {
              AttributeType.number => const TextInputType.numberWithOptions(decimal: true),
              AttributeType.url => TextInputType.url,
              _ => TextInputType.text,
            },
            textDirection: a.type == AttributeType.url || a.type == AttributeType.number ? TextDirection.ltr : null,
          );
      }
    }

    return PopScope(
      canPop: !_changed || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _original = null;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBarStandard(
          title: l.edit_title,
          leading: AppIconButton(
            icon: AppIcons.close,
            iconSize: 24,
            semanticLabel: l.common_close,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [AppBarTextAction(label: l.edit_save, onPressed: _changed && !_saving ? _save : null)],
        ),
        body: contact == null && _original == null
            ? const Center(child: AppSpinner())
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  AppTextField(label: l.edit_name, controller: _name, textInputAction: TextInputAction.next),
                  gap(),
                  AppTextField(
                    label: l.edit_phone,
                    controller: _phone,
                    hint: '+966 5x xxx xxxx',
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    error: _phoneError,
                  ),
                  gap(),
                  AppTextField(
                    label: l.edit_email,
                    controller: _emailCtrl,
                    hint: 'name@company.com',
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    error: _emailError,
                  ),
                  gap(),
                  AppTextField(label: l.edit_city, controller: _city),
                  gap(),
                  _PickerRow(
                    label: l.edit_language,
                    value: languageLabel,
                    empty: _language == null,
                    icon: AppIcons.globe,
                    onTap: _pickLanguage,
                  ),
                  for (final a in _attributes) ...[gap(), attributeField(a)],
                ],
              ),
      ),
    );
  }
}

/// Label above + tappable field-like row (select / date inputs).
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.value, required this.onTap, required this.icon, this.empty = false});

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(label, style: t.inputLabel)),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label، $value',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.border, width: 1.5),
              ),
              child: Row(
                children: [
                  AppIcon(icon, dp: 18, color: c.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: t.bodyLarge.copyWith(color: empty ? c.textTertiary : c.textPrimary),
                    ),
                  ),
                  AppIcon(AppIcons.chevronDown, dp: 18, color: c.borderStrong),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
