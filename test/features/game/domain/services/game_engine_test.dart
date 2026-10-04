import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';

void main() {
  group('GameEngine', () {
    test('creates a session with one imposter and one secret word', () {
      final engine = GameEngine(random: Random(1));
      final players = [
        const Player(id: '1', name: 'Ali'),
        const Player(id: '2', name: 'Sara'),
        const Player(id: '3', name: 'Omar'),
      ];
      final words = [
        const WordEntry(value: 'Pizza', category: 'Food'),
      ];

      final session = engine.createSession(
        players: players,
        words: words,
      );

      expect(session.players, hasLength(3));
      expect(
        session.players.where(session.isImposter),
        hasLength(1),
      );
      expect(session.secretWord.value, 'Pizza');
    });

    test('requires at least three players', () {
      final engine = GameEngine();

      expect(
        () => engine.createSession(
          players: const [
            Player(id: '1', name: 'Ali'),
            Player(id: '2', name: 'Sara'),
          ],
          words: const [
            WordEntry(value: 'Pizza', category: 'Food'),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
