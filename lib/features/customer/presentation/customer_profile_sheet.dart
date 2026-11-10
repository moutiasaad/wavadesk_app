import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../application/customer_profile_controller.dart';
import 'customer_profile_view.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_pinned_header.dart';

/// Opens the profile over the chat (Profile spec §3): draggable sheet with
/// snap points 0.5 · ≈0.88 (top edge 96dp below the screen top) · 1.0.
/// Dragging below 0.5 dismisses; the top radius goes 28 → 0 at full height.
/// [onNote] is kept for callers that want an internal-note shortcut; the
/// "ملاحظة" quick action itself adds a contact-level note (§5.2).
Future<void> showCustomerProfileSheet(
  BuildContext context, {
  required String contactId,
  String? conversationId,
  VoidCallback? onNote,
}) {
  final height = MediaQuery.sizeOf(context).height;
  final initial = ((height - 96) / height).clamp(0.55, 0.98).toDouble();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.slow,
      reverseDuration: const Duration(milliseconds: 250),
      curve: AppMotion.standard,
    ),
    builder: (_) => _ProfileSheet(contactId: contactId, conversationId: conversationId, initial: initial),
  );
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet({required this.contactId, required this.conversationId, required this.initial});

  final String contactId;
  final String? conversationId;
  final double initial;

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  final _sheet = DraggableScrollableController();
  double _extent = 0;
  bool _heroVisible = true;

  @override
  void initState() {
    super.initState();
    _extent = widget.initial;
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _openPage() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(Routes.contact(widget.contactId));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final contact = ref.watch(customerProfileControllerProvider(widget.contactId).select((s) => s.contact));
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final reduced = AppMotion.reduced(context);

    // 0 at the default snap, 1 at full height.
    final toFull = ((_extent - widget.initial) / (1 - widget.initial)).clamp(0.0, 1.0);
    final radius = AppRadius.sheet * (1 - toFull);
    final atFull = _extent >= 0.99;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: l.profile_dialog_label(contact == null ? '' : profileDisplayName(contact, l)),
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          if ((n.extent - _extent).abs() > 0.002) setState(() => _extent = n.extent);
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _sheet,
          expand: false,
          initialChildSize: widget.initial,
          minChildSize: 0.5,
          maxChildSize: 1,
          snap: true,
          snapAnimationDuration: reduced ? const Duration(milliseconds: 1) : AppMotion.normal,
          snapSizes: [widget.initial],
          builder: (context, scroll) => Container(
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
              boxShadow: context.shadows.high,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Status-bar safe at full height.
                SizedBox(height: topInset * toFull),
                // Grab handle 40×5 (top 8 / bottom 12); "فتح كصفحة" at full.
                SizedBox(
                  height: 25,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(top: 8, bottom: 12),
                          decoration: BoxDecoration(color: c.borderStrong, borderRadius: BorderRadius.circular(AppRadius.full)),
                        ),
                      ),
                      if (atFull)
                        PositionedDirectional(
                          end: AppSpacing.sm,
                          top: 0,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: c.primary,
                              textStyle: context.text.buttonSmall,
                              minimumSize: const Size(48, 25),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            ),
                            onPressed: _openPage,
                            child: Text(l.profile_open_page),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomerProfileView(
                          contactId: widget.contactId,
                          conversationId: widget.conversationId,
                          controller: scroll,
                          container: 'sheet',
                          onHeroVisibilityChanged: (v) => setState(() => _heroVisible = v),
                        ),
                      ),
                      if (contact != null)
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          end: 0,
                          child: IgnorePointer(
                            ignoring: _heroVisible,
                            child: AnimatedOpacity(
                              opacity: _heroVisible ? 0 : 1,
                              duration: AppMotion.fast,
                              child: ProfilePinnedHeader(
                                contact: contact,
                                onClose: () => Navigator.of(context).maybePop(),
                                onOpenPage: _openPage,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
