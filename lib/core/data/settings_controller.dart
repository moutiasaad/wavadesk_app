import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
    this.lastSegment = InboxSegment.mine,
    this.presence = Presence.online,
    this.notifyNewAssigned = true,
    this.notifyMentions = true,
    this.notifyWaiting = true,
    this.notifySound = true,
    this.recentSearches = const [],
  });

  final ThemeMode themeMode;
  final Locale locale;
  final InboxSegment lastSegment;
  final Presence presence;
  final bool notifyNewAssigned;
  final bool notifyMentions;
  final bool notifyWaiting;
  final bool notifySound;
  final List<String> recentSearches;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    InboxSegment? lastSegment,
    Presence? presence,
    bool? notifyNewAssigned,
    bool? notifyMentions,
    bool? notifyWaiting,
    bool? notifySound,
    List<String>? recentSearches,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
    lastSegment: lastSegment ?? this.lastSegment,
    presence: presence ?? this.presence,
    notifyNewAssigned: notifyNewAssigned ?? this.notifyNewAssigned,
    notifyMentions: notifyMentions ?? this.notifyMentions,
    notifyWaiting: notifyWaiting ?? this.notifyWaiting,
    notifySound: notifySound ?? this.notifySound,
    recentSearches: recentSearches ?? this.recentSearches,
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Per-device preferences (theme, language, last segment…). Every write is
/// persisted; reads at startup come from [SharedPreferences].
class SettingsController extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final p = ref.read(sharedPrefsProvider);
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = p.getString(key);
      return values.firstWhere((v) => v.name == name, orElse: () => fallback);
    }

    return AppSettings(
      themeMode: pick(ThemeMode.values, 'themeMode', ThemeMode.system),
      locale: Locale(p.getString('locale') ?? 'ar'),
      lastSegment: pick(InboxSegment.values, 'lastSegment', InboxSegment.mine),
      presence: pick(Presence.values, 'presence', Presence.online),
      notifyNewAssigned: p.getBool('notifyNewAssigned') ?? true,
      notifyMentions: p.getBool('notifyMentions') ?? true,
      notifyWaiting: p.getBool('notifyWaiting') ?? true,
      notifySound: p.getBool('notifySound') ?? true,
      recentSearches: p.getStringList('recentSearches') ?? const [],
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString('themeMode', mode.name);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _prefs.setString('locale', locale.languageCode);
  }

  void setLastSegment(InboxSegment segment) {
    state = state.copyWith(lastSegment: segment);
    _prefs.setString('lastSegment', segment.name);
  }

  void setPresence(Presence presence) {
    state = state.copyWith(presence: presence);
    _prefs.setString('presence', presence.name);
  }

  void setNotification({bool? newAssigned, bool? mentions, bool? waiting, bool? sound}) {
    state = state.copyWith(
      notifyNewAssigned: newAssigned,
      notifyMentions: mentions,
      notifyWaiting: waiting,
      notifySound: sound,
    );
    _prefs
      ..setBool('notifyNewAssigned', state.notifyNewAssigned)
      ..setBool('notifyMentions', state.notifyMentions)
      ..setBool('notifyWaiting', state.notifyWaiting)
      ..setBool('notifySound', state.notifySound);
  }

  void addRecentSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = [q, ...state.recentSearches.where((s) => s != q)].take(8).toList();
    state = state.copyWith(recentSearches: list);
    _prefs.setStringList('recentSearches', list);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: const []);
    _prefs.remove('recentSearches');
  }
}
