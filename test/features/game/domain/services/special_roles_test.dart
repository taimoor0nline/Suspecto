import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/game_session.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/round_result.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/domain/services/scoring.dart';

List<Player> _players(int n) =>
    [for (var i = 0; i < n; i++) Player(id: '$i', name: 'P$i')];

const _words = [WordEntry(value: 'Pizza', category: 'Food')];

void main() {
  test('options round-trip the new roles', () {
    final options = GameOptions.fromJson(
        const GameOptions(detective: true, accomplice: true).toJson());
    expect(options.detective, isTrue);
    expect(options.accomplice, isTrue);
    expect(GameOptions.fromJson(null).detective, isFalse);
  });

  test('roles go to distinct innocents and keep two plain citizens', () {
    for (var seed = 0; seed < 200; seed++) {
      final engine = GameEngine(random: Random(seed));
      for (var n = 3; n <= 12; n++) {
        for (var imposters = 1;
            imposters <= GameEngine.maxImposters(n);
            imposters++) {
          final s = engine.createSession(
            players: _players(n),
            words: _words,
            imposterCount: imposters,
            jester: true,
            accomplice: true,
            detective: true,
          );
          final roles = [s.jesterId, s.accompliceId, s.detectiveId]
              .whereType<String>()
              .toList();
          expect(roles.toSet(), hasLength(roles.length));
          expect(roles.any(s.imposterPlayerIds.contains), isFalse);
          expect(n - imposters - roles.length,
              greaterThanOrEqualTo(GameEngine.minPlainCitizens));
          if (n < GameOptions.detectiveMinPlayers) {
            expect(s.detectiveId, isNull);
          }
          if (n < GameOptions.accompliceMinPlayers) {
            expect(s.accompliceId, isNull);
          }
          if (s.detectiveId != null) {
            expect(s.detectiveClearId, isNot(s.detectiveId));
            expect(s.imposterPlayerIds, isNot(contains(s.detectiveClearId)));
          } else {
            expect(s.detectiveClearId, isNull);
          }
        }
      }
    }
  });

  test('roles are dealt when there is room and only when asked', () {
    final engine = GameEngine(random: Random(3));
    final on = engine.createSession(
        players: _players(8), words: _words, accomplice: true, detective: true);
    expect(on.accompliceId, isNotNull);
    expect(on.detectiveId, isNotNull);
    final off = engine.createSession(players: _players(8), words: _words);
    expect(off.accompliceId, isNull);
    expect(off.detectiveId, isNull);
  });

  GameSession session() => GameSession(
        players: _players(6),
        imposterPlayerIds: {'0'},
        secretWord: _words.first,
        accompliceId: '1',
        detectiveId: '2',
        detectiveClearId: '3',
      );

  test('the Accomplice scores with the imposters', () {
    final s = session();
    final escaped = Scoring.score(
        session: s,
        votes: {'1': '0', '2': '3', '3': '4', '4': '3', '5': '3', '0': '3'},
        accusedIds: ['3'],
        stolen: false);
    expect(escaped['0'], Scoring.imposterEscape);
    expect(escaped['1'], Scoring.imposterEscape,
        reason: 'no sharp-vote point for the Accomplice');
    final caught = Scoring.score(
        session: s,
        votes: {'1': '0', '2': '0', '3': '0', '4': '0', '5': '1', '0': '1'},
        accusedIds: ['0'],
        stolen: false);
    expect(caught['1'], 0);
    expect(caught['2'], Scoring.citizensWin + Scoring.sharpVote);
  });

  test('saved stats count an Accomplice win but not as an imposter round',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    final s = session();
    await store.recordResult(RoundResult(
      id: 'r1',
      session: s,
      accusedIds: const ['3'],
      stolen: false,
      points: Scoring.score(
          session: s, votes: const {}, accusedIds: ['3'], stolen: false),
    ));
    final stats = store.stats['P1']!;
    expect(stats.wins, 1);
    expect(stats.imposterRounds, 0);
    expect(store.history.first['accomplice'], 'P1');
    expect(store.history.first['detective'], 'P2');
    store.dispose();
  });
}
