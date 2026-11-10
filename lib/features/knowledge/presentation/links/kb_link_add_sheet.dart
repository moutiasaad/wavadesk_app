import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/knowledge_controller.dart';
import '../../data/kb_api.dart';

/// "إضافة رابط" (Knowledge Base spec §6.3). Returns the new entry id.
Future<String?> showKbLinkAddSheet(BuildContext context) => AppBottomSheet.show<String>(
      context,
      title: context.l10n.kb_add_link,
      builder: (_) => const KbLinkAddSheet(),
    );

/// https only, with a host that has a dot.
bool kbValidUrl(String s) {
  final u = Uri.tryParse(s.trim());
  return u != null && u.scheme == 'https' && u.host.contains('.');
}

class KbLinkAddSheet extends ConsumerStatefulWidget {
  const KbLinkAddSheet({super.key});

  @override
  ConsumerState<KbLinkAddSheet> createState() => _KbLinkAddSheetState();
}

class _KbLinkAddSheetState extends ConsumerState<KbLinkAddSheet> {
  final _url = TextEditingController();
  bool _subpages = false;
  bool _touched = false;
  bool _saving = false;
  String? _title;
  bool _previewing = false;
  Timer? _debounce;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _url.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() => _title = null);
    _debounce?.cancel();
    if (!kbValidUrl(v)) return;
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final seq = ++_seq;
      setState(() => _previewing = true);
      String? title;
      try {
        title = await ref.read(kbApiProvider).linkPreviewTitle(v.trim());
      } catch (_) {}
      if (!mounted || seq != _seq) return;
      setState(() {
        _previewing = false;
        _title = title;
      });
    });
  }

  Future<void> _add() async {
    final l = context.l10n;
    setState(() => _touched = true);
    if (!kbValidUrl(_url.text)) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(kbApiProvider).addLink(_url.text.trim(), includeSubpages: _subpages);
      Analytics.log('kb_link_add', {'subpages': _subpages});
      ref.read(knowledgeControllerProvider.notifier).entryCreated();
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e is KbApiException && e.isNotSupported ? l.kb_web_only : (e is KbApiException && e.isNetwork ? l.kb_offline : l.kb_save_err);
      AppSnackbar.show(context, message: msg, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final invalid = _touched && !kbValidUrl(_url.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: l.kb_link_url,
            hint: 'https://',
            controller: _url,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            error: invalid ? l.kb_url_invalid : null,
            onChanged: _changed,
            onSubmitted: (_) => _add(),
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            child: _previewing || _title != null
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        if (_previewing) AppSpinner(size: 14, color: c.textTertiary, delayed: false) else AppIcon(AppIcons.globe, size: AppIconSize.sm, color: c.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        if (_title != null) Expanded(child: Text(_title!, style: t.bodySmall.copyWith(color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => setState(() => _subpages = !_subpages),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(l.kb_link_subpages, style: t.listTitle.copyWith(fontSize: 14))),
                  AppSwitch(value: _subpages, semanticLabel: l.kb_link_subpages, onChanged: (v) => setState(() => _subpages = v)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: l.kb_add, expand: true, loading: _saving, onPressed: _saving ? null : _add),
        ],
      ),
    );
  }
}
