import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/application/round_controller.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/presentation/phases/phase_page.dart';
import 'package:suspecto/features/game/presentation/widgets/secret_card.dart';

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
    final player = round.currentPlayer;
    final session = round.session;
    final word = session.wordFor(player);
    return PhasePage(
      title: 'Pass to ${player.name}',
      subtitle:
          'Card ${round.index + 1} of ${session.players.length}. Everyone else, look away.',
      onEndRound: onEndRound,
      children: [
        SecretCard(
          visible: round.cardVisible,
          onHold: (show) => _show(context, show),
          word: word,
          hint: word == null && round.options.imposterHint
              ? session.secretWord
              : null,
          question: session.mode == GameMode.questions,
          jester: session.isJester(player),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: round.cardViewed && !round.cardVisible
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
