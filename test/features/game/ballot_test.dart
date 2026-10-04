import 'package:flutter_test/flutter_test.dart';
import 'package:suspecto/features/game/domain/services/ballot.dart';

void main() {
  test('requires complete valid ballots and rejects self-votes', () {
    final ballot = Ballot(['a', 'b', 'c']);
    expect(() => ballot.vote('a', 'a'), throwsArgumentError);
    expect(() => ballot.vote('x', 'b'), throwsArgumentError);
    ballot.vote('a', 'b');
    expect(() => ballot.vote('a', 'c'), throwsStateError);
    expect(() => ballot.suspects(1), throwsStateError);
    ballot.vote('b', 'c');
    ballot.vote('c', 'b');
    expect(ballot.suspects(1), ['b']);
  });
  test('boundary ties require revoting', () {
    final ballot = Ballot(['a', 'b', 'c']);
    ballot.vote('a', 'b');
    ballot.vote('b', 'c');
    ballot.vote('c', 'a');
    expect(ballot.suspects(1), isNull);
  });
  test('selects multiple suspects and detects a tie at the cutoff', () {
    final ballot = Ballot(['a', 'b', 'c', 'd', 'e', 'f', 'g']);
    for (final id in ['a', 'c', 'd']) {
      ballot.vote(id, 'b');
    }
    for (final id in ['b', 'e']) {
      ballot.vote(id, 'a');
    }
    ballot.vote('f', 'c');
    ballot.vote('g', 'd');
    expect(ballot.suspects(2), ['b', 'a']);
    expect(ballot.suspects(3), isNull);
  });
}
