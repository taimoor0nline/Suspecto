import 'package:suspecto/features/game/domain/models/game_session.dart';

/// Points awarded at the end of a round.
class Scoring {
  Scoring._();

  /// Each citizen when the group catches every imposter.
  static const citizensWin = 1;

  /// Each citizen whose final vote named an imposter, win or lose.
  static const sharpVote = 1;

  /// Each imposter when at least one imposter escapes.
  static const imposterEscape = 2;

  /// Each imposter when caught imposters guess the secret word.
  static const imposterSteal = 3;

  /// Points per player ID. Every player gets an entry, including zero.
  static Map<String, int> score({
    required GameSession session,
    required Map<String, String> votes,
    required bool allCaught,
    required bool stolen,
  }) {
    final citizensWon = allCaught && !stolen;
    return Map.unmodifiable({
      for (final player in session.players)
        player.id: session.isImposter(player)
            ? (citizensWon ? 0 : (stolen ? imposterSteal : imposterEscape))
            : (citizensWon ? citizensWin : 0) +
                (session.imposterPlayerIds.contains(votes[player.id])
                    ? sharpVote
                    : 0),
    });
  }
}
