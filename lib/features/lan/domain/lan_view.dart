import 'dart:ui';

import 'package:suspecto/features/game/domain/models/drawing_stroke.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/party_awards.dart';

/// Protocol version; phones with a different version cannot play together.
const lanProtocolVersion = 3;

/// Most points kept per line on the wire; longer lines are thinned evenly.
const lanMaxStrokePoints = 80;

enum LanPhase {
  lobby,
  reveal,
  drawing,
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
  const LanCard({
    this.word,
    this.hint,
    this.jester = false,
    this.accompliceOf,
    this.clearedId,
  });

  /// Null for a classic-mode imposter.
  final LanWord? word;

  /// The secret word's pack, shown to classic imposters when hints are on.
  final LanWord? hint;

  /// This player is the Jester and wins alone if voted out.
  final bool jester;

  /// This player is the Accomplice of these imposter IDs.
  final List<String>? accompliceOf;

  /// This player is the Detective and knows this player ID is innocent.
  final String? clearedId;

  Map<String, Object?> toJson() => {
        'word': word?.toJson(),
        'hint': hint?.toJson(),
        'jester': jester,
        'acc': accompliceOf,
        'clr': clearedId,
      };

  static LanCard? fromJson(Object? json) => json is Map
      ? LanCard(
          word: LanWord.fromJson(json['word']),
          hint: LanWord.fromJson(json['hint']),
          jester: json['jester'] == true,
          accompliceOf: json['acc'] is List ? _strings(json['acc']) : null,
          clearedId: json['clr'] is String ? json['clr'] as String : null,
        )
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
    this.jesterId,
    this.jesterWin = false,
    this.accompliceId,
    this.detectiveId,
    this.roundId,
  });

  final LanWord secret;
  final LanWord? decoy;
  final List<String> imposterIds;
  final List<String> accusedIds;
  final Map<String, int> votes;
  final Map<String, int> points;
  final bool citizensWin;
  final bool stolen;
  final String? jesterId;
  final bool jesterWin;
  final String? accompliceId;
  final String? detectiveId;

  /// The host's history ID for this round.
  final String? roundId;

  Map<String, Object?> toJson() => {
        'secret': secret.toJson(),
        'decoy': decoy?.toJson(),
        'imposters': imposterIds,
        'accused': accusedIds,
        'votes': votes,
        'points': points,
        'citizensWin': citizensWin,
        'stolen': stolen,
        'jester': jesterId,
        'jesterWin': jesterWin,
        'accomplice': accompliceId,
        'detective': detectiveId,
        'roundId': roundId,
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
      jesterId: json['jester'] is String ? json['jester'] as String : null,
      jesterWin: json['jesterWin'] == true,
      accompliceId:
          json['accomplice'] is String ? json['accomplice'] as String : null,
      detectiveId:
          json['detective'] is String ? json['detective'] as String : null,
      roundId: json['roundId'] is String ? json['roundId'] as String : null,
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
    this.speedRound = false,
    this.card,
    this.revealedQuestion,
    this.starterId,
    this.remainingSeconds = 0,
    this.myVote,
    this.guessOptions = const [],
    this.guesserIds = const [],
    this.result,
    this.scores = const {},
    this.awards = const [],
    this.matchTarget = 0,
    this.championId,
    this.matchTied = false,
    this.strokes = const [],
    this.drawerId,
    this.drawTurn = 0,
    this.drawTurns = 0,
    this.drawingRound = false,
  });

  final LanPhase phase;
  final String you;
  final bool isHost;
  final List<LanPlayerView> players;
  final int round;
  final GameMode mode;
  final int imposterCount;
  final bool speedRound;
  final LanCard? card;

  /// Question mode: the innocent players' question, once the host reveals it.
  final LanWord? revealedQuestion;
  final String? starterId;
  final int remainingSeconds;
  final String? myVote;
  final List<LanWord> guessOptions;
  final List<String> guesserIds;
  final LanResult? result;

  /// Points per player ID across this game's rounds.
  final Map<String, int> scores;

  /// Session titles, sent with results.
  final List<PartyAward> awards;

  /// Party mode target score, or 0 for endless rounds.
  final int matchTarget;

  /// The match winner, sent with results once someone has won.
  final String? championId;

  /// Players are tied at the top on or above the target.
  final bool matchTied;

  /// Drawing round: the shared sketch so far, whose turn it is, and the
  /// zero-based turn out of [drawTurns].
  final List<DrawingStroke> strokes;
  final String? drawerId;
  final int drawTurn;
  final int drawTurns;

  /// The host turned on drawing rounds (not used in question mode).
  final bool drawingRound;

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

  bool get myTurnToDraw => phase == LanPhase.drawing && drawerId == you;

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'you': you,
        'host': isHost,
        'players': [for (final p in players) p.toJson()],
        'round': round,
        'mode': mode.name,
        'imposters': imposterCount,
        'speed': speedRound,
        'card': card?.toJson(),
        'question': revealedQuestion?.toJson(),
        'starter': starterId,
        'remaining': remainingSeconds,
        'myVote': myVote,
        'options': [for (final w in guessOptions) w.toJson()],
        'guessers': guesserIds,
        'result': result?.toJson(),
        'scores': scores,
        'awards': [
          for (final a in awards)
            {'kind': a.kind.name, 'id': a.playerId, 'n': a.count},
        ],
        'match': matchTarget,
        'champion': championId,
        'matchTied': matchTied,
        'strokes': [for (final s in strokes) encodeStroke(s)],
        'drawer': drawerId,
        'drawTurn': drawTurn,
        'drawTurns': drawTurns,
        'drawing': drawingRound,
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
      speedRound: json['speed'] == true,
      card: LanCard.fromJson(json['card']),
      revealedQuestion: LanWord.fromJson(json['question']),
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
      awards: [
        if (json['awards'] is List)
          for (final a in json['awards'] as List)
            if (a is Map &&
                a['id'] is String &&
                a['n'] is int &&
                AwardKind.values.any((k) => k.name == a['kind']))
              PartyAward(AwardKind.values.byName(a['kind'] as String),
                  a['id'] as String, a['n'] as int),
      ],
      matchTarget: json['match'] is int ? json['match'] as int : 0,
      championId:
          json['champion'] is String ? json['champion'] as String : null,
      matchTied: json['matchTied'] == true,
      strokes: [
        if (json['strokes'] is List)
          for (final s in json['strokes'] as List)
            if (decodeStroke(s) case final stroke?) stroke,
      ],
      drawerId: json['drawer'] is String ? json['drawer'] as String : null,
      drawTurn: json['drawTurn'] is int ? json['drawTurn'] as int : 0,
      drawTurns: json['drawTurns'] is int ? json['drawTurns'] as int : 0,
      drawingRound: json['drawing'] == true,
    );
  }
}

