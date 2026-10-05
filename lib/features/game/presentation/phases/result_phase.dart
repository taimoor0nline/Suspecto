import 'package:flutter/material.dart';
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
    return Celebration(
      key: ValueKey(result.id),
      tone: copy.tone,
      child: PhasePage(
        title: copy.title,
        subtitle: copy.subtitle,
        children: [
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
              title: Text(p.name),
              subtitle: LocalText(result.accusedIds.contains(p.id)
                  ? 'Accused by the group'
                  : 'Not accused'),
              trailing: LocalText('${round.ballot.counts[p.id]} votes'),
            ),
          const SizedBox(height: 20),
          LocalText('Scoreboard', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Scoreboard(standings: standings, roundPoints: result.points),
          if (awards.isNotEmpty) ...[
            const SizedBox(height: 20),
            LocalText('Party awards', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            PartyAwardsCard(awards: awards, nameOf: result.nameOf),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: round.playAgain,
            child: const LocalText('Play again'),
          ),
          const SizedBox(height: 8),
          ShareResultsButton(
            summary: (context) => ResultSummary.build(
              context,
              title: copy.title,
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
