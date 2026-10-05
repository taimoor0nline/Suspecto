import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/round_widgets.dart';

class DiscussionPhase extends StatefulWidget {
  const DiscussionPhase(
      {super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  @override
  State<DiscussionPhase> createState() => _DiscussionPhaseState();
}

class _DiscussionPhaseState extends State<DiscussionPhase> {
  bool _questionShown = false;

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final session = round.session;
    final questions = session.mode == GameMode.questions;
    final starter = session.startingPlayer.name;
    return PhasePage(
      title: questions ? 'Answer time' : 'Let the bluffing begin',
      subtitle: questions
          ? '$starter answers first. Everyone answers their question out loud, then discuss whose answer did not fit.'
          : '$starter starts. Give one clue each, then discuss who is bluffing. Keep the word secret.',
      onEndRound: widget.onEndRound,
      children: [
        if (questions) ...[
          QuestionRevealCard(
            question: _questionShown ? session.secretWord : null,
            onReveal: () => setState(() => _questionShown = true),
          ),
          const SizedBox(height: 12),
        ],
        DiscussionTimerCard(
            remainingSeconds: round.remainingSeconds, mode: session.mode),
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
