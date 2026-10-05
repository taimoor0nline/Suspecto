/// Badges players earn across games on this device, derived from saved
/// history so they also count rounds played before achievements existed.
enum Achievement {
  firstRound('🎉', 'First round', 'Finish your first round.'),
  regular('🎲', 'Regular', 'Play 10 rounds.'),
  partyAnimal('🥳', 'Party animal', 'Play 50 rounds.'),
  masterOfDisguise('🎭', 'Master of disguise', 'Win 5 rounds as an imposter.'),
  detective('🕵️', 'Detective', 'Win 10 rounds as an innocent player.'),
  thief('💰', 'Thief', 'Steal a win with the last-chance guess.'),
  jestersLaugh('🃏', "Jester's laugh", 'Win a round as the Jester.'),
  deepCover('🥸', 'Deep cover', 'Win as an imposter in Undercover mode.'),
  quizNight('🎤', 'Quiz night', 'Play 5 rounds in Question mode.'),
  fullHouse('🏟️', 'Full house', 'Play a round with 10 or more players.'),
  century('💯', 'Century', 'Score 100 points.');

  const Achievement(this.emoji, this.title, this.description);
  final String emoji;

  /// English; translated by the UI.
  final String title;
  final String description;
}

/// What one player has done, tallied from history.
class PlayerTally {
  int rounds = 0;
  int imposterWins = 0;
  int innocentWins = 0;
  int steals = 0;
  int jesterWins = 0;
  int undercoverImposterWins = 0;
  int questionRounds = 0;
  int bigParties = 0;
  int points = 0;

  Set<Achievement> get unlocked => {
        if (rounds >= 1) Achievement.firstRound,
        if (rounds >= 10) Achievement.regular,
        if (rounds >= 50) Achievement.partyAnimal,
        if (imposterWins >= 5) Achievement.masterOfDisguise,
        if (innocentWins >= 10) Achievement.detective,
        if (steals >= 1) Achievement.thief,
        if (jesterWins >= 1) Achievement.jestersLaugh,
        if (undercoverImposterWins >= 1) Achievement.deepCover,
        if (questionRounds >= 5) Achievement.quizNight,
        if (bigParties >= 1) Achievement.fullHouse,
        if (points >= 100) Achievement.century,
      };
}

class Achievements {
  Achievements._();

  /// Who won a saved round: 'jester', 'citizens' or 'imposters'.
  static String winner(Map<String, dynamic> round) => round['jesterWin'] == true
      ? 'jester'
      : round['citizensWin'] == true
          ? 'citizens'
          : 'imposters';

  /// Tallies per player name from saved rounds (any order).
  static Map<String, PlayerTally> tally(Iterable<Map<String, dynamic>> rounds) {
    final result = <String, PlayerTally>{};
    for (final round in rounds) {
      final players = List<String>.from(round['players'] as List);
      final imposters = List<String>.from(round['imposters'] as List);
      final jester =
          round['jester'] is String ? round['jester'] as String : null;
      final won = winner(round);
      final points = round['points'] is Map ? round['points'] as Map : const {};
      for (final name in players) {
        final t = result.putIfAbsent(name, PlayerTally.new);
        final imposter = imposters.contains(name);
        t.rounds++;
        t.points += points[name] is int ? points[name] as int : 0;
        if (players.length >= 10) {
          t.bigParties++;
        }
        if (round['mode'] == 'questions') {
          t.questionRounds++;
        }
        if (imposter && won == 'imposters') {
          t.imposterWins++;
          if (round['stolen'] == true) {
            t.steals++;
          }
          if (round['mode'] == 'undercover') {
            t.undercoverImposterWins++;
          }
        }
        if (!imposter && name != round['accomplice'] && won == 'citizens') {
          t.innocentWins++;
        }
        if (name == jester && won == 'jester') {
          t.jesterWins++;
        }
      }
    }
    return result;
  }

  /// Achievements each player earned with the round [roundId], in order.
  static Map<String, List<Achievement>> unlockedBy(
      List<Map<String, dynamic>> history, String roundId) {
    if (!history.any((r) => r['id'] == roundId)) {
      return const {};
    }
    final before = tally(history.where((r) => r['id'] != roundId));
    final after = tally(history);
    final result = <String, List<Achievement>>{};
    after.forEach((name, tally) {
      final earned = tally.unlocked
          .difference(before[name]?.unlocked ?? const <Achievement>{});
      if (earned.isNotEmpty) {
        result[name] = Achievement.values.where(earned.contains).toList();
      }
    });
    return result;
  }
}
