import 'dart:math';

import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameEngine {
  GameEngine({Random? random}) : _random = random ?? Random.secure();
  final Random _random;

  static int maxImposters(int playerCount) => min(3, (playerCount - 1) ~/ 2);

  GameSession createSession({
    required List<Player> players,
    required List<WordEntry> words,
    int imposterCount = 1,
  }) {
    if (players.length < 3 || players.length > 20) {
      throw ArgumentError('Use 3–20 players.');
    }
    if (players.any((p) => p.id.trim().isEmpty || p.name.trim().isEmpty) ||
        players.map((p) => p.id).toSet().length != players.length) {
      throw ArgumentError('Each player needs a unique ID and a name.');
    }
    if (imposterCount < 1 || imposterCount > maxImposters(players.length)) {
      throw ArgumentError(
        'Imposters must be fewer than half the players, up to 3.',
      );
    }
    if (words.isEmpty) {
      throw ArgumentError('Choose at least one category.');
    }
    final shuffled = [...players]..shuffle(_random);
    return GameSession(
      players: players,
      imposterPlayerIds: shuffled.take(imposterCount).map((p) => p.id).toSet(),
      secretWord: words[_random.nextInt(words.length)],
    );
  }
}
