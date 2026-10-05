import 'package:suspecto/features/game/domain/models/round_result.dart';

enum AwardKind {
  /// Most points this session.
  mvp,

  /// Most rounds won as an imposter.
  bluffer,

  /// Most votes cast for real imposters.
  detective,

  /// Most votes received, guilty or not.
  suspect,

  /// Most rounds won as the Jester.
  jester,
}

class PartyAward {
  const PartyAward(this.kind, this.playerId, this.count);
  final AwardKind kind;
  final String playerId;

  /// Points, wins, votes or catches, depending on [kind].
  final int count;
}

/// Fun end-of-session titles. An award is given only when one player clearly
/// leads; ties are skipped so nobody feels picked at random.
class PartyAwards {
  PartyAwards._();

  static List<PartyAward> compute(List<RoundResult> rounds) {
    final tallies = {
      for (final kind in AwardKind.values) kind: <String, int>{}
    };
    void add(AwardKind kind, String id, [int amount = 1]) =>
        tallies[kind]![id] = (tallies[kind]![id] ?? 0) + amount;

    for (final round in rounds) {
      final session = round.session;
      round.points.forEach((id, points) => add(AwardKind.mvp, id, points));
      for (final player in session.players) {
        if (session.isImposter(player) && round.impostersWin) {
          add(AwardKind.bluffer, player.id);
        }
      }
      round.votes.forEach((voter, suspect) {
        add(AwardKind.suspect, suspect);
        if (!session.imposterPlayerIds.contains(voter) &&
            session.imposterPlayerIds.contains(suspect)) {
          add(AwardKind.detective, voter);
        }
      });
      if (round.jesterWin) {
        add(AwardKind.jester, session.jesterId!);
      }
    }

    final awards = <PartyAward>[];
    for (final kind in AwardKind.values) {
      final ranked = tallies[kind]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (ranked.isEmpty || ranked.first.value <= 0) {
        continue;
      }
      if (ranked.length > 1 && ranked[1].value == ranked.first.value) {
        continue;
      }
      awards.add(PartyAward(kind, ranked.first.key, ranked.first.value));
    }
    return awards;
  }
}
