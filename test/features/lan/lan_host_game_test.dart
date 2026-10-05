import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/domain/services/scoring.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';

const _words = [
  WordEntry(value: 'Pizza', category: 'Food'),
  WordEntry(value: 'Pasta', category: 'Food'),
];

/// A host plus [guests] joined phones.
(LanHostGame, List<String>) _game(GameOptions options,
    {int guests = 2, int seed = 1}) {
  final game = LanHostGame(
    hostName: 'Host',
    engine: GameEngine(random: Random(seed)),
    config: LanGameConfig(
      imposterCount: 1,
      discussionMinutes: 1,
      options: options,
      words: _words,
    ),
  );
  final ids = [LanHostGame.hostId];
  for (var i = 0; i < guests; i++) {
    ids.add(game.join(name: 'G$i', token: 't$i').id!);
  }
  return (game, ids);
}

/// What [id]'s phone receives, after a trip through JSON.
LanView _view(LanHostGame game, String id) =>
    LanView.fromJson(jsonDecode(jsonEncode(game.viewFor(id).toJson())))!;

void _revealAll(LanHostGame game, List<String> ids) {
  for (final id in ids) {
    game.handle(id, LanAction.seen);
  }
}

/// Everyone votes for a citizen, so the imposter escapes.
void _imposterEscapes(LanHostGame game, List<String> ids) {
  game.handle(LanHostGame.hostId, LanAction.startVote);
  final imposter = ids.firstWhere((id) => _view(game, id).card?.word == null);
  final citizens = ids.where((id) => id != imposter).toList();
  for (final id in ids) {
    game.handle(id, LanAction.vote,
        {'suspect': id == citizens[0] ? citizens[1] : citizens[0]});
  }
}

void main() {
  test('party mode crowns a winner and the next start is a new match', () {
    final (game, ids) = _game(const GameOptions(matchTarget: 5));
    var rounds = 0;
    while (_view(game, ids.first).championId == null && rounds < 100) {
      game.handle(LanHostGame.hostId, LanAction.start);
      _revealAll(game, ids);
      _imposterEscapes(game, ids);
      rounds++;
    }
    final view = _view(game, ids[1]);
    expect(view.phase, LanPhase.result);
    expect(view.matchTarget, 5);
    expect(view.scores[view.championId], greaterThanOrEqualTo(5));
    game.handle(LanHostGame.hostId, LanAction.start);
    final next = _view(game, ids[1]);
    expect(next.phase, LanPhase.reveal);
    expect(next.scores.values.every((s) => s == 0), isTrue);
    game.dispose();
  });

  test('each phone sees only its own special role', () {
    final (game, ids) =
        _game(const GameOptions(accomplice: true, detective: true), guests: 7);
    game.handle(LanHostGame.hostId, LanAction.start);
    final views = [for (final id in ids) _view(game, id)];
    final imposters = [
      for (final v in views)
        if (v.card!.word == null) v.you,
    ];
    final accomplices = views.where((v) => v.card!.accompliceOf != null);
    final detectives = views.where((v) => v.card!.clearedId != null);
    expect(accomplices, hasLength(1));
    expect(detectives, hasLength(1));
    expect(accomplices.single.card!.accompliceOf, unorderedEquals(imposters));
    expect(imposters, isNot(contains(detectives.single.card!.clearedId)));
    _revealAll(game, ids);
    _imposterEscapes(game, ids);
    final result = _view(game, ids.first).result!;
    expect(result.accompliceId, accomplices.single.you);
    expect(result.detectiveId, detectives.single.you);
    expect(result.points[result.accompliceId], Scoring.imposterEscape);
    game.dispose();
  });

  test('drawing turns go phone by phone and only the drawer can draw', () {
    final (game, ids) = _game(const GameOptions(drawing: true));
    game.handle(LanHostGame.hostId, LanAction.start);
    _revealAll(game, ids);
    var view = _view(game, ids.first);
    expect(view.phase, LanPhase.drawing);
    expect(view.drawTurns, ids.length * GameOptions.drawingLaps);
    final line = {
      'xy': encodePoints([for (var i = 0; i < 500; i++) Offset(i / 500, .5)]),
    };
    expect((line['xy'] as List).length, lanMaxStrokePoints * 2);
    for (var turn = 0; turn < view.drawTurns; turn++) {
      final drawer = _view(game, ids.first).drawerId!;
      final other = ids.firstWhere((id) => id != drawer);
      game.handle(other, LanAction.draw, line);
      expect(_view(game, ids.first).drawTurn, turn,
          reason: 'only the drawer can draw');
      if (turn == 1) {
        game.handle(LanHostGame.hostId, LanAction.skipDraw);
      } else {
        game.handle(drawer, LanAction.draw, line);
      }
      expect(_view(game, drawer).myTurnToDraw, isFalse);
    }
    view = _view(game, ids[2]);
    expect(view.phase, LanPhase.discussion);
    expect(view.strokes, hasLength(view.drawTurns - 1));
    game.dispose();
  });

  test('malformed lines are ignored', () {
    for (final bad in [
      null,
      <int>[],
      [1, 2, 3],
      [1, 2000],
      ['a', 'b'],
      List.filled(lanMaxStrokePoints * 2 + 2, 1),
    ]) {
      expect(decodePoints(bad), isNull, reason: '$bad');
    }
  });
}
