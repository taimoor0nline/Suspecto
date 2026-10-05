import 'dart:convert';
import 'package:suspecto/core/language_config.dart';
import 'package:suspecto/features/achievements/domain/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suspecto/core/audio/sound_effects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/round_result.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';
import 'package:suspecto/features/profiles/domain/player_profile.dart';

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
  bool sounds = true;
  final SoundEffects _sfx = SoundEffects();
  bool storageAvailable = true;
  List<String> lastPlayers = [];
  List<String> lastCategories = [];
  int lastImposters = 1;
  int lastMinutes = 3;
  GameOptions lastOptions = const GameOptions();

  /// The name this phone last used in a multi-phone game.
  String lanName = '';

  /// The quick tutorial was finished or dismissed on this device.
  bool tutorialSeen = false;
  final List<WordPack> _customPacks = [];
  final List<PlayerProfile> _profiles = [];

  /// Remembered players, alphabetical.
  List<PlayerProfile> get profiles => List.unmodifiable([..._profiles]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
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
    sounds = data['sounds'] != false;
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
    tutorialSeen = data['tutorialSeen'] == true;
    lanName =
        data['lanName'] is String && (data['lanName'] as String).length <= 24
            ? data['lanName'] as String
            : '';
    _profiles.clear();
    final savedProfiles =
        data['profiles'] is List ? data['profiles'] as List : [];
    for (final json in savedProfiles) {
      final profile = PlayerProfile.fromJson(json);
      if (profile != null &&
          _profiles.length < PlayerProfile.maxProfiles &&
          profileFor(profile.name) == null &&
          !_profiles.any((p) => p.id == profile.id)) {
        _profiles.add(profile);
      }
    }
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
            'lanName': lanName,
            'tutorialSeen': tutorialSeen,
            'customPacks': [for (final pack in _customPacks) pack.toJson()],
            'profiles': [for (final profile in _profiles) profile.toJson()],
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

  Future<void> markTutorialSeen() async {
    if (tutorialSeen) {
      return;
    }
    tutorialSeen = true;
    await _save();
  }

  Future<void> saveLanName(String name) async {
    lanName = name.trim();
    await _save();
  }

  /// The profile whose name matches [name], ignoring case.
  PlayerProfile? profileFor(String name) {
    final key = name.trim().toLowerCase();
    for (final profile in _profiles) {
      if (profile.name.toLowerCase() == key) {
        return profile;
      }
    }
    return null;
  }

  /// Avatar and colour for [name]: its profile, or a stable default.
  PlayerProfile lookOf(String name) =>
      profileFor(name) ?? PlayerProfile.defaultFor(name, id: '');

  /// Remembers any of [names] that have no profile yet.
  Future<void> rememberPlayers(Iterable<String> names) async {
    var changed = false;
    for (final name in names.map((n) => n.trim())) {
      if (name.isEmpty ||
          profileFor(name) != null ||
          _profiles.length >= PlayerProfile.maxProfiles) {
        continue;
      }
      _profiles.add(PlayerProfile.defaultFor(name));
      changed = true;
    }
    if (changed) {
      await _save();
    }
  }

  /// Whether giving [name] to a profile would clash with another person:
  /// another profile has it, or (when renaming profile [exceptProfileId]) the
  /// name already has rounds in history. A new profile may claim a name from
  /// history; that is how existing stats get an avatar.
  bool nameInUse(String name, {String? exceptProfileId}) {
    final key = name.trim().toLowerCase();
    final other = profileFor(name);
    if (other != null && other.id != exceptProfileId) {
      return true;
    }
    final own = _profiles.where((p) => p.id == exceptProfileId).firstOrNull;
    if (own == null || own.name.toLowerCase() == key) {
      return false;
    }
    return _history.any((round) => (round['players'] as List)
        .any((n) => (n as String).toLowerCase() == key));
  }

  /// Adds or updates [profile]. Renaming also renames the player throughout
  /// history, so their stats and achievements move with them.
  Future<void> saveProfile(PlayerProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    final previous = index >= 0 ? _profiles[index] : null;
    if (index >= 0) {
      _profiles[index] = profile;
    } else if (_profiles.length < PlayerProfile.maxProfiles) {
      _profiles.add(profile);
    }
    if (previous != null && previous.name != profile.name) {
      _renameInHistory(previous.name, profile.name);
      lastPlayers = [
        for (final n in lastPlayers) n == previous.name ? profile.name : n,
      ];
    }
    await _save();
  }

  /// Forgets a profile. Their rounds stay in history under the same name.
  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _save();
  }

  void _renameInHistory(String from, String to) {
    String swap(Object? name) => name == from ? to : name as String;
    for (final round in _history) {
      for (final key in ['players', 'imposters', 'accused']) {
        round[key] = [for (final n in round[key] as List) swap(n)];
      }
      for (final key in ['jester', 'accomplice', 'detective']) {
        if (round[key] == from) {
          round[key] = to;
        }
      }
      if (round['points'] is Map) {
        round['points'] = {
          for (final e in (round['points'] as Map).entries)
            swap(e.key): e.value,
        };
      }
    }
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
      String? jester,
      bool jesterWin = false,
      String? accomplice,
      String? detective,
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
      if (jester != null) 'jester': jester,
      if (jesterWin) 'jesterWin': true,
      if (accomplice != null) 'accomplice': accomplice,
      if (detective != null) 'detective': detective,
      'points': {...points},
    });
    if (_history.length > 200) {
      _history.removeRange(200, _history.length);
    }
    await _save();
  }

  /// Saves a finished round from either pass-and-play or a multi-phone game.
  Future<void> recordResult(RoundResult result) {
    final session = result.session;
    return recordRound(
      id: result.id,
      word: session.secretWord.value,
      category: session.secretWord.category,
      players: session.players.map((p) => p.name).toList(),
      imposters: session.imposters.map((p) => p.name).toList(),
      accused: result.accusedIds.map(result.nameOf).toList(),
      citizensWin: result.citizensWin,
      mode: result.mode.name,
      decoyWord: session.decoyWord?.value,
      customWord: session.secretWord.custom,
      stolen: result.stolen,
      jester: session.jester?.name,
      jesterWin: result.jesterWin,
      accomplice: session.accomplice?.name,
      detective: session.detective?.name,
      points: {
        for (final entry in result.points.entries)
          result.nameOf(entry.key): entry.value,
      },
    );
  }

  Map<String, PlayerStats> get stats {
    final result = <String, PlayerStats>{};
    for (final round in _history) {
      for (final name in List<String>.from(round['players'] as List)) {
        final stats = result.putIfAbsent(name, PlayerStats.new);
        final imposter = (round['imposters'] as List).contains(name);
        // The Accomplice wins and loses with the imposters.
        final imposterTeam = imposter || round['accomplice'] == name;
        stats.played++;
        stats.points += ((round['points'] as Map?)?[name] as int?) ?? 0;
        if (imposter) {
          stats.imposterRounds++;
        }
        final winner = Achievements.winner(round);
        if (imposterTeam
            ? winner == 'imposters'
            : winner == 'citizens' ||
                (winner == 'jester' && round['jester'] == name)) {
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

  void feedback({bool reveal = false, Sfx? sound}) {
    if (haptics) {
      if (reveal) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    playSound(sound ?? (reveal ? Sfx.reveal : Sfx.tap));
  }

  /// Plays a sound effect when sounds are on.
  void playSound(Sfx sfx) {
    if (sounds) {
      _sfx.play(sfx);
    }
  }

  /// A stronger buzz for big moments such as time running out.
  void alert() {
    if (haptics) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);
  static AppStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()?.notifier;
  static AppStore of(BuildContext context) => maybeOf(context)!;
}
