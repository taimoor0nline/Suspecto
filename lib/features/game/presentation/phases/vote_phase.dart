import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/audio/sound_effects.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';

/// One private ballot per player, confirmed by name before choices appear.
class VotePhase extends StatelessWidget {
  const VotePhase({super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  @override
  Widget build(BuildContext context) {
    final player = round.currentPlayer;
    return PhasePage(
      title: 'Pass to ${player.name}',
      subtitle:
          'Vote ${round.index + 1} of ${round.session.players.length}. Choose your suspect privately.',
      onEndRound: onEndRound,
      children: round.voterReady
          ? [
              for (final candidate
                  in round.session.players.where((p) => p.id != player.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => round.select(candidate.id),
                    icon: Icon(round.selected == candidate.id
                        ? Icons.check_circle
                        : Icons.person_outline),
                    label: Text(candidate.name),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: round.selected == null
                    ? null
                    : () {
                        StoreScope.maybeOf(context)?.feedback(sound: Sfx.vote);
                        round.castVote();
                      },
                child: const LocalText('Submit private vote'),
              ),
            ]
          : [
              const Icon(Icons.how_to_vote_outlined, size: 88),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: round.confirmVoter,
                child: LocalText('I am ${player.name}'),
              ),
            ],
    );
  }
}

class TiePhase extends StatelessWidget {
  const TiePhase({super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  @override
  Widget build(BuildContext context) => PhasePage(
        title: 'Too close to call',
        subtitle:
            'The vote is tied at the cutoff. Discuss again, then everyone votes again. Roles stay secret.',
        onEndRound: onEndRound,
        children: [
          const Icon(Icons.balance, size: 88),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: round.beginVoting,
            child: const LocalText('Vote again'),
          ),
        ],
      );
}
