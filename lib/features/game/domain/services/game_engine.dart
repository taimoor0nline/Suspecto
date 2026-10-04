import 'dart:math';

import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameEngine {
  GameEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  GameSession createSession({
    required List<Player> players,
    required List<WordEntry> words,
  }) {
    if (players.length < 3) {
      throw ArgumentError('At least 3 players are required.');
    }

    if (words.isEmpty) {
      throw ArgumentError('At least one word is required.');
    }

    final imposter = players[_random.nextInt(players.length)];
    final secretWord = words[_random.nextInt(words.length)];

    return GameSession(
      players: List.unmodifiable(players),
      imposterPlayerId: imposter.id,
      secretWord: secretWord,
    );
  }
}
