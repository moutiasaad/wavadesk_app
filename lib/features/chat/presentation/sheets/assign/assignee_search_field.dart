import 'package:flutter/material.dart';

import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// 44dp search, `surfaceVariant` → focused `surface` + 1.5 `primary` + ring
/// (Assign spec §5.2). Never autofocuses — the keyboard would cover the list.
class AssigneeSearchField extends StatelessWidget {
  const AssigneeSearchField({super.key, required this.onChanged, this.controller});

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: AppSearchField(
        hint: context.l10n.as_search,
        controller: controller,
        showCancel: false,
        autofocus: false,
        onChanged: onChanged,
      ),
    );
  }
}
