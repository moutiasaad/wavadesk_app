import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// Sample data loaded from the JSON files in `assets/fake/`:
///  * `agents.json`        — me, colleagues, teams, workspace limits, WhatsApp
///  * `conversations.json` — conversations with their messages
///  * `content.json`       — knowledge, notifications, templates, quick
///                           replies, dashboard numbers
///
/// Edit those files to test scenarios — no code changes needed (hot restart
/// to reload). Times are relative to app start (`*_ago_minutes`), so the
/// data always looks fresh. Call [load] once before `runApp`.
abstract final class MockData {
  static Map<String, dynamic> _agents = const {};
  static Map<String, dynamic> _conversations = const {};
  static Map<String, dynamic> _content = const {};
  static Map<String, dynamic> _contacts = const {};
  static DateTime _loadedAt = DateTime.now();

  static Future<void> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    Future<Map<String, dynamic>> read(String name) async =>
        jsonDecode(await b.loadString('assets/fake/$name')) as Map<String, dynamic>;
    _agents = await read('agents.json');
    _conversations = await read('conversations.json');
    _content = await read('content.json');
    _contacts = await read('contacts.json');
    _loadedAt = DateTime.now();
    _me = _agent(_agents['me'] as Map<String, dynamic>);
    _colleagues = [for (final a in (_agents['colleagues'] as List? ?? const [])) _agent(a as Map<String, dynamic>)];
  }

  // ---- JSON helpers ---------------------------------------------------------------

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
      values.firstWhere((v) => v.name == raw, orElse: () => fallback);

  static DateTime _ago(Object? minutes) => _loadedAt.subtract(Duration(minutes: (minutes as num?)?.toInt() ?? 0));

  static DateTime? _agoOrNull(Object? minutes) => minutes == null ? null : _ago(minutes);

  static List<String> _strings(Object? raw) => [for (final v in (raw as List? ?? const [])) '$v'];

  static Map<String, dynamic> _map(Object? raw) => raw is Map ? Map<String, dynamic>.from(raw) : const {};

  // ---- Agents & workspace ------------------------------------------------------------

  static Agent _agent(Map<String, dynamic> j) => Agent(
    id: '${j['id']}',
    name: (j['name'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    role: _enum(AgentRole.values, j['role'], AgentRole.agent),
    presence: _enum(Presence.values, j['presence'], Presence.online),
    gender: j['gender'] as String?,
    openConversations: (j['open_conversations'] as num?)?.toInt() ?? 0,
    avatarUrl: j['avatar_url'] as String?,
  );

  static Agent _me = const Agent(id: 'a1', name: '', email: '');
  static List<Agent> _colleagues = const [];

  static Agent get me => _me;
  static List<Agent> get colleagues => _colleagues;

  static Agent? agentById(String? id) {
    if (id == null) return null;
    if (id == _me.id) return _me;
    for (final a in _colleagues) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Named colleagues used by the demo real-time events. If they're removed
  /// from `agents.json`, the first colleague (or me) stands in.
  static Agent get sara => agentById('a2') ?? (_colleagues.isNotEmpty ? _colleagues.first : _me);
  static Agent get khaled => agentById('a3') ?? (_colleagues.length > 1 ? _colleagues[1] : sara);
  static Agent get reem => agentById('a4') ?? sara;

  static List<Team> get teams => [
    for (final t in (_agents['teams'] as List? ?? const []))
      Team(id: '${(t as Map)['id']}', name: '${t['name']}', memberCount: (t['member_count'] as num?)?.toInt() ?? 0),
  ];

  /// Raw `agents.json` (assign-sheet extras: skills, team_ids, routing, …).
  static Map<String, dynamic> get agentsJson => _agents;

  static Map<String, dynamic> get _workspace => _map(_agents['workspace']);

  /// Open chats per agent before the capacity warning (Claim spec §6).
  static int get maxConcurrent => (_workspace['max_concurrent'] as num?)?.toInt() ?? 8;
  static bool get hardCapacityLimit => _workspace['hard_capacity_limit'] == true;
  static int get slaSeconds => (_workspace['sla_seconds'] as num?)?.toInt() ?? 300;

  static WhatsAppConnection get whatsapp {
    final w = _map(_agents['whatsapp']);
    return WhatsAppConnection(
      connected: w['connected'] != false,
      phoneNumber: w['phone_number'] as String?,
      displayName: w['display_name'] as String?,
      connectedSince: DateTime.tryParse(w['connected_since'] as String? ?? ''),
      messagesToday: (w['messages_today'] as num?)?.toInt() ?? 0,
    );
  }

  // ---- Conversations -----------------------------------------------------------------

  /// Fresh copies each call (controllers mutate their own lists).
  static List<Conversation> conversations() => [
    for (final c in (_conversations['conversations'] as List? ?? const []))
      _conversation(Map<String, dynamic>.from(c as Map)),
  ];

  static Customer _customer(Map<String, dynamic> j, Channel channel) {
    final ids = _map(j['channel_ids']);
    return Customer(
      id: '${j['id']}',
      name: (j['name'] as String?) ?? '',
      channel: channel,
      phone: j['phone'] as String?,
      email: j['email'] as String?,
      city: j['city'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      tags: _strings(j['tags']),
      conversationsCount: (j['conversations_count'] as num?)?.toInt() ?? 0,
      ordersCount: (j['orders_count'] as num?)?.toInt() ?? 0,
      firstContact: DateTime.tryParse(j['first_contact'] as String? ?? ''),
      blocked: j['blocked'] == true,
      notes: [
        for (final n in (j['notes'] as List? ?? const []))
          TeamNote(author: '${(n as Map)['author']}', text: '${n['text']}', createdAt: _ago(n['ago_minutes'])),
      ],
      channelIds: {for (final e in ids.entries) _enum(Channel.values, e.key, Channel.other): '${e.value}'},
      customFields: {for (final e in _map(j['custom_fields']).entries) e.key: '${e.value}'},
    );
  }

  static Conversation _conversation(Map<String, dynamic> j) {
    final channel = _enum(Channel.values, j['channel'], Channel.other);
    final ai = j['ai_suggestion'] is Map ? Map<String, dynamic>.from(j['ai_suggestion'] as Map) : null;
    final snoozeFor = (j['snoozed_for_minutes'] as num?)?.toInt();
    return Conversation(
      id: '${j['id']}',
      customer: _customer(_map(j['contact']), channel),
      status: _enum(ConversationStatus.values, j['status'], ConversationStatus.open),
      ownership: _enum(Ownership.values, j['ownership'], Ownership.unassigned),
      assignee: agentById(j['assignee_id'] as String?),
      priority: _enum(Priority.values, j['priority'], Priority.low),
      unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      waitingSince: _agoOrNull(j['waiting_since_ago_minutes']),
      orderRef: j['order_ref'] as String?,
      tags: _strings(j['tags']),
      viewers: [for (final id in _strings(j['viewer_ids'])) ?agentById(id)],
      snoozedUntil: snoozeFor == null ? null : _loadedAt.add(Duration(minutes: snoozeFor)),
      serviceWindowOpen: j['service_window_open'] != false,
      customerOnline: j['customer_online'] == true,
      lastSeen: _agoOrNull(j['last_seen_ago_minutes']),
      browsingPage: j['browsing_page'] as String?,
      channelConnected: j['channel_connected'] != false,
      aiPaused: j['ai_paused'] == true,
      aiSuggestion: ai == null
          ? null
          : AiSuggestion(
              text: (ai['text'] as String?) ?? '',
              source: (ai['source'] as String?) ?? '',
              confidence: (ai['confidence'] as num?)?.toDouble() ?? 0.9,
              noAnswer: ai['no_answer'] == true,
            ),
      messages: [for (final m in (j['messages'] as List? ?? const [])) _message(Map<String, dynamic>.from(m as Map))],
    );
  }

  static Message _message(Map<String, dynamic> j) {
    final senderType = j['sender_type'] as String? ?? 'contact';
    final senderId = j['sender_id'] as String?;
    final media = _map(j['media']);
    final reply = j['reply_to'] is Map ? Map<String, dynamic>.from(j['reply_to'] as Map) : null;
    final template = _map(j['template']);
    final card = _map(j['contact_card']);
    final ai = _map(j['ai_meta']);
    final event = j['system_event'] is Map ? Map<String, dynamic>.from(j['system_event'] as Map) : null;
    final type = switch (senderType) {
      'contact' => MessageBubbleType.incoming,
      'ai' => MessageBubbleType.outgoingAi,
      'note' => MessageBubbleType.internalNote,
      'system' => MessageBubbleType.system,
      _ => senderId == null || senderId == _me.id ? MessageBubbleType.outgoing : MessageBubbleType.outgoingColleague,
    };
    final duration = (media['duration_sec'] as num?)?.toInt();
    return Message(
      id: '${j['id']}',
      type: type,
      kind: _enum(MessageKind.values, j['type'], MessageKind.text),
      text: (j['text'] as String?) ?? '',
      sentAt: _ago(j['ago_minutes']),
      senderId: senderId ?? (type == MessageBubbleType.outgoing ? _me.id : null),
      senderName: j['sender_name'] as String? ?? agentById(senderId)?.name,
      delivery: _enum(DeliveryState.values, j['delivery'], DeliveryState.read),
      quote: reply == null
          ? null
          : QuotedMessage(
              sender: '${reply['sender_name'] ?? ''}',
              text: '${reply['preview'] ?? ''}',
              messageId: reply['id'] as String?,
            ),
      mediaDuration: duration == null ? null : Duration(seconds: duration),
      fileName: media['file_name'] as String?,
      fileSize: media['file_size'] as String?,
      albumCount: (media['count'] as num?)?.toInt() ?? 0,
      locationLabel: _map(j['location'])['address'] as String?,
      contactName: card['name'] as String?,
      contactPhone: card['phone'] as String?,
      emailSubject: j['subject'] as String?,
      templateName: template['name'] as String?,
      templateButtons: _strings(template['buttons']),
      aiSource: ai['source'] as String?,
      aiConfidence: (ai['confidence'] as num?)?.toDouble(),
      edited: j['edited'] == true,
      mentions: _strings(j['mentions']),
      transcript: j['transcript'] as String?,
      reactions: [
        for (final r in (j['reactions'] as List? ?? const []))
          Reaction(emoji: '${(r as Map)['emoji']}', byContact: r['by'] != 'agent'),
      ],
      systemEvent: event == null
          ? null
          : SystemEvent(
              kind: _systemKind(event['kind']),
              actorId: event['actor_id'] as String?,
              actorName: event['actor_name'] as String? ?? agentById(event['actor_id'] as String?)?.name,
              target: event['target'] as String?,
              value: event['value'] as String?,
            ),
    );
  }

  static SystemEventKind _systemKind(Object? k) => switch (k) {
    'claimed' => SystemEventKind.claimed,
    'assigned' => SystemEventKind.assigned,
    'unassigned' => SystemEventKind.unassigned,
    'ai_handoff' => SystemEventKind.aiHandoff,
    'ai_paused' => SystemEventKind.aiPaused,
    'ai_resumed' => SystemEventKind.aiResumed,
    'resolved' => SystemEventKind.resolved,
    'reopened' => SystemEventKind.reopened,
    'snoozed' => SystemEventKind.snoozed,
    'priority' => SystemEventKind.priority,
    'tag_added' => SystemEventKind.tagAdded,
    'window_closed' => SystemEventKind.windowClosed,
    'blocked' => SystemEventKind.blocked,
    'unblocked' => SystemEventKind.unblocked,
    'called' => SystemEventKind.called,
    'assign_undone' => SystemEventKind.assignUndone,
    _ => SystemEventKind.started,
  };

  /// Generated older rows so the inbox paginates (`history.count` in
  /// conversations.json; 0 disables).
  static List<Conversation> history() {
    final count = (_map(_conversations['history'])['count'] as num?)?.toInt() ?? 0;
    if (count <= 0) return const [];
    const names = ['سعود', 'منيرة', 'Omar Haddad', 'لطيفة', 'بندر', 'غادة', 'Sophie', 'ماجد', 'عهود', 'نايف'];
    const texts = [
      'شكرًا، تم استلام الطلب',
      'هل يوجد خصم على الكمية؟',
      'Thanks for the quick help!',
      'متى يصل الطلب؟',
      'أرغب في تغيير العنوان',
    ];
    const channels = [Channel.whatsapp, Channel.web, Channel.instagram, Channel.messenger, Channel.email];
    final team = _colleagues.isEmpty ? [_me] : _colleagues;
    return [
      for (var i = 0; i < count; i++)
        Conversation(
          id: 'h$i',
          customer: Customer(
            id: 'cuh$i',
            name: '${names[i % names.length]} ${i + 1}',
            channel: channels[i % channels.length],
          ),
          status: i % 7 == 0
              ? ConversationStatus.open
              : (i.isEven ? ConversationStatus.resolved : ConversationStatus.closed),
          ownership: i % 3 == 0 ? Ownership.mine : Ownership.colleague,
          assignee: i % 3 == 0 ? _me : team[i % team.length],
          messages: [
            Message(
              id: 'm1',
              type: i.isEven ? MessageBubbleType.incoming : MessageBubbleType.outgoingColleague,
              senderName: team[i % team.length].name,
              text: texts[i % texts.length],
              sentAt: _loadedAt.subtract(Duration(days: 1 + i ~/ 3, hours: i % 5)),
            ),
          ],
        ),
    ];
  }

  // ---- Customer profiles (contacts.json) ---------------------------------------------

  /// Raw profile extras for a contact id (language, timezone, notes, orders…).
  static Map<String, dynamic> contactExtras(String contactId) => _map(_map(_contacts['contacts'])[contactId]);

  /// Connected e-commerce integration (salla, zid, shopify) or null.
  static String? get storeIntegration => _map(_contacts['integrations'])['store'] as String?;

  /// Converts a relative ago-minutes value to a timestamp.
  static DateTime agoMinutes(Object? minutes) => _ago(minutes);

  // ---- Content -----------------------------------------------------------------------

  static List<QuickReply> get quickReplies => [
    for (final r in (_content['quick_replies'] as List? ?? const []))
      QuickReply(shortcut: '${(r as Map)['shortcut']}', title: '${r['title']}', text: '${r['text']}'),
  ];

  static List<MessageTemplate> get templates => [
    for (final t in (_content['templates'] as List? ?? const []))
      MessageTemplate(
        id: '${(t as Map)['id']}',
        name: '${t['name']}',
        category: '${t['category']}',
        body: '${t['body']}',
      ),
  ];

  static List<KnowledgeEntry> knowledge() => [
    for (final k in (_content['knowledge'] as List? ?? const []))
      KnowledgeEntry(
        id: '${(k as Map)['id']}',
        type: _enum(KnowledgeType.values, k['type'], KnowledgeType.faq),
        title: '${k['title']}',
        body: '${k['body']}',
        updatedAt: _ago(k['updated_ago_minutes']),
        usageCount: (k['usage_count'] as num?)?.toInt() ?? 0,
        enabled: k['enabled'] != false,
        keywords: _strings(k['keywords']),
      ),
  ];

  static List<AppNotification> notifications() => [
    for (final n in (_content['notifications'] as List? ?? const []))
      AppNotification(
        id: '${(n as Map)['id']}',
        kind: switch (n['kind']) {
          'ai_handoff' => NotificationKind.aiHandoff,
          final k => _enum(NotificationKind.values, k, NotificationKind.system),
        },
        title: '${n['title']}',
        body: '${n['body']}',
        createdAt: _ago(n['ago_minutes']),
        conversationId: n['conversation_id'] as String?,
        read: n['read'] == true,
      ),
  ];

  static DashboardStats get dashboard {
    final d = _map(_content['dashboard']);
    double num0(String k) => (d[k] as num?)?.toDouble() ?? 0;
    return DashboardStats(
      openConversations: num0('open_conversations').toInt(),
      openDelta: num0('open_delta'),
      waitingOverSla: num0('waiting_over_sla').toInt(),
      avgFirstResponse: Duration(seconds: num0('avg_first_response_seconds').toInt()),
      firstResponseDelta: num0('first_response_delta'),
      resolvedToday: num0('resolved_today').toInt(),
      resolvedDelta: num0('resolved_delta'),
      aiResolvedRate: num0('ai_resolved_rate'),
      aiRateDelta: num0('ai_rate_delta'),
      csat: num0('csat'),
      hourlyVolume: [for (final v in (d['hourly_volume'] as List? ?? const [])) (v as num).toInt()],
      channelShare: {
        for (final e in _map(d['channel_share']).entries)
          _enum(Channel.values, e.key, Channel.other): (e.value as num).toInt(),
      },
    );
  }
}
