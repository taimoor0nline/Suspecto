import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

/// Protocol version; phones with a different version cannot play together.
const lanProtocolVersion = 1;

enum LanPhase {
  lobby,
  reveal,
  discussion,
  vote,
  tie,
  guess,
  result;

  static LanPhase parse(Object? value) =>
      values.firstWhere((p) => p.name == value, orElse: () => lobby);
}

/// A word as sent over the network. Each phone translates built-in words into
/// its own language, so players can use different languages in one game.
class LanWord {
  const LanWord(this.value, {this.custom = false});
  final String value;
  final bool custom;

  factory LanWord.from(WordEntry entry) =>
      LanWord(entry.value, custom: entry.custom);

  WordEntry get entry =>
      WordEntry(value: value, category: value, custom: custom);

  Map<String, Object?> toJson() => {'v': value, 'c': custom};

  static LanWord? fromJson(Object? json) => json is Map && json['v'] is String
      ? LanWord(json['v'] as String, custom: json['c'] == true)
      : null;
}

class LanPlayerView {
  const LanPlayerView({
    required this.id,
    required this.name,
    this.isHost = false,
    this.connected = true,
    this.inRound = false,
    this.done = false,
  });

  final String id;
  final String name;
  final bool isHost;
  final bool connected;

  /// Dealt into the current round (players who join between rounds wait).
  final bool inRound;

  /// Has finished this phase: seen their card, or cast their vote.
  final bool done;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'host': isHost,
        'on': connected,
        'in': inRound,
        'done': done,
      };

  static LanPlayerView? fromJson(Object? json) =>
      json is Map && json['id'] is String && json['name'] is String
          ? LanPlayerView(
              id: json['id'] as String,
              name: json['name'] as String,
              isHost: json['host'] == true,
              connected: json['on'] != false,
              inRound: json['in'] == true,
              done: json['done'] == true,
            )
          : null;
}

/// What one player may see of their own role.
class LanCard {
  const LanCard({this.word, this.hint});

  /// Null for a classic-mode imposter.
  final LanWord? word;

  /// The secret word's pack, shown to classic imposters when hints are on.
  final LanWord? hint;

  Map<String, Object?> toJson() =>
      {'word': word?.toJson(), 'hint': hint?.toJson()};

  static LanCard? fromJson(Object? json) => json is Map
      ? LanCard(
          word: LanWord.fromJson(json['word']),
          hint: LanWord.fromJson(json['hint']))
      : null;
}

class LanResult {
  const LanResult({
    required this.secret,
    this.decoy,
    required this.imposterIds,
    required this.accusedIds,
    required this.votes,
    required this.points,
    required this.citizensWin,
    required this.stolen,
  });

  final LanWord secret;
  final LanWord? decoy;
  final List<String> imposterIds;
  final List<String> accusedIds;
  final Map<String, int> votes;
  final Map<String, int> points;
  final bool citizensWin;
  final bool stolen;

  Map<String, Object?> toJson() => {
        'secret': secret.toJson(),
        'decoy': decoy?.toJson(),
        'imposters': imposterIds,
        'accused': accusedIds,
        'votes': votes,
        'points': points,
        'citizensWin': citizensWin,
        'stolen': stolen,
      };

  static LanResult? fromJson(Object? json) {
    final secret = json is Map ? LanWord.fromJson(json['secret']) : null;
    if (json is! Map || secret == null) {
      return null;
    }
    return LanResult(
      secret: secret,
      decoy: LanWord.fromJson(json['decoy']),
      imposterIds: _strings(json['imposters']),
      accusedIds: _strings(json['accused']),
      votes: _ints(json['votes']),
      points: _ints(json['points']),
      citizensWin: json['citizensWin'] == true,
      stolen: json['stolen'] == true,
    );
  }
}

/// Everything one phone needs to draw the game, personalised by the host so
/// that no phone ever receives another player's secret role.
class LanView {
  const LanView({
    required this.phase,
    required this.you,
    required this.isHost,
    required this.players,
    required this.round,
    required this.mode,
    required this.imposterCount,
    this.card,
    this.starterId,
    this.remainingSeconds = 0,
    this.myVote,
    this.guessOptions = const [],
    this.guesserIds = const [],
    this.result,
    this.scores = const {},
  });

  final LanPhase phase;
  final String you;
  final bool isHost;
  final List<LanPlayerView> players;
  final int round;
  final GameMode mode;
  final int imposterCount;
  final LanCard? card;
  final String? starterId;
  final int remainingSeconds;
  final String? myVote;
  final List<LanWord> guessOptions;
  final List<String> guesserIds;
  final LanResult? result;

  /// Points per player ID across this game's rounds.
  final Map<String, int> scores;

  LanPlayerView? player(String? id) {
    for (final p in players) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  String nameOf(String id) => player(id)?.name ?? '?';

  LanPlayerView? get me => player(you);

  List<LanPlayerView> get roundPlayers =>
      players.where((p) => p.inRound).toList();

  bool get canGuess => guesserIds.contains(you);

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'you': you,
        'host': isHost,
        'players': [for (final p in players) p.toJson()],
        'round': round,
        'mode': mode.name,
        'imposters': imposterCount,
        'card': card?.toJson(),
        'starter': starterId,
        'remaining': remainingSeconds,
        'myVote': myVote,
        'options': [for (final w in guessOptions) w.toJson()],
        'guessers': guesserIds,
        'result': result?.toJson(),
        'scores': scores,
      };

  static LanView? fromJson(Object? json) {
    if (json is! Map || json['you'] is! String || json['players'] is! List) {
      return null;
    }
    return LanView(
      phase: LanPhase.parse(json['phase']),
      you: json['you'] as String,
      isHost: json['host'] == true,
      players: [
        for (final p in json['players'] as List)
          if (LanPlayerView.fromJson(p) case final player?) player,
      ],
      round: json['round'] is int ? json['round'] as int : 0,
      mode: GameMode.parse(json['mode']),
      imposterCount: json['imposters'] is int ? json['imposters'] as int : 1,
      card: LanCard.fromJson(json['card']),
      starterId: json['starter'] is String ? json['starter'] as String : null,
      remainingSeconds: json['remaining'] is int ? json['remaining'] as int : 0,
      myVote: json['myVote'] is String ? json['myVote'] as String : null,
      guessOptions: [
        if (json['options'] is List)
          for (final w in json['options'] as List)
            if (LanWord.fromJson(w) case final word?) word,
      ],
      guesserIds: _strings(json['guessers']),
      result: LanResult.fromJson(json['result']),
      scores: _ints(json['scores']),
    );
  }
}

List<String> _strings(Object? json) =>
    json is List ? json.whereType<String>().toList() : const [];

Map<String, int> _ints(Object? json) => json is Map
    ? {
        for (final e in json.entries)
          if (e.key is String && e.value is int)
            e.key as String: e.value as int,
      }
    : const {};
