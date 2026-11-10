import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../application/ai_rewrite_controller.dart';
import '../../../domain/conversation_detail.dart';
import '../../../domain/rewrite_session.dart';
import 'rewrite_footer.dart';
import 'rewrite_header.dart';
import 'rewrite_more_styles_sheet.dart';
import 'rewrite_original_box.dart';
import 'rewrite_result_card.dart';
import 'rewrite_style_chips.dart';

/// "حسّن الرد بالذكاء" (Rewrite spec, frame 06). A bottom sheet over the
/// chat; returns the wording to put into the composer — never sends.
Future<RewriteOutcome?> showAiRewriteSheet(
  BuildContext context,
  WidgetRef ref, {
  required ConversationDetail detail,
  required String source,
  required RewriteEntry entry,
  required bool note,
}) {
  final args = RewriteArgs(
    conversationId: detail.id,
    contactId: detail.contact.id,
    source: source,
    entry: entry,
    note: note,
    channel: detail.channel,
    agentId: ref.read(currentAgentProvider).id,
    aiEnabled: detail.aiEnabledInWorkspace,
    canViewPlans: detail.permissions.isAdmin,
  );
  return showModalBottomSheet<RewriteOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    // §12: open 280ms slide-up easeOutCubic; use → close 220ms.
    sheetAnimationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 280),
            reverseDuration: Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
    builder: (ctx) => AiRewriteSheet(args: args),
  );
}

/// The same sheet for a knowledge-base answer (Add Answer spec §6.2): styles
/// أكثر احترافية · أقصر · أكثر ودًّا · صحّح الإملاء · ترجم · حوّلها لنقاط.
Future<RewriteOutcome?> showKbAnswerRewriteSheet(
  BuildContext context,
  WidgetRef ref, {
  required String source,
  bool aiEnabled = true,
}) {
  final args = RewriteArgs(
    conversationId: '',
    contactId: '',
    source: source,
    entry: RewriteEntry.composer,
    note: false,
    channel: Channel.whatsapp,
    agentId: ref.read(currentAgentProvider).id,
    aiEnabled: aiEnabled,
    canViewPlans: ref.read(currentAgentProvider).isAdmin,
    kbAnswer: true,
  );
  return showModalBottomSheet<RewriteOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    sheetAnimationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 280),
            reverseDuration: Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
    builder: (ctx) => AiRewriteSheet(args: args),
  );
}

class AiRewriteSheet extends ConsumerStatefulWidget {
  const AiRewriteSheet({super.key, required this.args});

  final RewriteArgs args;

  @override
  ConsumerState<AiRewriteSheet> createState() => _AiRewriteSheetState();
}

class _AiRewriteSheetState extends ConsumerState<AiRewriteSheet> {
  final _resultFocus = FocusNode(debugLabel: 'rw-result');
  bool _announcedLoading = false;

  AiRewriteController get _ctrl => ref.read(aiRewriteControllerProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    // Initial focus on the result card (§10).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resultFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _resultFocus.dispose();
    super.dispose();
  }

  void _announce(String message) {
    if (!mounted) return;
    SemanticsService.announce(message, Directionality.of(context));
  }

  void _onSessionChange(RewriteSession? prev, RewriteSession next) {
    final l = context.l10n;
    if (next.status == RewriteStatus.loading && prev?.status != RewriteStatus.loading && !_announcedLoading) {
      _announcedLoading = true; // "Loading announced once"
      _announce(l.rw_writing.replaceAll('…', ''));
    }
    final arrived =
        next.status == RewriteStatus.success &&
        (prev?.status != RewriteStatus.success || prev?.current?.id != next.current?.id);
    if (arrived && next.current != null) {
      final text = next.current!.effectiveText;
      _announce(l.rw_a11y_ready(text.length > 80 ? text.substring(0, 80) : text));
    }
  }

