import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerStats {
  int played = 0;
  int wins = 0;
  int imposterRounds = 0;
}

class AppStore extends ChangeNotifier {
  SharedPreferences? _prefs;
  String language = 'en';
  String theme = 'system';
  bool haptics = true;
  bool sounds = false;
  bool storageAvailable = true;
  List<String> lastPlayers = [];
  List<String> lastCategories = [];
  int lastImposters = 1;
  int lastMinutes = 3;
  final List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => List.unmodifiable(_history.map((r) => Map<String, dynamic>.unmodifiable(r)));
  ThemeMode get themeMode => switch (theme) { 'dark' => ThemeMode.dark, 'light' => ThemeMode.light, _ => ThemeMode.system };

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString('suspecto.v1');
      if (raw == null) { return; }
      final data = jsonDecode(raw) as Map<String, dynamic>;
      language = data['language'] == 'ar' ? 'ar' : 'en';
      theme = ['system', 'dark', 'light'].contains(data['theme']) ? data['theme'] as String : 'system';
      haptics = data['haptics'] != false;
      sounds = data['sounds'] == true;
      lastPlayers = List<String>.from(data['players'] ?? []);
      lastCategories = List<String>.from(data['categories'] ?? []);
      lastImposters = data['imposters'] is int ? data['imposters'] as int : 1;
      lastMinutes = data['minutes'] is int ? data['minutes'] as int : 3;
      final rounds = data['history'] as List? ?? [];
      for (final r in rounds.take(200)) {
        final round = Map<String, dynamic>.from(r as Map);
        if (round['id'] is String && round['word'] is String && round['category'] is String && round['date'] is String && DateTime.tryParse(round['date'] as String) != null && round['citizensWin'] is bool && [round['players'], round['imposters'], round['accused']].every((v) => v is List && v.every((x) => x is String))) {
          _history.add(round);
        }
      }
    } catch (_) {
      // Corrupt or unavailable storage must never prevent offline play.
      language = 'en'; theme = 'system'; haptics = true; sounds = false;
      lastPlayers = []; lastCategories = []; _history.clear();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      storageAvailable = await _prefs!.setString('suspecto.v1', jsonEncode({'language': language, 'theme': theme, 'haptics': haptics, 'sounds': sounds, 'players': lastPlayers, 'categories': lastCategories, 'imposters': lastImposters, 'minutes': lastMinutes, 'history': _history}));
    } catch (_) { storageAvailable = false; }
    notifyListeners();
  }

  Future<void> updateSettings({String? language, String? theme, bool? haptics, bool? sounds}) async {
    if (language != null) { this.language = language == 'ar' ? 'ar' : 'en'; }
    if (theme != null) { this.theme = ['system', 'dark', 'light'].contains(theme) ? theme : 'system'; }
    this.haptics = haptics ?? this.haptics;
    this.sounds = sounds ?? this.sounds;
    notifyListeners();
    await _save();
  }

  Future<void> saveSetup(List<String> players, List<String> categories, int imposters, int minutes) async {
    lastPlayers = [...players]; lastCategories = [...categories]; lastImposters = imposters; lastMinutes = minutes;
    await _save();
  }

  Future<void> recordRound({required String id, required String word, required String category, required List<String> players, required List<String> imposters, required List<String> accused, required bool citizensWin}) async {
    if (_history.any((r) => r['id'] == id)) { return; }
    _history.insert(0, {'id': id, 'date': DateTime.now().toUtc().toIso8601String(), 'word': word, 'category': category, 'players': [...players], 'imposters': [...imposters], 'accused': [...accused], 'citizensWin': citizensWin});
    if (_history.length > 200) { _history.removeRange(200, _history.length); }
    await _save();
  }

  Map<String, PlayerStats> get stats {
    final result = <String, PlayerStats>{};
    for (final round in _history) {
      for (final name in List<String>.from(round['players'] as List)) {
        final stats = result.putIfAbsent(name, PlayerStats.new);
        final imposter = (round['imposters'] as List).contains(name);
        stats.played++;
        if (imposter) { stats.imposterRounds++; }
        if (imposter != (round['citizensWin'] as bool)) { stats.wins++; }
      }
    }
    return result;
  }

  Future<void> clearHistory() async { _history.clear(); await _save(); }

  void feedback({bool reveal = false}) {
    if (haptics) { if (reveal) { HapticFeedback.mediumImpact(); } else { HapticFeedback.selectionClick(); } }
    if (sounds) { SystemSound.play(SystemSoundType.click); }
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);
  static AppStore? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()?.notifier;
  static AppStore of(BuildContext context) => maybeOf(context)!;
}
