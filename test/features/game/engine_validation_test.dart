import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';

void main() {
  final players = List.generate(7, (i) => Player(id: '$i', name: 'Player $i'));
  const words = [WordEntry(value: 'Pizza', category: 'Food')];
  test('assigns three distinct imposters and snapshots inputs', () {
    final input = [...players];
    final session = GameEngine(random: Random(7))
        .createSession(players: input, words: words, imposterCount: 3);
    input.clear();
    expect(session.players, hasLength(7));
    expect(session.players.where(session.isImposter), hasLength(3));
    expect(() => session.imposterPlayerIds.clear(), throwsUnsupportedError);
  });
  test('rejects duplicate IDs, blank names and invalid counts', () {
    final engine = GameEngine();
    expect(
      () => engine.createSession(
        players: [...players, players.first],
        words: words,
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.createSession(
        players: [
          const Player(id: 'x', name: ' '),
          ...players,
        ],
        words: words,
      ),
      throwsArgumentError,
    );
    for (final count in [0, 4]) {
      expect(
        () => engine.createSession(
          players: players,
          words: words,
          imposterCount: count,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => engine.createSession(
        players: players.take(4).toList(),
        words: words,
        imposterCount: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.createSession(
        players: List.generate(21, (i) => Player(id: '$i', name: 'P$i')),
        words: words,
      ),
      throwsArgumentError,
    );
  });
}
