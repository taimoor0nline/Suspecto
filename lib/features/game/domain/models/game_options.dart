import 'package:suspecto/features/game/domain/models/word_entry.dart';

/// How secret words are dealt.
enum GameMode {
  /// Imposters know they are imposters and receive no word.
  classic,

  /// Imposters unknowingly receive a different word from the same pack.
  undercover,

  /// Everyone answers a question aloud; imposters unknowingly get a
  /// different question.
  questions;

  static GameMode parse(Object? value) =>
      values.firstWhere((mode) => mode.name == value, orElse: () => classic);

  /// Imposters receive something (a word or question) and may not know
  /// their role.
  bool get hiddenImposters => this != classic;
}

/// Which built-in words to deal. Custom words match every level.
enum WordDifficulty {
  mixed,
  easy,
  medium,
  hard;

  static WordDifficulty parse(Object? value) =>
      values.firstWhere((d) => d.name == value, orElse: () => mixed);

  bool matches(WordEntry word) =>
      this == mixed || word.custom || word.difficulty == index;

  List<WordEntry> filter(List<WordEntry> words) =>
      words.where(matches).toList();
}

/// Optional rules chosen during setup.
class GameOptions {
  const GameOptions({
    this.mode = GameMode.classic,
    this.imposterHint = false,
    this.lastChanceGuess = true,
    this.difficulty = WordDifficulty.mixed,
    this.jester = false,
    this.speedRound = false,
    this.matchTarget = 0,
    this.detective = false,
    this.accomplice = false,
  });

  /// Discussion length for speed rounds.
  static const speedRoundSeconds = 30;

  /// Match lengths offered in setup, in points. 0 plays endless rounds.
  static const matchTargets = [0, 5, 10, 15];

  /// The Jester needs enough players that being voted out is a real bluff.
  static const jesterMinPlayers = 5;

  /// The Detective needs at least one other innocent player to clear.
  static const detectiveMinPlayers = 4;

  /// The Accomplice needs enough citizens left to catch the imposters.
  static const accompliceMinPlayers = 6;

  final GameMode mode;

  /// Classic mode only: imposters see the pack name of the secret word.
  final bool imposterHint;

  /// When every imposter is caught, they may steal the win by guessing the
  /// word. Not used in question mode.
  final bool lastChanceGuess;

  final WordDifficulty difficulty;

  /// One innocent player secretly wins alone if the group votes them out.
  final bool jester;

  /// A 30-second discussion with one-word clues.
  final bool speedRound;

  /// Party mode: the first player to this many session points wins the
  /// match. 0 plays endless rounds.
  final int matchTarget;

  /// One innocent player secretly learns that another player is innocent.
  final bool detective;

  /// One innocent player knows the imposters and wins with them.
  final bool accomplice;

  /// Discussion length in seconds for the chosen [minutes].
  int discussionSeconds(int minutes) =>
      speedRound ? speedRoundSeconds : minutes * 60;

  GameOptions copyWith({
    GameMode? mode,
    bool? imposterHint,
    bool? lastChanceGuess,
    WordDifficulty? difficulty,
    bool? jester,
    bool? speedRound,
    int? matchTarget,
    bool? detective,
    bool? accomplice,
  }) =>
      GameOptions(
        mode: mode ?? this.mode,
        imposterHint: imposterHint ?? this.imposterHint,
        lastChanceGuess: lastChanceGuess ?? this.lastChanceGuess,
        difficulty: difficulty ?? this.difficulty,
        jester: jester ?? this.jester,
        speedRound: speedRound ?? this.speedRound,
        matchTarget: matchTarget ?? this.matchTarget,
        detective: detective ?? this.detective,
        accomplice: accomplice ?? this.accomplice,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'imposterHint': imposterHint,
        'lastChanceGuess': lastChanceGuess,
        'difficulty': difficulty.name,
        'jester': jester,
        'speedRound': speedRound,
        'matchTarget': matchTarget,
        'detective': detective,
        'accomplice': accomplice,
      };

  factory GameOptions.fromJson(Object? json) {
    if (json is! Map) {
      return const GameOptions();
    }
    return GameOptions(
      mode: GameMode.parse(json['mode']),
      imposterHint: json['imposterHint'] == true,
      lastChanceGuess: json['lastChanceGuess'] != false,
      difficulty: WordDifficulty.parse(json['difficulty']),
      jester: json['jester'] == true,
      speedRound: json['speedRound'] == true,
      matchTarget: matchTargets.contains(json['matchTarget'])
          ? json['matchTarget'] as int
          : 0,
      detective: json['detective'] == true,
      accomplice: json['accomplice'] == true,
    );
  }
}
