import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// One dialling country: national number length range and the digit
/// grouping used while typing (e.g. SA 9 digits "5x xxx xxxx" = [2, 3, 4]).
@immutable
class PhoneCountry {
  const PhoneCountry(this.iso, this.dial, this.min, this.max, this.groups, this.en, [this.ar, this.fr]);

  final String iso;
  final String dial;
  final int min;
  final int max;
  final List<int> groups;
  final String en;
  final String? ar;
  final String? fr;

  /// Regional-indicator flag emoji from the ISO code.
  String get flag => String.fromCharCodes(iso.codeUnits.map((u) => 0x1F1E6 + u - 0x41));

  String name(String lang) => switch (lang) {
        'ar' => ar ?? en,
        'fr' => fr ?? en,
        _ => en,
      };

  /// "5x xxx xxxx" style grouping of national [digits].
  String format(String digits) {
    final out = StringBuffer();
    var i = 0;
    for (final g in groups) {
      if (i >= digits.length) break;
      if (out.isNotEmpty) out.write(' ');
      final end = (i + g).clamp(0, digits.length);
      out.write(digits.substring(i, end));
      i = end;
    }
    if (i < digits.length) {
      if (out.isNotEmpty) out.write(' ');
      out.write(digits.substring(i));
    }
    return out.toString();
  }

  /// Placeholder like "5x xxx xxxx" from the grouping.
  String get example => format('5${'x' * (max - 1)}');
}

/// MENA / Gulf first (in this order), then everything else A–Z by English name.
abstract final class PhoneCountries {
  static const mena = <PhoneCountry>[
    PhoneCountry('SA', '966', 9, 9, [2, 3, 4], 'Saudi Arabia', 'السعودية', 'Arabie saoudite'),
    PhoneCountry('AE', '971', 9, 9, [2, 3, 4], 'United Arab Emirates', 'الإمارات', 'Émirats arabes unis'),
    PhoneCountry('KW', '965', 8, 8, [4, 4], 'Kuwait', 'الكويت', 'Koweït'),
    PhoneCountry('QA', '974', 8, 8, [4, 4], 'Qatar', 'قطر', 'Qatar'),
    PhoneCountry('BH', '973', 8, 8, [4, 4], 'Bahrain', 'البحرين', 'Bahreïn'),
    PhoneCountry('OM', '968', 8, 8, [4, 4], 'Oman', 'عُمان', 'Oman'),
    PhoneCountry('EG', '20', 10, 10, [3, 3, 4], 'Egypt', 'مصر', 'Égypte'),
    PhoneCountry('JO', '962', 9, 9, [1, 4, 4], 'Jordan', 'الأردن', 'Jordanie'),
    PhoneCountry('MA', '212', 9, 9, [3, 2, 2, 2], 'Morocco', 'المغرب', 'Maroc'),
    PhoneCountry('DZ', '213', 9, 9, [3, 2, 2, 2], 'Algeria', 'الجزائر', 'Algérie'),
    PhoneCountry('TN', '216', 8, 8, [2, 3, 3], 'Tunisia', 'تونس', 'Tunisie'),
    PhoneCountry('IQ', '964', 10, 10, [3, 3, 4], 'Iraq', 'العراق', 'Irak'),
    PhoneCountry('LB', '961', 7, 8, [2, 3, 3], 'Lebanon', 'لبنان', 'Liban'),
    PhoneCountry('LY', '218', 9, 9, [2, 3, 4], 'Libya', 'ليبيا', 'Libye'),
    PhoneCountry('SY', '963', 9, 9, [3, 3, 3], 'Syria', 'سوريا', 'Syrie'),
    PhoneCountry('PS', '970', 9, 9, [3, 3, 3], 'Palestine', 'فلسطين', 'Palestine'),
    PhoneCountry('YE', '967', 9, 9, [3, 3, 3], 'Yemen', 'اليمن', 'Yémen'),
    PhoneCountry('SD', '249', 9, 9, [2, 3, 4], 'Sudan', 'السودان', 'Soudan'),
    PhoneCountry('MR', '222', 8, 8, [2, 2, 2, 2], 'Mauritania', 'موريتانيا', 'Mauritanie'),
    PhoneCountry('TR', '90', 10, 10, [3, 3, 2, 2], 'Turkey', 'تركيا', 'Turquie'),
  ];

