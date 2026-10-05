import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';

/// Caught imposters pick the secret word from a shortlist to steal the win.
class GuessPhase extends StatefulWidget {
  const GuessPhase({super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  @override
  State<GuessPhase> createState() => _GuessPhaseState();
}

class _GuessPhaseState extends State<GuessPhase> {
  WordEntry? _guess;

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final names = round.session.imposters.map((p) => p.name).join(', ');
    return PhasePage(
      title: 'Last chance!',
      subtitle: 'Caught: $names. Guess the secret word to steal the win.',
      onEndRound: widget.onEndRound,
      children: [
        const Icon(Icons.psychology_alt_outlined, size: 72),
        const SizedBox(height: 16),
        for (final option in round.guessOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _guess = option),
              icon: Icon(identical(_guess, option)
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked),
              label: WordText(option),
            ),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _guess == null
              ? null
              : () {
                  StoreScope.maybeOf(context)?.feedback(reveal: true);
                  round.submitGuess(_guess!);
                },
          child: const LocalText('Lock in guess'),
        ),
      ],
    );
  }
}
