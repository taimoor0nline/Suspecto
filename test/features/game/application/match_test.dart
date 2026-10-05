import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

const _players = [
  Player(id: 'a', name: 'Ali'),
  Player(id: 'b', name: 'Sara'),
  Player(id: 'c', name: 'Omar'),
];

RoundController _controller(int target) => RoundController(
      players: _players,
      words: const [WordEntry(value: 'Pizza', category: 'Food')],
      imposterCount: 1,
      discussionMinutes: 1,
      options: GameOptions(matchTarget: target, lastChanceGuess: false),
    );

/// Plays one round where every vote lands on a citizen, so the imposter
/// escapes with 2 points.
void _imposterEscapes(RoundController round) {
  for (var i = 0; i < _players.length; i++) {
    round
      ..showCard(true)
      ..showCard(false)
      ..nextCard();
  }
  round.beginVoting();
  final imposter = round.session.imposterPlayerIds.single;
  final citizen = _players.firstWhere((p) => p.id != imposter).id;
  final other =
      _players.firstWhere((p) => p.id != imposter && p.id != citizen).id;
  for (final voter in round.session.players) {
    round
      ..confirmVoter()
      ..select(voter.id == citizen ? other : citizen)
      ..castVote();
  }
  expect(round.phase, RoundPhase.result);
}

void main() {
  test('match target is saved and unknown targets fall back to endless', () {
    expect(
        GameOptions.fromJson(const GameOptions(matchTarget: 10).toJson())
            .matchTarget,
        10);
    expect(GameOptions.fromJson({'matchTarget': 7}).matchTarget, 0);
    expect(GameOptions.fromJson(null).matchTarget, 0);
  });

  test('endless play never crowns a champion', () {
    final round = _controller(0);
    for (var i = 0; i < 4; i++) {
      _imposterEscapes(round);
      expect(round.champion, isNull);
      round.playAgain();
    }
    round.dispose();
  });

  test('first player to the target wins and a new match resets scores', () {
    final round = _controller(5);
    var played = 0;
    while (round.champion == null && played < 200) {
      if (played > 0) {
        round.playAgain();
      }
      _imposterEscapes(round);
      played++;
    }
    final champion = round.champion!;
    final standings = round.standings;
    expect(standings.first.key, champion);
    expect(standings.first.value, greaterThanOrEqualTo(5));
    expect(standings[1].value, lessThan(standings.first.value));

    round.playAgain();
    expect(round.phase, RoundPhase.result, reason: 'the match is over');

    round.newMatch();
    expect(round.phase, RoundPhase.reveal);
    expect(round.roundsPlayed, 0);
    expect(round.history, isEmpty);
    expect(round.standings.every((e) => e.value == 0), isTrue);
    expect(round.champion, isNull);
    round.dispose();
  });
}
