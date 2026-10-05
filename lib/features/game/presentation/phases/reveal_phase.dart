import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';

/// Pass-the-phone private role cards. The card shows only while held.
class RevealPhase extends StatelessWidget {
  const RevealPhase({super.key, required this.round, required this.onEndRound});
  final RoundController round;
  final VoidCallback onEndRound;

  void _show(BuildContext context, bool show) {
    if (show && !round.cardVisible) {
      StoreScope.maybeOf(context)?.feedback(reveal: true);
    }
    round.showCard(show);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = round.currentPlayer;
    final session = round.session;
    final visible = round.cardVisible;
    final word = session.wordFor(player);
    return PhasePage(
      title: 'Pass to ${player.name}',
      subtitle:
          'Card ${round.index + 1} of ${session.players.length}. Everyone else, look away.',
      onEndRound: onEndRound,
      children: [
        Listener(
          onPointerDown: (_) => _show(context, true),
          onPointerUp: (_) => _show(context, false),
          onPointerCancel: (_) => _show(context, false),
          child: Semantics(
            label: translate(context, 'Hold to reveal your secret card'),
            child: AnimatedContainer(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 260),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: visible
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: visible
                    ? [
                        Icon(
                            word == null
                                ? Icons.theater_comedy
                                : Icons.visibility,
                            size: 60),
                        const SizedBox(height: 20),
                        if (word == null)
                          LocalText('You are the imposter',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium)
                        else
                          WordText(word,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        LocalText(
                          word == null
                              ? 'Blend in. Listen to the clues. Bluff your way through.'
                              : 'Remember the word. Give a clue, but do not say it.',
                          textAlign: TextAlign.center,
                        ),
                        if (word == null && round.options.imposterHint) ...[
                          const SizedBox(height: 16),
                          const LocalText('Hint: the word is from this pack',
                              textAlign: TextAlign.center),
                          Text(
                            categoryLabel(context, session.secretWord),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ]
                    : [
                        const Icon(Icons.fingerprint, size: 60),
                        const SizedBox(height: 20),
                        LocalText('Hold to reveal',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        const LocalText('Release to hide your card.',
                            textAlign: TextAlign.center),
                      ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: round.cardViewed && !visible
              ? () {
                  StoreScope.maybeOf(context)?.feedback();
                  round.nextCard();
                }
              : null,
          child: LocalText(
              round.isLastPlayer ? 'Start discussion' : 'Hide & pass'),
        ),
      ],
    );
  }
}
