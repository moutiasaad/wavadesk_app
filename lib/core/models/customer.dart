import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class TeamNote {
  const TeamNote({required this.author, required this.text, required this.createdAt});

  final String author;
  final String text;
  final DateTime createdAt;
}

@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.channel,
    this.phone,
    this.email,
    this.city,
    this.avatarUrl,
    this.tags = const [],
    this.conversationsCount = 0,
    this.ordersCount = 0,
    this.firstContact,
    this.notes = const [],
    this.channelIds = const {},
    this.customFields = const {},
    this.blocked = false,
  });

  final String id;
  final String name;
  final Channel channel;
  final String? phone;
  final String? email;
  final String? city;
  final String? avatarUrl;
  final List<String> tags;
  final int conversationsCount;
  final int ordersCount;
  final DateTime? firstContact;
  final List<TeamNote> notes;
  final Map<Channel, String> channelIds;
  final Map<String, String> customFields;
  final bool blocked;

  Customer copyWith({
    List<String>? tags,
    List<TeamNote>? notes,
    bool? blocked,
    String? name,
    String? phone,
    String? email,
    String? city,
    Map<String, String>? customFields,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    channel: channel,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    city: city ?? this.city,
    avatarUrl: avatarUrl,
    tags: tags ?? this.tags,
    conversationsCount: conversationsCount,
    ordersCount: ordersCount,
    firstContact: firstContact,
    notes: notes ?? this.notes,
    channelIds: channelIds,
    customFields: customFields ?? this.customFields,
    blocked: blocked ?? this.blocked,
  );
}
