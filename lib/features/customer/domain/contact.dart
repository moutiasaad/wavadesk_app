import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import 'contact_attribute.dart';
import 'contact_note.dart';

@immutable
class ContactTag {
  const ContactTag({required this.id, required this.name, this.color, this.system = false});

  final String id;
  final String name;

  /// Hex like "#D97706" (suggestion dot in the tag editor).
  final String? color;

  /// System / VIP tags render tonal.
  final bool system;

  factory ContactTag.fromJson(Map<String, dynamic> j) => ContactTag(
        id: '${j['id'] ?? j['name']}',
        name: '${j['name']}',
        color: j['color'] as String?,
        system: j['system'] == true,
      );
}

@immutable
class ContactChannel {
  const ContactChannel({required this.channel, required this.identifier, this.conversations = 0});

  final Channel channel;
  final String identifier;
  final int conversations;
}

enum OrderStatus { processing, shipped, delivered, cancelled }

@immutable
class ContactOrder {
  const ContactOrder({
    required this.id,
    required this.number,
    required this.date,
    required this.itemsCount,
    required this.total,
    required this.status,
    this.currency = 'SAR',
    this.url,
  });

  final String id;
  final String number;
  final DateTime date;
  final int itemsCount;
  final double total;
  final String currency;
  final OrderStatus status;

  /// External order page (v1 opens it in the browser).
  final String? url;
}

@immutable
class ContactPermissions {
  const ContactPermissions({
    this.canEdit = true,
    this.canBlock = true,
    this.canMerge = false,
    this.canDelete = false,
    this.canPinNotes = true,
  });

  final bool canEdit;
  final bool canBlock;
  final bool canMerge;
  final bool canDelete;
  final bool canPinNotes;

  /// Admins: everything. Supervisors: no merge/delete. Agents: edit + block.
  factory ContactPermissions.forRole(AgentRole role) => switch (role) {
        AgentRole.admin =>
          const ContactPermissions(canMerge: true, canDelete: true),
        AgentRole.supervisor => const ContactPermissions(),
        AgentRole.agent => const ContactPermissions(canPinNotes: false),
      };
}

@immutable
class AiSummary {
  const AiSummary({required this.text, required this.generatedAt});

  final String text;
  final DateTime generatedAt;
}

/// Full customer profile (Profile spec §9 `GET /contacts/{id}`).
@immutable
class Contact {
  const Contact({
    required this.id,
    required this.createdAt,
    this.name,
    this.avatarUrl,
    this.phone,
    this.email,
    this.city,
    this.country,
    this.language,
    this.timezone,
    this.isVip = false,
    this.isBlocked = false,
    this.blockedReason,
    this.tags = const [],
    this.attributes = const [],
    this.createdViaChannel,
    this.createdViaAgent,
    this.conversationsCount = 0,
    this.ordersCount,
    this.csat,
    this.firstContactAt,
    this.aiSummary,
    this.notes = const [],
    this.channels = const [],
    this.orders,
    this.ordersTotalSpent,
    this.permissions = const ContactPermissions(),
    this.visitorBrowser,
    this.visitorPage,
  });

  final String id;

  /// Null for anonymous website visitors.
  final String? name;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final String? city;
  final String? country;

  /// "ar" | "en" — the AI replies in this language.
  final String? language;

  /// IANA zone, e.g. "Asia/Riyadh".
  final String? timezone;
  final bool isVip;
  final bool isBlocked;
  final String? blockedReason;
  final List<ContactTag> tags;
  final List<ContactAttribute> attributes;
  final DateTime createdAt;
  final Channel? createdViaChannel;
  final String? createdViaAgent;
  final int conversationsCount;

  /// Null when no e-commerce integration is connected.
  final int? ordersCount;
  final double? csat;
  final DateTime? firstContactAt;
  final AiSummary? aiSummary;
  final List<ContactNote> notes;
  final List<ContactChannel> channels;
  final List<ContactOrder>? orders;
  final double? ordersTotalSpent;
  final ContactPermissions permissions;

