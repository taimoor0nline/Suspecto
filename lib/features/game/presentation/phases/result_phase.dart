import 'package:flutter/material.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';
import 'package:suspecto/features/achievements/presentation/achievement_widgets.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/celebration.dart';
import 'package:suspecto/features/game/presentation/widgets/party_awards_card.dart';
import 'package:suspecto/features/game/presentation/widgets/round_widgets.dart';
import 'package:suspecto/features/game/presentation/widgets/scoreboard.dart';
import 'package:suspecto/features/game/presentation/widgets/share_results.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';

class ResultPhase extends StatelessWidget {
  const ResultPhase({super.key, required this.round, required this.onLeave});
  final RoundController round;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = round.result!;
    final session = result.session;
    final copy = outcomeCopy(
      citizensWin: result.citizensWin,
      stolen: result.stolen,
      jesterWin: result.jesterWin,
    );
    final imposterNames = session.imposters.map((p) => p.name).join(', ');
    final awards = round.awards;
    final standings = round.standings;
    final champion = round.champion;
    return Celebration(
      key: ValueKey(result.id),
      tone: copy.tone,
      child: PhasePage(
        title: copy.title,
        subtitle: copy.subtitle,
        children: [
          if (champion != null) ...[
            MatchWinnerCard(name: champion.name),
            const SizedBox(height: 20),
          ],
          SecretRevealCard(
            icon: copy.icon,
            mode: session.mode,
            secret: session.secretWord,
            decoy: session.decoyWord,
            imposterNames: imposterNames,
            jesterName: session.jester?.name,
          ),
          const SizedBox(height: 20),
          AchievementsUnlockedCard(roundId: result.id),
          LocalText('The votes', style: theme.textTheme.titleLarge),
          for (final p in session.players)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PlayerAvatar(name: p.name, radius: 18),
              title: Text(p.name),
              subtitle: LocalText(result.accusedIds.contains(p.id)
                  ? 'Accused by the group'
                  : 'Not accused'),
              trailing: LocalText(votesText(round.ballot.counts[p.id] ?? 0)),
            ),
          const SizedBox(height: 20),
          LocalText('Scoreboard', style: theme.textTheme.titleLarge),
          if (round.matchTarget > 0) ...[
            const SizedBox(height: 4),
            LocalText(
                round.matchTied
                    ? 'Tied at the top. Keep playing until one player leads.'
                    : 'First to ${round.matchTarget} pts',
                style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Scoreboard(standings: standings, roundPoints: result.points),
          if (awards.isNotEmpty) ...[
            const SizedBox(height: 20),
            LocalText('Party awards', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            PartyAwardsCard(awards: awards, nameOf: result.nameOf),
          ],
          const SizedBox(height: 20),
          if (champion != null)
            FilledButton(
              onPressed: round.newMatch,
              child: const LocalText('New match'),
            )
          else
            FilledButton(
              onPressed: round.playAgain,
              child: LocalText(
                  round.matchTarget > 0 ? 'Next round' : 'Play again'),
            ),
          const SizedBox(height: 8),
          ShareResultsButton(
            summary: (context) => ResultSummary.build(
              context,
              title: champion == null
                  ? copy.title
                  : '${champion.name} wins the match!',
              secretLabel: secretLabels(session.mode).$1,
              secret: wordLabel(context, session.secretWord),
              imposters: 'Imposters: $imposterNames',
              awards: awards,
              nameOf: result.nameOf,
              standings: [for (final e in standings) (e.key.name, e.value)],
            ),
          ),
          TextButton(
            onPressed: onLeave,
            child: const LocalText('Change players & settings'),
          ),
        ],
      ),
    );
  }
}

/// Crowns the party-mode winner above the round's results.
class MatchWinnerCard extends StatelessWidget {
  const MatchWinnerCard({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            LocalText('Match winner',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            PlayerAvatar(name: name, radius: 28),
            const SizedBox(height: 8),
            LocalText('$name wins the match!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}