  static const others = <PhoneCountry>[
    PhoneCountry('AU', '61', 9, 9, [3, 3, 3], 'Australia', 'أستراليا', 'Australie'),
    PhoneCountry('AT', '43', 10, 13, [3, 4, 4], 'Austria', 'النمسا', 'Autriche'),
    PhoneCountry('BD', '880', 10, 10, [4, 6], 'Bangladesh', 'بنغلاديش', 'Bangladesh'),
    PhoneCountry('BE', '32', 9, 9, [3, 2, 2, 2], 'Belgium', 'بلجيكا', 'Belgique'),
    PhoneCountry('BR', '55', 10, 11, [2, 5, 4], 'Brazil', 'البرازيل', 'Brésil'),
    PhoneCountry('CA', '1', 10, 10, [3, 3, 4], 'Canada', 'كندا', 'Canada'),
    PhoneCountry('CN', '86', 11, 11, [3, 4, 4], 'China', 'الصين', 'Chine'),
    PhoneCountry('DK', '45', 8, 8, [2, 2, 2, 2], 'Denmark', 'الدنمارك', 'Danemark'),
    PhoneCountry('ET', '251', 9, 9, [2, 3, 4], 'Ethiopia', 'إثيوبيا', 'Éthiopie'),
    PhoneCountry('FI', '358', 9, 10, [2, 3, 4], 'Finland', 'فنلندا', 'Finlande'),
    PhoneCountry('FR', '33', 9, 9, [1, 2, 2, 2, 2], 'France', 'فرنسا', 'France'),
    PhoneCountry('DE', '49', 10, 11, [3, 4, 4], 'Germany', 'ألمانيا', 'Allemagne'),
    PhoneCountry('GR', '30', 10, 10, [3, 3, 4], 'Greece', 'اليونان', 'Grèce'),
    PhoneCountry('IN', '91', 10, 10, [5, 5], 'India', 'الهند', 'Inde'),
    PhoneCountry('ID', '62', 9, 12, [3, 4, 5], 'Indonesia', 'إندونيسيا', 'Indonésie'),
    PhoneCountry('IR', '98', 10, 10, [3, 3, 4], 'Iran', 'إيران', 'Iran'),
    PhoneCountry('IE', '353', 9, 9, [2, 3, 4], 'Ireland', 'أيرلندا', 'Irlande'),
    PhoneCountry('IT', '39', 9, 10, [3, 3, 4], 'Italy', 'إيطاليا', 'Italie'),
    PhoneCountry('JP', '81', 10, 10, [2, 4, 4], 'Japan', 'اليابان', 'Japon'),
    PhoneCountry('KE', '254', 9, 9, [3, 3, 3], 'Kenya', 'كينيا', 'Kenya'),
    PhoneCountry('MY', '60', 9, 10, [2, 4, 4], 'Malaysia', 'ماليزيا', 'Malaisie'),
    PhoneCountry('MX', '52', 10, 10, [2, 4, 4], 'Mexico', 'المكسيك', 'Mexique'),
    PhoneCountry('NL', '31', 9, 9, [1, 4, 4], 'Netherlands', 'هولندا', 'Pays-Bas'),
    PhoneCountry('NG', '234', 10, 10, [3, 3, 4], 'Nigeria', 'نيجيريا', 'Nigeria'),
    PhoneCountry('NO', '47', 8, 8, [3, 2, 3], 'Norway', 'النرويج', 'Norvège'),
    PhoneCountry('PK', '92', 10, 10, [3, 7], 'Pakistan', 'باكستان', 'Pakistan'),
    PhoneCountry('PH', '63', 10, 10, [3, 3, 4], 'Philippines', 'الفلبين', 'Philippines'),
    PhoneCountry('PL', '48', 9, 9, [3, 3, 3], 'Poland', 'بولندا', 'Pologne'),
    PhoneCountry('PT', '351', 9, 9, [3, 3, 3], 'Portugal', 'البرتغال', 'Portugal'),
    PhoneCountry('RU', '7', 10, 10, [3, 3, 2, 2], 'Russia', 'روسيا', 'Russie'),
    PhoneCountry('SN', '221', 9, 9, [2, 3, 2, 2], 'Senegal', 'السنغال', 'Sénégal'),
    PhoneCountry('ZA', '27', 9, 9, [2, 3, 4], 'South Africa', 'جنوب أفريقيا', 'Afrique du Sud'),
    PhoneCountry('KR', '82', 9, 10, [2, 4, 4], 'South Korea', 'كوريا الجنوبية', 'Corée du Sud'),
    PhoneCountry('ES', '34', 9, 9, [3, 3, 3], 'Spain', 'إسبانيا', 'Espagne'),
    PhoneCountry('LK', '94', 9, 9, [2, 3, 4], 'Sri Lanka', 'سريلانكا', 'Sri Lanka'),
    PhoneCountry('SE', '46', 7, 9, [2, 3, 4], 'Sweden', 'السويد', 'Suède'),
    PhoneCountry('CH', '41', 9, 9, [2, 3, 2, 2], 'Switzerland', 'سويسرا', 'Suisse'),
    PhoneCountry('TH', '66', 9, 9, [2, 3, 4], 'Thailand', 'تايلاند', 'Thaïlande'),
    PhoneCountry('GB', '44', 10, 10, [4, 6], 'United Kingdom', 'المملكة المتحدة', 'Royaume-Uni'),
    PhoneCountry('US', '1', 10, 10, [3, 3, 4], 'United States', 'الولايات المتحدة', 'États-Unis'),
    PhoneCountry('VN', '84', 9, 10, [3, 3, 4], 'Vietnam', 'فيتنام', 'Viêt Nam'),
  ];

