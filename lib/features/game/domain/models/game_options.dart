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
  });

  /// The Jester needs enough players that being voted out is a real bluff.
  static const jesterMinPlayers = 5;

  final GameMode mode;

  /// Classic mode only: imposters see the pack name of the secret word.
  final bool imposterHint;

  /// When every imposter is caught, they may steal the win by guessing the
  /// word. Not used in question mode.
  final bool lastChanceGuess;

  final WordDifficulty difficulty;

  /// One innocent player secretly wins alone if the group votes them out.
  final bool jester;

  GameOptions copyWith({
    GameMode? mode,
    bool? imposterHint,
    bool? lastChanceGuess,
    WordDifficulty? difficulty,
    bool? jester,
  }) =>
      GameOptions(
        mode: mode ?? this.mode,
        imposterHint: imposterHint ?? this.imposterHint,
        lastChanceGuess: lastChanceGuess ?? this.lastChanceGuess,
        difficulty: difficulty ?? this.difficulty,
        jester: jester ?? this.jester,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'imposterHint': imposterHint,
        'lastChanceGuess': lastChanceGuess,
        'difficulty': difficulty.name,
        'jester': jester,
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
    );
  }
}
