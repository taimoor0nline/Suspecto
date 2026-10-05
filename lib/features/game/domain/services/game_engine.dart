import 'dart:math';

import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

class GameEngine {
  GameEngine({Random? random}) : _random = random ?? Random.secure();
  final Random _random;

  static int maxImposters(int playerCount) => min(3, (playerCount - 1) ~/ 2);

  /// Deals roles. In undercover mode imposters get a different word, preferably
  /// from the same pack; with only one distinct word the round falls back to
  /// classic rules.
  GameSession createSession({
    required List<Player> players,
    required List<WordEntry> words,
    int imposterCount = 1,
    GameMode mode = GameMode.classic,
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
    final secret = words[_random.nextInt(words.length)];
    WordEntry? decoy;
    if (mode == GameMode.undercover) {
      final others = _distinctFrom(secret, words);
      final sameCategory =
          others.where((w) => w.category == secret.category).toList();
      final pool = sameCategory.isNotEmpty ? sameCategory : others;
      if (pool.isNotEmpty) {
        decoy = pool[_random.nextInt(pool.length)];
      }
    }
    return GameSession(
      players: players,
      imposterPlayerIds: shuffled.take(imposterCount).map((p) => p.id).toSet(),
      secretWord: secret,
      decoyWord: decoy,
      startingPlayerId: players[_random.nextInt(players.length)].id,
    );
  }

  /// Multiple-choice options for the imposters' last-chance guess: the secret
  /// word plus look-alikes, favouring the same pack. Returns an empty list
  /// when there are not enough distinct words for a meaningful guess.
  List<WordEntry> guessOptions(
    GameSession session,
    List<WordEntry> words, {
    int count = 6,
  }) {
    final secret = session.secretWord;
    final others = _distinctFrom(secret, words)..shuffle(_random);
    others.sort((a, b) => (a.category == secret.category ? 0 : 1)
        .compareTo(b.category == secret.category ? 0 : 1));
    final options = [secret, ...others.take(count - 1)]..shuffle(_random);
    return options.length < 2 ? const [] : List.unmodifiable(options);
  }

  static List<WordEntry> _distinctFrom(
      WordEntry secret, List<WordEntry> words) {
    final seen = {_key(secret)};
    return [
      for (final word in words)
        if (seen.add(_key(word))) word,
    ];
  }

  static String _key(WordEntry word) => word.value.trim().toLowerCase();

  static bool sameWord(WordEntry a, WordEntry b) => _key(a) == _key(b);
}