  /// Web visitor metadata (unknown contacts).
  final String? visitorBrowser;
  final String? visitorPage;

  bool get isUnknown => name == null || name!.trim().isEmpty;

  /// "زائر #8812" style short id for anonymous visitors.
  String get shortId => id.length <= 4 ? id : id.substring(id.length - 4);

  String? get primaryIdentifier => phone ?? email;

  Contact copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? language,
    bool? isBlocked,
    String? blockedReason,
    bool clearBlockedReason = false,
    List<ContactTag>? tags,
    List<ContactAttribute>? attributes,
    List<ContactNote>? notes,
    AiSummary? aiSummary,
    int? conversationsCount,
    List<ContactChannel>? channels,
    bool? isVip,
  }) =>
      Contact(
        id: id,
        createdAt: createdAt,
        name: name ?? this.name,
        avatarUrl: avatarUrl,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        city: city ?? this.city,
        country: country,
        language: language ?? this.language,
        timezone: timezone,
        isVip: isVip ?? this.isVip,
        isBlocked: isBlocked ?? this.isBlocked,
        blockedReason: clearBlockedReason ? null : (blockedReason ?? this.blockedReason),
        tags: tags ?? this.tags,
        attributes: attributes ?? this.attributes,
        createdViaChannel: createdViaChannel,
        createdViaAgent: createdViaAgent,
        conversationsCount: conversationsCount ?? this.conversationsCount,
        ordersCount: ordersCount,
        csat: csat,
        firstContactAt: firstContactAt,
        aiSummary: aiSummary ?? this.aiSummary,
        notes: notes ?? this.notes,
        channels: channels ?? this.channels,
        orders: orders,
        ordersTotalSpent: ordersTotalSpent,
        permissions: permissions,
        visitorBrowser: visitorBrowser,
        visitorPage: visitorPage,
      );

  // ---- JSON (API) ------------------------------------------------------------------

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  /// `data` of `/mobile/v1` `GET contacts/{id}` (server ContactPresenter):
  /// tags are plain strings, notes use `body`, stats are nested, every
  /// contact is a WhatsApp customer and there are no orders.
  factory Contact.fromMobileJson(Map<String, dynamic> j) {
    Map<String, dynamic> obj(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};
    final stats = obj(j['stats']);
    final perms = obj(j['permissions']);
    final summary = j['ai_summary'] is Map ? obj(j['ai_summary']) : null;
    final tags = [for (final t in (j['tags'] as List? ?? const [])) '$t'];
    final phone = j['phone_hidden'] == true ? null : j['phone'] as String?;
    return Contact(
      id: '${j['id']}',
      name: (j['display_name'] as String?) ?? (j['name'] as String?),
      avatarUrl: j['avatar_url'] as String?,
      phone: phone,
      isVip: tags.any((t) => t.toUpperCase() == 'VIP'),
      isBlocked: j['blocked'] == true,
      blockedReason: j['blocked_reason'] as String?,
      tags: [for (final t in tags) ContactTag(id: t, name: t, system: t.toUpperCase() == 'VIP')],
      createdAt: _date(j['created_at']) ?? DateTime.now(),
      createdViaChannel: Channel.whatsapp,
      conversationsCount: (stats['total_conversations'] as num?)?.toInt() ?? 0,
      firstContactAt: _date(stats['first_contact_at'] ?? j['first_contact_at']),
      aiSummary: summary == null
          ? null
          : AiSummary(text: '${summary['text']}', generatedAt: _date(summary['generated_at']) ?? DateTime.now()),
      notes: [for (final n in (j['notes'] as List? ?? const [])) if (n is Map) ContactNote.fromJson(Map<String, dynamic>.from(n))],
      channels: [
        for (final c in (j['channels'] as List? ?? const []))
          if (c is Map)
            ContactChannel(
              channel: Channel.values.firstWhere((ch) => ch.name == c['channel'], orElse: () => Channel.whatsapp),
              // The row is one of the workspace's numbers; show the customer's address on it.
              identifier: phone ?? (c['name'] as String?) ?? '—',
              conversations: (c['conversations'] as num?)?.toInt() ?? 0,
            ),
      ],
      permissions: ContactPermissions(
        canEdit: perms['can_edit_contact'] != false,
        canBlock: perms['can_block'] == true,
        canMerge: perms['can_merge'] == true,
        canDelete: perms['can_delete'] == true,
        canPinNotes: perms['can_add_note'] != false,
      ),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> j) {
    final stats = j['stats'] is Map ? Map<String, dynamic>.from(j['stats'] as Map) : const <String, dynamic>{};
    final via = j['created_via'] is Map ? Map<String, dynamic>.from(j['created_via'] as Map) : const <String, dynamic>{};
    final summary = j['ai_summary'] is Map ? Map<String, dynamic>.from(j['ai_summary'] as Map) : null;
    final perms = j['permissions'] is Map ? Map<String, dynamic>.from(j['permissions'] as Map) : const <String, dynamic>{};
    Channel ch(Object? v) => Channel.values.firstWhere((c) => c.name == v, orElse: () => Channel.other);
    return Contact(
      id: '${j['id']}',
      name: j['name'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      phone: j['phone'] as String?,
      email: j['email'] as String?,
      city: j['city'] as String?,
      country: j['country'] as String?,
      language: j['language'] as String?,
      timezone: j['timezone'] as String?,
      isVip: j['is_vip'] == true,
      isBlocked: j['is_blocked'] == true,
      blockedReason: j['blocked_reason'] as String?,
      tags: [for (final t in (j['tags'] as List? ?? const [])) if (t is Map) ContactTag.fromJson(Map<String, dynamic>.from(t))],
      attributes: [
        for (final a in (j['attributes'] as List? ?? const [])) if (a is Map) ContactAttribute.fromJson(Map<String, dynamic>.from(a)),
      ],
      createdAt: _date(j['created_at']) ?? DateTime.now(),
      createdViaChannel: via['channel'] == null ? null : ch(via['channel']),
      createdViaAgent: via['agent'] is Map ? (via['agent'] as Map)['name'] as String? : null,
      conversationsCount: (stats['conversations'] as num?)?.toInt() ?? 0,
      ordersCount: (stats['orders'] as num?)?.toInt(),
      csat: (stats['csat'] as num?)?.toDouble(),
      firstContactAt: _date(stats['first_contact_at']),
      aiSummary: summary == null
          ? null
          : AiSummary(text: '${summary['text']}', generatedAt: _date(summary['generated_at']) ?? DateTime.now()),
      notes: [for (final n in (j['notes'] as List? ?? const [])) if (n is Map) ContactNote.fromJson(Map<String, dynamic>.from(n))],
      channels: [
        for (final c in (j['channels'] as List? ?? const []))
          if (c is Map)
            ContactChannel(
              channel: ch(c['channel']),
              identifier: '${c['identifier']}',
              conversations: (c['conversations'] as num?)?.toInt() ?? 0,
            ),
      ],
      orders: j['orders'] is List
          ? [
              for (final o in j['orders'] as List)
                if (o is Map)
                  ContactOrder(
                    id: '${o['id']}',
                    number: '${o['number']}',
                    date: _date(o['date']) ?? DateTime.now(),
                    itemsCount: (o['items_count'] as num?)?.toInt() ?? 0,
                    total: (o['total'] as num?)?.toDouble() ?? 0,
                    currency: (o['currency'] as String?) ?? 'SAR',
                    status: OrderStatus.values.firstWhere((s) => s.name == o['status'], orElse: () => OrderStatus.processing),
                    url: o['url'] as String?,
                  ),
            ]
          : null,
      ordersTotalSpent: (j['orders_total_spent'] as num?)?.toDouble(),
      permissions: ContactPermissions(
        canEdit: perms['can_edit'] != false,
        canBlock: perms['can_block'] != false,
        canMerge: perms['can_merge'] == true,
        canDelete: perms['can_delete'] == true,
        canPinNotes: perms['can_pin_notes'] != false,
      ),
    );
  }
}