  static final List<PhoneCountry> all = [
    ...mena,
    ...([...others]..sort((a, b) => a.en.compareTo(b.en))),
  ];

  static PhoneCountry byIso(String? iso) =>
      all.firstWhere((c) => c.iso == iso?.toUpperCase(), orElse: () => mena.first);

  /// Device region when it's in the table, else Saudi Arabia.
  static PhoneCountry initial() => byIso(ui.PlatformDispatcher.instance.locale.countryCode);

  /// Longest dial code that prefixes [digits] (international digits, no +).
  static PhoneCountry? matchDial(String digits) {
    PhoneCountry? best;
    for (final c in all) {
      if (digits.startsWith(c.dial) && (best == null || c.dial.length > best.dial.length)) best = c;
    }
    // +1 is shared by US and CA: keep the US.
    if (best?.dial == '1') return byIso('US');
    return best;
  }
}

/// Arabic-Indic / Persian digits → 0-9; everything else but digits and '+' dropped.
String normalizePhoneInput(String raw) {
  final out = StringBuffer();
  for (final r in raw.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(0x30 + r - 0x06F0);
    } else if ((r >= 0x30 && r <= 0x39) || r == 0x2B) {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// Mobile number with a country selector: flag + dial code button, then the
/// national number grouped live per country. Reports E.164 (`+9665…`) or
/// null while the length is not valid for the chosen country.
class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({super.key, required this.label, required this.onChanged, required this.invalidError});

  final String label;
  final ValueChanged<String?> onChanged;

  /// Shown once a number was typed that doesn't fit the country (after
  /// leaving the field, or when it is already too long).
  final String invalidError;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  PhoneCountry _country = PhoneCountries.initial();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _digits => _text.text.replaceAll(RegExp(r'[^0-9]'), '');

  void _report() {
    final d = _digits;
    final ok = d.length >= _country.min && d.length <= _country.max;
    widget.onChanged(ok ? '+${_country.dial}$d' : null);
  }

  void _setNational(String digits) {
    final capped = digits.length > _country.max ? digits.substring(0, _country.max) : digits;
    final text = _country.format(capped);
    _text.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  /// Typed or pasted text: "+966 5…" / "00966 5…" pick the country, a
  /// trunk 0 is dropped, the rest is grouped for the country.
  void _onInput(String raw) {
    var s = normalizePhoneInput(raw);
    final intl = s.startsWith('+') || s.startsWith('00');
    s = s.replaceAll('+', '');
    if (intl) {
      if (s.startsWith('00')) s = s.substring(2);
      final match = PhoneCountries.matchDial(s);
      if (match != null) {
        _country = match;
        s = s.substring(match.dial.length);
      }
    } else if (s.length > _country.max && s.startsWith(_country.dial)) {
      // Pasted with the code but without "+".
      s = s.substring(_country.dial.length);
    }
    if (s.startsWith('0')) s = s.substring(1);
    setState(() => _setNational(s));
    _report();
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, selected: _country);
    if (picked == null || !mounted) return;
    setState(() {
      _country = picked;
      _setNational(_digits);
    });
    _report();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final d = _digits;
    final valid = d.length >= _country.min && d.length <= _country.max;
    final error = d.isNotEmpty && !valid && (!_focus.hasFocus || d.length > _country.max) ? widget.invalidError : null;
    final hasError = error != null;
    final focused = _focus.hasFocus;
    final border = hasError ? c.error : (focused ? c.primary : c.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text(widget.label, style: t.inputLabel)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 1.5),
            boxShadow: focused ? [BoxShadow(color: hasError ? c.errorContainer : c.primaryContainer, spreadRadius: 4)] : null,
          ),
          // Phone numbers read left-to-right in every language.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: l.newmsg_country_a11y(_country.name(l.localeName), '+${_country.dial}'),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: _pickCountry,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.lg)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_country.flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text('+${_country.dial}', style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 2),
                          AppIcon(AppIcons.chevronDown, dp: 14, color: c.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: c.divider),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: widget.label,
                    child: TextField(
                      controller: _text,
                      focusNode: _focus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹+\s\-()]'))],
                      onChanged: _onInput,
                      style: t.bodyLarge.copyWith(letterSpacing: 0.5, fontFeatures: const [FontFeature.tabularFigures()]),
                      cursorColor: c.primary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: _country.example,
                        hintStyle: t.bodyLarge.copyWith(color: c.textTertiary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(error, style: t.caption.copyWith(color: c.textError, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

/// Searchable country list (name in the app language, flag, dial code).
Future<PhoneCountry?> showCountryPicker(BuildContext context, {required PhoneCountry selected}) {
  final l = context.l10n;
  return AppBottomSheet.showExpanded<PhoneCountry>(
    context,
    title: l.newmsg_country,
    builder: (ctx, controller) => _CountryList(controller: controller, selected: selected),
  );
}

class _CountryList extends StatefulWidget {
  const _CountryList({required this.controller, required this.selected});

  final ScrollController controller;
  final PhoneCountry selected;

  @override
  State<_CountryList> createState() => _CountryListState();
}

class _CountryListState extends State<_CountryList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final lang = l.localeName;
    final q = normalizePhoneInput(_q).replaceAll('+', '');
    final term = _q.trim().toLowerCase();
    final items = [
      for (final ct in PhoneCountries.all)
        if (term.isEmpty ||
            ct.name(lang).toLowerCase().contains(term) ||
            ct.en.toLowerCase().contains(term) ||
            ct.iso.toLowerCase() == term ||
            (q.isNotEmpty && ct.dial.startsWith(q)))
          ct,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: AppTextField(
            hint: l.newmsg_country_search,
            prefixIcon: AppIcons.search,
            autofocus: false,
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(l.newmsg_country_none, style: t.bodySmall.copyWith(color: c.textSecondary)))
              : ListView.builder(
                  controller: widget.controller,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final ct = items[i];
                    final selected = ct.iso == widget.selected.iso;
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(ct),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
                        child: Row(
                          children: [
                            Text(ct.flag, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ct.name(lang),
                                style: t.bodyMedium.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                              ),
                            ),
                            Text('+${ct.dial}', textDirection: TextDirection.ltr, style: t.bodySmall.copyWith(color: c.textSecondary)),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              AppIcon(AppIcons.check, dp: 16, color: c.primary),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