/// Thins [points] evenly to at most [lanMaxStrokePoints], keeping both ends.
List<Offset> thinStroke(List<Offset> points) {
  if (points.length <= lanMaxStrokePoints) {
    return points;
  }
  final step = (points.length - 1) / (lanMaxStrokePoints - 1);
  return [
    for (var i = 0; i < lanMaxStrokePoints; i++) points[(i * step).round()],
  ];
}

/// Points as a flat list of whole thousandths: [x0, y0, x1, y1, …].
List<int> encodePoints(List<Offset> points) => [
      for (final p in thinStroke(points)) ...[
        (p.dx.clamp(0.0, 1.0) * 1000).round(),
        (p.dy.clamp(0.0, 1.0) * 1000).round(),
      ],
    ];

/// Reads [encodePoints] output; null if malformed or empty.
List<Offset>? decodePoints(Object? json) {
  if (json is! List ||
      json.isEmpty ||
      json.length.isOdd ||
      json.length > lanMaxStrokePoints * 2 ||
      json.any((n) => n is! int || n < 0 || n > 1000)) {
    return null;
  }
  return [
    for (var i = 0; i < json.length; i += 2)
      Offset((json[i] as int) / 1000, (json[i + 1] as int) / 1000),
  ];
}

Map<String, Object?> encodeStroke(DrawingStroke stroke) =>
    {'p': stroke.playerId, 'xy': encodePoints(stroke.points)};

DrawingStroke? decodeStroke(Object? json) {
  final points = json is Map ? decodePoints(json['xy']) : null;
  return json is Map && json['p'] is String && points != null
      ? DrawingStroke(playerId: json['p'] as String, points: points)
      : null;
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
