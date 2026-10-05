import 'dart:convert';
import 'package:suspecto/core/language_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

class PlayerStats {
  int played = 0;
  int wins = 0;
  int imposterRounds = 0;
  int points = 0;
}

class AppStore extends ChangeNotifier {
  AppStore({LanguageConfig? languageConfig})
      : languageConfig = languageConfig ?? defaultLanguageConfig;
  final LanguageConfig languageConfig;
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
  GameOptions lastOptions = const GameOptions();
  final List<WordPack> _customPacks = [];
  List<WordPack> get customPacks => List.unmodifiable(_customPacks);
  final List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => List.unmodifiable(
      _history.map((r) => Map<String, dynamic>.unmodifiable(r)));
  ThemeMode get themeMode => switch (theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system
      };

  Future<void> load() async {
    String? raw;
    try {
      _prefs = await SharedPreferences.getInstance();
      final value = _prefs!.get('suspecto.v1');
      raw = value is String ? value : null;
    } catch (_) {
      storageAvailable = false;
      notifyListeners();
      return;
    }
    if (raw == null) {
      return;
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    language = languageConfig
        .resolve(data['language'] is String ? data['language'] as String : null)
        .code;
    theme = ['system', 'dark', 'light'].contains(data['theme'])
        ? data['theme'] as String
        : 'system';
    haptics = data['haptics'] != false;
    sounds = data['sounds'] == true;
    List<String> validStrings(dynamic value) =>
        value is List && value.every((x) => x is String && x.trim().isNotEmpty)
            ? List<String>.from(value)
            : [];
    final savedPlayers = validStrings(data['players']);
    lastPlayers = savedPlayers.length >= 3 && savedPlayers.length <= 20
        ? savedPlayers
        : [];
    lastCategories = validStrings(data['categories']);
    lastImposters = data['imposters'] is int ? data['imposters'] as int : 1;
    lastMinutes = data['minutes'] is int ? data['minutes'] as int : 3;
    lastOptions = GameOptions.fromJson(data['options']);
    _customPacks.clear();
    final packs =
        data['customPacks'] is List ? data['customPacks'] as List : [];
    for (final json in packs) {
      final pack = WordPack.fromJson(json);
      if (pack != null &&
          _customPacks.length < WordPack.maxCustomPacks &&
          !_customPacks.any((p) => p.id == pack.id)) {
        _customPacks.add(pack);
      }
    }
    _history.clear();
    final rounds = data['history'] is List ? data['history'] as List : [];
    for (final entry in rounds) {
      if (_history.length == 200) {
        break;
      }
      if (entry is! Map) {
        continue;
      }
      try {
        final round = Map<String, dynamic>.from(entry);
        final players = validStrings(round['players']);
        final imposters = validStrings(round['imposters']);
        final accused = validStrings(round['accused']);
        if (round['id'] is! String ||
            (round['id'] as String).isEmpty ||
            _history.any((r) => r['id'] == round['id']) ||
            round['word'] is! String ||
            (round['word'] as String).trim().isEmpty ||
            round['category'] is! String ||
            (round['category'] as String).trim().isEmpty ||
            round['date'] is! String ||
            DateTime.tryParse(round['date'] as String) == null ||
            round['citizensWin'] is! bool ||
            (round['stolen'] != null && round['stolen'] is! bool)) {
          continue;
        }
        final stolen = round['stolen'] == true;
        if (players.length < 3 ||
            players.length > 20 ||
            players.toSet().length != players.length ||
            imposters.isEmpty ||
            imposters.length > 3 ||
            imposters.length * 2 >= players.length ||
            imposters.toSet().length != imposters.length ||
            accused.length != imposters.length ||
            accused.toSet().length != accused.length ||
            ![...imposters, ...accused].every(players.contains) ||
            (accused.every(imposters.contains) && !stolen) !=
                round['citizensWin']) {
          continue;
        }
        final rawPoints = round['points'] is Map ? round['points'] as Map : {};
        _history.add({
          ...round,
          'players': players,
          'imposters': imposters,
          'accused': accused,
          'stolen': stolen,
          'points': {
            for (final entry in rawPoints.entries)
              if (players.contains(entry.key) &&
                  entry.value is int &&
                  (entry.value as int) >= 0)
                entry.key as String: entry.value as int,
          },
        });
      } catch (_) {/* Skip only the malformed record. */}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      storageAvailable = await _prefs!.setString(
          'suspecto.v1',
          jsonEncode({
            'language': language,
            'theme': theme,
            'haptics': haptics,
            'sounds': sounds,
            'players': lastPlayers,
            'categories': lastCategories,
            'imposters': lastImposters,
            'minutes': lastMinutes,
            'options': lastOptions.toJson(),
            'customPacks': [for (final pack in _customPacks) pack.toJson()],
            'history': _history
          }));
    } catch (_) {
      storageAvailable = false;
    }
    notifyListeners();
  }

  Future<void> updateSettings(
      {String? language, String? theme, bool? haptics, bool? sounds}) async {
    if (language != null) {
      this.language = languageConfig.resolve(language).code;
    }
    if (theme != null) {
      this.theme =
          ['system', 'dark', 'light'].contains(theme) ? theme : 'system';
    }
    this.haptics = haptics ?? this.haptics;
    this.sounds = sounds ?? this.sounds;
    notifyListeners();
    await _save();
  }

  Future<void> saveSetup(
      List<String> players, List<String> categories, int imposters, int minutes,
      {GameOptions? options}) async {
    lastPlayers = [...players];
    lastCategories = [...categories];
    lastImposters = imposters;
    lastMinutes = minutes;
    lastOptions = options ?? lastOptions;
    await _save();
  }

  /// Adds a custom pack, or replaces the one with the same ID.
  Future<void> savePack(WordPack pack) async {
    final index = _customPacks.indexWhere((p) => p.id == pack.id);
    if (index >= 0) {
      _customPacks[index] = pack;
    } else if (_customPacks.length < WordPack.maxCustomPacks) {
      _customPacks.add(pack);
    }
    await _save();
  }

  Future<void> deletePack(String id) async {
    _customPacks.removeWhere((p) => p.id == id);
    lastCategories = lastCategories.where((c) => c != id).toList();
    await _save();
  }

  Future<void> recordRound(
      {required String id,
      required String word,
      required String category,
      required List<String> players,
      required List<String> imposters,
      required List<String> accused,
      required bool citizensWin,
      String mode = 'classic',
      String? decoyWord,
      bool customWord = false,
      bool stolen = false,
      Map<String, int> points = const {}}) async {
    if (_history.any((r) => r['id'] == id)) {
      return;
    }
    _history.insert(0, {
      'id': id,
      'date': DateTime.now().toUtc().toIso8601String(),
      'word': word,
      'category': category,
      'players': [...players],
      'imposters': [...imposters],
      'accused': [...accused],
      'citizensWin': citizensWin,
      'mode': mode,
      if (decoyWord != null) 'decoyWord': decoyWord,
      if (customWord) 'customWord': true,
      'stolen': stolen,
      'points': {...points},
    });
    if (_history.length > 200) {
      _history.removeRange(200, _history.length);
    }
    await _save();
  }

  Map<String, PlayerStats> get stats {
    final result = <String, PlayerStats>{};
    for (final round in _history) {
      for (final name in List<String>.from(round['players'] as List)) {
        final stats = result.putIfAbsent(name, PlayerStats.new);
        final imposter = (round['imposters'] as List).contains(name);
        stats.played++;
        stats.points += ((round['points'] as Map?)?[name] as int?) ?? 0;
        if (imposter) {
          stats.imposterRounds++;
        }
        if (imposter != (round['citizensWin'] as bool)) {
          stats.wins++;
        }
      }
    }
    return result;
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _save();
  }

  void feedback({bool reveal = false}) {
    if (haptics) {
      if (reveal) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (sounds) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);
  static AppStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()?.notifier;
  static AppStore of(BuildContext context) => maybeOf(context)!;
}
