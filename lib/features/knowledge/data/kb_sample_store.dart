import '../domain/kb_entry.dart';

/// In-memory knowledge base shared by the sample list API (spec 12) and the
/// sample editor API (spec 13) so a saved answer shows up in the list.
class KbSampleStore {
  KbSampleStore._();

  static final instance = KbSampleStore._();

  int _seq = 100;
  String nextId(String prefix) => '${prefix}_s${_seq++}';

  static DateTime _ago({int days = 0, int hours = 0}) => DateTime.now().subtract(Duration(days: days, hours: hours));

  static List<int> _daily(int total) => [for (var i = 0; i < 30; i++) ((total / 30) * (0.5 + (i * 7 % 10) / 10)).round()];

  static const _me = KbPerson(id: 'a1', name: 'نورة');
  static const _khalid = KbPerson(id: 'a2', name: 'خالد');

  final List<KbQa> qa = [
    KbQa(
      id: 'kb_s1',
      question: 'هل يمكن الاسترجاع بعد 30 يومًا؟',
      altPhrasings: const ['أبي أرجّع الطلب', 'كم مدة الإرجاع؟'],
      answer: 'يمكن الاسترجاع خلال 30 يومًا من الاستلام بشرط أن يكون المنتج بحالته الأصلية. بعد 30 يومًا نقدّم استبدالًا أو رصيدًا في المتجر.',
      tags: const [KbTag(id: 'السياسات', name: 'السياسات')],
      usage: KbUsage(month: 38, thumbsUpRate: 0.92, lastUsedAt: _ago(hours: 2), daily: _daily(38)),
      recentUses: [
        KbRecentUse(conversationId: 'c1', customerName: 'وعد الزهراني', question: 'ممكن أرجّع فستان اشتريته قبل 40 يوم؟', at: _ago(hours: 2)),
        KbRecentUse(conversationId: 'c2', customerName: 'عبدالله الشهري', question: 'كم مدة الإرجاع عندكم؟', at: _ago(days: 1)),
      ],
      createdBy: _me,
      updatedBy: _me,
      createdAt: _ago(days: 60),
      updatedAt: _ago(days: 2),
      version: 3,
    ),
    KbQa(
      id: 'kb_s2',
      question: 'كم مدة التوصيل؟',
      altPhrasings: const ['متى يوصل الطلب؟', 'التوصيل كم يوم'],
      answer: 'التوصيل داخل المدن الرئيسية خلال 2–3 أيام عمل، ولباقي المناطق خلال 5–7 أيام عمل.',
      tags: const [KbTag(id: 'الشحن', name: 'الشحن')],
      usage: KbUsage(month: 27, thumbsUpRate: 0.88, lastUsedAt: _ago(hours: 5), daily: _daily(27)),
      createdBy: _khalid,
      updatedBy: _khalid,
      createdAt: _ago(days: 90),
      updatedAt: _ago(days: 9),
    ),
    KbQa(
      id: 'kb_s3',
      question: 'ما هي طرق الدفع المتاحة؟',
      answer: 'نقبل مدى، فيزا، ماستركارد، Apple Pay، والدفع عند الاستلام (برسوم 15 ريال).',
      tags: const [KbTag(id: 'الدفع', name: 'الدفع')],
      usage: KbUsage(month: 12, daily: _daily(12)),
      createdBy: _me,
      updatedBy: _me,
      createdAt: _ago(days: 200),
      updatedAt: _ago(days: 190),
    ),
    KbQa(
      id: 'kb_s4',
      question: 'هل يوجد فرع في الرياض؟',
      answer: 'نعم، فرعنا في الرياض بحي العليا، شارع التحلية، ويعمل من 10 صباحًا حتى 11 مساءً.',
      enabled: false,
      status: KbStatus.disabled,
      usage: KbUsage(month: 3, daily: _daily(3)),
      createdBy: _khalid,
      updatedBy: _khalid,
      createdAt: _ago(days: 40),
      updatedAt: _ago(days: 20),
    ),
  ];

  final List<KbQa> drafts = [
    KbQa(
      id: 'kb_s9',
      question: 'هل تغليف الهدايا مجاني؟',
      answer: 'نعم، تغليف الهدايا مجاني لجميع الطلبات مع بطاقة إهداء.',
      status: KbStatus.draft,
      enabled: false,
      draftedBy: _khalid,
      draftSource: KbDraftSource.agent,
      createdAt: _ago(hours: 3),
      updatedAt: _ago(hours: 3),
    ),
  ];

  final List<KbEntrySummary> files = [
    KbEntrySummary(
      id: 'kb_f1',
      type: KbType.file,
      title: 'سياسة الاستبدال والاسترجاع.pdf',
      status: KbStatus.active,
      usage30d: 12,
      updatedAt: _ago(days: 14),
      file: const KbFileInfo(pages: 14, sizeBytes: 1240000, mime: 'application/pdf'),
    ),
  ];

  final List<KbEntrySummary> links = [
    KbEntrySummary(
      id: 'kb_l1',
      type: KbType.link,
      title: 'الأسئلة الشائعة — متجرنا',
      status: KbStatus.active,
      usage30d: 6,
      updatedAt: _ago(days: 6),
      link: const KbLinkInfo(domain: 'store.example.com', pagesCount: 8),
    ),
  ];

  final List<KbUnanswered> unanswered = [
    KbUnanswered(
      id: 'unq_s1',
      question: 'هل عندكم مقاسات كبيرة؟',
      variants: const ['فيه مقاس XXL؟', 'المقاسات الكبيرة متوفرة؟'],
      count: 7,
      lastAskedAt: _ago(hours: 1),
      channels: const ['whatsapp', 'web'],
      draftAnswer: 'نعم، تتوفر أغلب التصاميم حتى مقاس XXL. يمكنك اختيار المقاس من صفحة المنتج.',
      conversationIds: const ['c1', 'c3'],
    ),
    KbUnanswered(
      id: 'unq_s2',
      question: 'متى ينزل التخفيض؟',
      variants: const ['فيه عروض قريب؟'],
      count: 4,
      lastAskedAt: _ago(hours: 6),
      channels: const ['whatsapp'],
      conversationIds: const ['c2'],
    ),
    KbUnanswered(
      id: 'unq_s3',
      question: 'هل توصلون للكويت؟',
      count: 2,
      lastAskedAt: _ago(days: 1),
      channels: const ['web'],
      conversationIds: const ['c4'],
    ),
  ];

  KbQa? qaById(String id) {
    for (final e in [...qa, ...drafts]) {
      if (e.id == id) return e;
    }
    return null;
  }

  KbUnanswered? unansweredById(String id) {
    for (final u in unanswered) {
      if (u.id == id) return u;
    }
    return null;
  }

  void upsertQa(KbQa e) {
    final i = qa.indexWhere((x) => x.id == e.id);
    i < 0 ? qa.insert(0, e) : qa[i] = e;
  }
}