  Future<void> _openMore(RewriteSession s) async {
    final picked = await showRewriteMoreStylesSheet(
      context,
      selected: s.style,
      sourceIsArabic: s.sourceIsArabic,
      teamStyles: s.teamStyles,
    );
    if (picked != null && mounted) _ctrl.selectMoreStyle(picked);
  }

  void _use() {
    final out = _ctrl.use();
    if (out != null) Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(aiRewriteControllerProvider(widget.args));
    ref.listen(aiRewriteControllerProvider(widget.args), _onSessionChange);

    final media = MediaQuery.of(context);
    final bottomSafe = media.viewPadding.bottom;
    final keyboard = media.viewInsets.bottom;

    final String primaryLabel;
    final VoidCallback? onPrimary;
    if (s.editingOriginal) {
      primaryLabel = l.rw_rerun;
      onPrimary = _ctrl.rerunEdited;
    } else {
      primaryLabel = s.current?.unchanged == true && !(s.current?.edited ?? false) ? l.rw_use_as_is : l.rw_use;
      onPrimary = s.canUse ? _use : null;
    }
    final showFooter = s.status != RewriteStatus.planLimit;

    return Padding(
      // Keyboard-aware: the sheet lifts with viewInsets (§3).
      padding: EdgeInsets.only(bottom: keyboard),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: l.rw_title,
        child: Container(
          constraints: BoxConstraints(maxHeight: (media.size.height - keyboard) * 0.92),
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
            boxShadow: context.shadows.high,
          ),
          padding: const EdgeInsets.fromLTRB(18, AppSpacing.sm, 18, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle 40×5, gap 12.
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: c.borderStrong, borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RewriteHeader(onClose: () => Navigator.of(context).maybePop()),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RewriteOriginalBox(
                        source: s.source,
                        editing: s.editingOriginal,
                        selectionMode: s.entry == RewriteEntry.selection,
                        editEnabled: s.status != RewriteStatus.planLimit,
                        onEdit: () {
                          _ctrl.startEditOriginal();
                        },
                        onChanged: (v) {
                          _ctrl.updatePendingSource(v);
                        },
                      ),
                      // 14dp gap; chips carry 8dp of hit padding on top.
                      const SizedBox(height: 6),
                      RewriteStyleChips(
                        chips: s.chips,
                        selected: s.style,
                        sourceIsArabic: s.sourceIsArabic,
                        cachedIds: {
                          for (final e in s.versions.entries)
                            if (e.value.isNotEmpty) e.key,
                        },
                        enabled: s.chipsEnabled && !s.editingOriginal && s.status != RewriteStatus.planLimit,
                        highlightTranslate: s.customerPrefersOther,
                        onSelect: _ctrl.selectStyle,
                        onMore: s.note || s.kbAnswer ? null : () => _openMore(s),
                      ),
                      if (s.customerPrefersOther) RewriteLanguageHint(language: s.preferredLanguage!),
                      SizedBox(height: s.customerPrefersOther ? 14 : 6),
                      RewriteResultCard(
                        session: s,
                        labelFocusNode: _resultFocus,
                        onRetry: _ctrl.retry,
                        onEdit: _ctrl.editResult,
                        onPrevious: () => _ctrl.showVersion(s.currentIndex - 1),
                        onNext: () => _ctrl.showVersion(s.currentIndex + 1),
                        onViewPlans: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(Routes.subscription);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (showFooter) ...[
                const SizedBox(height: AppSpacing.lg),
                RewriteFooter(
                  primaryLabel: primaryLabel,
                  onPrimary: onPrimary,
                  showRegenerate: !s.editingOriginal,
                  atMaxVersions: s.atMaxVersions,
                  onRegenerate: s.canRegenerate && s.status == RewriteStatus.success ? _ctrl.regenerate : null,
                ),
              ],
              SizedBox(height: AppSpacing.xxl + (keyboard > 0 ? 0 : bottomSafe)),
            ],
          ),
        ),
      ),
    );
  }
}
