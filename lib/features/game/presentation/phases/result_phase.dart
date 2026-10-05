import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/scoreboard.dart';
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
    final (title, subtitle, icon) = result.citizensWin
        ? (
            'Caught in the act!',
            'The group caught every imposter.',
            Icons.emoji_events
          )
        : result.stolen
            ? (
                'Stolen at the last second!',
                'The imposters were caught but guessed the secret word.',
                Icons.auto_awesome
              )
            : (
                'The bluff worked!',
                'At least one imposter escaped. Imposters win this round.',
                Icons.theater_comedy
              );
    return PhasePage(
      title: title,
      subtitle: subtitle,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                const LocalText('THE SECRET WORD'),
                WordText(session.secretWord,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge),
                if (session.decoyWord != null) ...[
                  const SizedBox(height: 12),
                  const LocalText("THE IMPOSTERS' WORD"),
                  WordText(session.decoyWord!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall),
                ],
                const SizedBox(height: 16),
                LocalText(
                  'Imposters: ${session.imposters.map((p) => p.name).join(', ')}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
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
        Scoreboard(standings: round.standings, roundPoints: result.points),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: round.playAgain,
          child: const LocalText('Play again'),
        ),
        TextButton(
          onPressed: onLeave,
          child: const LocalText('Change players & settings'),
        ),
      ],
    );
  }
}
