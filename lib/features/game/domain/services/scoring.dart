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

  /// The Jester when the group votes them out. Nobody else wins that round,
  /// though sharp votes still count.
  static const jesterWin = 3;

  /// Points per player ID. Every player gets an entry, including zero.
  static Map<String, int> score({
    required GameSession session,
    required Map<String, String> votes,
    required List<String> accusedIds,
    required bool stolen,
  }) {
    final jesterOut =
        session.jesterId != null && accusedIds.contains(session.jesterId);
    final allCaught = accusedIds.isNotEmpty &&
        accusedIds.every(session.imposterPlayerIds.contains);
    final citizensWon = allCaught && !stolen;
    int pointsFor(String id) {
      final sharp =
          session.imposterPlayerIds.contains(votes[id]) ? sharpVote : 0;
      // The Accomplice scores as an imposter and gets no sharp-vote point.
      if (session.imposterPlayerIds.contains(id) ||
          id == session.accompliceId) {
        return jesterOut || citizensWon
            ? 0
            : (stolen ? imposterSteal : imposterEscape);
      }
      if (id == session.jesterId && jesterOut) {
        return jesterWin + sharp;
      }
      return (citizensWon ? citizensWin : 0) + sharp;
    }

    return Map.unmodifiable({
      for (final player in session.players) player.id: pointsFor(player.id)
    });
  }
}
