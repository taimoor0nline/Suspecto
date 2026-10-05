import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/presentation/widgets/scoreboard.dart';
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
    final standings = [
      for (final p in view.players)
        MapEntry(Player(id: p.id, name: p.name), view.scores[p.id] ?? 0),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return LanPage(
      view: view,
      onLeave: onLeave,
      reconnecting: session.status == LanStatus.reconnecting,
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
                WordText(result.secret.entry,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge),
                if (result.decoy != null) ...[
                  const SizedBox(height: 12),
                  const LocalText("THE IMPOSTERS' WORD"),
                  WordText(result.decoy!.entry,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall),
                ],
                const SizedBox(height: 16),
                LocalText(
                  'Imposters: ${result.imposterIds.map(view.nameOf).join(', ')}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
      ],
    );
  }
}
