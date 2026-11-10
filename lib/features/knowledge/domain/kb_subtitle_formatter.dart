import '../../../l10n/app_localizations.dart';
import 'kb_entry.dart';

/// Row subtitle (Knowledge Base spec §4.6): "استُخدم 38 مرة · محدّث منذ يومين",
/// "استُخدم 12 مرة · 14 صفحة", links add the domain (LTR).
abstract final class KbSubtitleFormatter {
  /// "يومين" / "2 days" — the span after "منذ" / before "ago".
  static String span(AppLocalizations l, DateTime t, {DateTime? now}) {
    final d = (now ?? DateTime.now()).difference(t);
    if (d.inMinutes < 1) return l.kb_span_now;
    if (d.inHours < 1) return l.kb_span_minutes(d.inMinutes);
    if (d.inDays < 1) return l.kb_span_hours(d.inHours);
    if (d.inDays < 30) return l.kb_span_days(d.inDays);
    if (d.inDays < 365) return l.kb_span_months(d.inDays ~/ 30);
    return l.kb_span_years(d.inDays ~/ 365);
  }

  /// Left-to-right isolate so a domain keeps its order inside Arabic text.
  static String ltr(String s) => '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';

  static String format(AppLocalizations l, KbEntrySummary e, {DateTime? now}) {
    if (e.status == KbStatus.draft) {
      return e.draftSource == KbDraftSource.aiFromConversation || e.draftedBy == null
          ? l.kb_draft_from_conv
          : l.kb_draft_by(e.draftedBy!.name, span(l, e.draftedAt ?? e.updatedAt, now: now));
    }
    final parts = <String>[l.kb_used_n(e.usage30d)];
    switch (e.type) {
      case KbType.qa:
        parts.add(l.kb_updated(span(l, e.updatedAt, now: now)));
      case KbType.file:
        if (e.file != null && e.file!.pages > 0) {
          parts.add(l.kb_pages(e.file!.pages));
        } else {
          parts.add(l.kb_updated(span(l, e.updatedAt, now: now)));
        }
      case KbType.link:
        if (e.link != null && e.link!.domain.isNotEmpty) parts.add(ltr(e.link!.domain));
    }
    return parts.join(' · ');
  }
}
