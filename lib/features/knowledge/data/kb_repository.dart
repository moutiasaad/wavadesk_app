import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/kb_entry.dart';
import 'kb_api.dart';

/// [KbApi] + a cached copy of the unfiltered first page so the tab opens
/// instantly and refreshes silently (Knowledge Base spec §7 "Cached").
class KbRepository {
  KbRepository(this.api, {this.cacheKey = 'kb_list_cache_v1'});

  final KbApi api;
  final String cacheKey;

  Future<KbListPage?> cached() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(cacheKey);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return KbListPage(
        items: [for (final e in (j['items'] as List)) KbEntrySummary.fromJson(Map<String, dynamic>.from(e as Map))],
        counts: KbCounts.fromJson(Map<String, dynamic>.from(j['counts'] as Map)),
        unansweredCount: (j['unanswered'] as num?)?.toInt() ?? 0,
        draftsPending: (j['drafts'] as num?)?.toInt() ?? 0,
        permissions: KbPermissions.fromJson(Map<String, dynamic>.from(j['permissions'] as Map)),
        nextCursor: j['next'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(KbListPage page) async {
    try {
      final c = page.counts;
      final p = page.permissions;
      await (await SharedPreferences.getInstance()).setString(
        cacheKey,
        jsonEncode({
          'items': [for (final e in page.items) e.toJson()],
          'counts': {'total': c.total, 'qa': c.qa, 'file': c.file, 'link': c.link, 'processing': c.processing},
          'unanswered': page.unansweredCount,
          'drafts': page.draftsPending,
          'permissions': {'can_edit': p.canEdit, 'can_delete': p.canDelete, 'can_review_drafts': p.canReviewDrafts},
          'next': page.nextCursor,
        }),
      );
    } catch (_) {
      // Cache is best effort.
    }
  }
}
