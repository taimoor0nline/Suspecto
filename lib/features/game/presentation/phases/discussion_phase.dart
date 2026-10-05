import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';

class DiscussionPhase extends StatelessWidget {
  const DiscussionPhase(
      {super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = round.remainingSeconds;
    return PhasePage(
      title: 'Let the bluffing begin',
      subtitle:
          '${round.session.startingPlayer.name} starts. Give one clue each, then discuss who is bluffing. Keep the word secret.',
      onEndRound: onEndRound,
      children: [
        if (round.session.mode == GameMode.undercover) ...[
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: const ListTile(
              leading: Icon(Icons.masks_outlined),
              title: LocalText('Undercover round'),
              subtitle: LocalText(
                  'Imposters got a different word and may not know they are imposters.'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.timer_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  style: theme.textTheme.displayLarge,
                ),
                LocalText(remaining == 0 ? 'Time to vote!' : 'Discussion time'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: round.beginVoting,
          child: const LocalText('Start private voting'),
        ),
        TextButton.icon(
          onPressed: () => round.addDiscussionTime(const Duration(minutes: 1)),
          icon: const Icon(Icons.more_time),
          label: const LocalText('Add 1 minute'),
        ),
      ],
    );
  }
}
