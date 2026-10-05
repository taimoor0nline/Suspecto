/// How secret words are dealt.
enum GameMode {
  /// Imposters know they are imposters and receive no word.
  classic,

  /// Imposters unknowingly receive a different word from the same pack.
  undercover;

  static GameMode parse(Object? value) =>
      values.firstWhere((mode) => mode.name == value, orElse: () => classic);
}

/// Optional rules chosen during setup.
class GameOptions {
  const GameOptions({
    this.mode = GameMode.classic,
    this.imposterHint = false,
    this.lastChanceGuess = true,
  });

  final GameMode mode;

  /// Classic mode only: imposters see the pack name of the secret word.
  final bool imposterHint;

  /// When every imposter is caught, they may steal the win by guessing the word.
  final bool lastChanceGuess;

  GameOptions copyWith(
          {GameMode? mode, bool? imposterHint, bool? lastChanceGuess}) =>
      GameOptions(
        mode: mode ?? this.mode,
        imposterHint: imposterHint ?? this.imposterHint,
        lastChanceGuess: lastChanceGuess ?? this.lastChanceGuess,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'imposterHint': imposterHint,
        'lastChanceGuess': lastChanceGuess,
      };

  factory GameOptions.fromJson(Object? json) {
    if (json is! Map) {
      return const GameOptions();
    }
    return GameOptions(
      mode: GameMode.parse(json['mode']),
      imposterHint: json['imposterHint'] == true,
      lastChanceGuess: json['lastChanceGuess'] != false,
    );
  }
}
