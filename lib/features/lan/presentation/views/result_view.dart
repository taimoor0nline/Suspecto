import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/presentation/widgets/celebration.dart';
import 'package:suspecto/features/game/presentation/widgets/party_awards_card.dart';
import 'package:suspecto/features/game/presentation/widgets/round_widgets.dart';
import 'package:suspecto/features/game/presentation/widgets/scoreboard.dart';
import 'package:suspecto/features/game/presentation/widgets/share_results.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/presentation/widgets/lan_widgets.dart';

class LanResultView extends StatelessWidget {
  const LanResultView(
      {super.key, required this.session, required this.onLeave});
  final LanSession session;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final view = session.view!;
    final result = view.result!;
    final theme = Theme.of(context);
    final copy = outcomeCopy(
      citizensWin: result.citizensWin,
      stolen: result.stolen,
      jesterWin: result.jesterWin,
    );
    final imposterNames = result.imposterIds.map(view.nameOf).join(', ');
    final standings = [
      for (final p in view.players)
        MapEntry(Player(id: p.id, name: p.name), view.scores[p.id] ?? 0),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return Celebration(
      key: ValueKey('result-${view.round}'),
      tone: copy.tone,
      child: LanPage(
        view: view,
        onLeave: onLeave,
        reconnecting: session.status == LanStatus.reconnecting,
        title: copy.title,
        subtitle: copy.subtitle,
        children: [
          SecretRevealCard(
            icon: copy.icon,
            mode: view.mode,
            secret: result.secret.entry,
            decoy: result.decoy?.entry,
            imposterNames: imposterNames,
            jesterName:
                result.jesterId == null ? null : view.nameOf(result.jesterId!),
          ),
          const SizedBox(height: 20),
          LocalText('The votes', style: theme.textTheme.titleLarge),
          for (final p in view.roundPlayers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              subtitle: LocalText(result.accusedIds.contains(p.id)
                  ? 'Accused by the group'
                  : 'Not accused'),
              trailing: LocalText('${result.votes[p.id] ?? 0} votes'),
            ),
          const SizedBox(height: 20),
          LocalText('Scoreboard', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Scoreboard(standings: standings, roundPoints: result.points),
          if (view.awards.isNotEmpty) ...[
            const SizedBox(height: 20),
            LocalText('Party awards', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            PartyAwardsCard(awards: view.awards, nameOf: view.nameOf),
          ],
          const SizedBox(height: 20),
          if (view.isHost) ...[
            FilledButton(
              onPressed: view.players.where((p) => p.connected).length >= 3
                  ? () => session.send(LanAction.start)
                  : null,
              child: const LocalText('Play again'),
            ),
            TextButton(
              onPressed: () => session.send(LanAction.lobby),
              child: const LocalText('Back to lobby'),
            ),
          ] else
            const WaitingNote('Waiting for the host to start the round.'),
          const SizedBox(height: 8),
          ShareResultsButton(
            summary: (context) => ResultSummary.build(
              context,
              title: copy.title,
              secretLabel: secretLabels(view.mode).$1,
              secret: wordLabel(context, result.secret.entry),
              imposters: 'Imposters: $imposterNames',
              awards: view.awards,
              nameOf: view.nameOf,
              standings: [for (final e in standings) (e.key.name, e.value)],
            ),
          ),
        ],
      ),
    );
  }
}
