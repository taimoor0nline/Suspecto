import 'package:flutter/material.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';
import 'package:suspecto/features/achievements/presentation/achievement_widgets.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/presentation/widgets/celebration.dart';
import 'package:suspecto/features/game/presentation/widgets/drawing_canvas.dart';
import 'package:suspecto/features/game/presentation/widgets/match_winner_card.dart';
import 'package:suspecto/features/game/presentation/widgets/party_awards_card.dart';
import 'package:suspecto/features/game/presentation/widgets/round_widgets.dart';
import 'package:suspecto/features/game/presentation/widgets/scoreboard.dart';
import 'package:suspecto/features/game/presentation/widgets/share_results.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/presentation/views/round_views.dart';
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
    final champion =
        view.championId == null ? null : view.nameOf(view.championId!);
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
          if (champion != null) ...[
            MatchWinnerCard(name: champion),
            const SizedBox(height: 20),
          ],
          SecretRevealCard(
            icon: copy.icon,
            mode: view.mode,
            secret: result.secret.entry,
            decoy: result.decoy?.entry,
            imposterNames: imposterNames,
            jesterName:
                result.jesterId == null ? null : view.nameOf(result.jesterId!),
            accompliceName: result.accompliceId == null
                ? null
                : view.nameOf(result.accompliceId!),
            detectiveName: result.detectiveId == null
                ? null
                : view.nameOf(result.detectiveId!),
          ),
          if (view.strokes.isNotEmpty) ...[
            const SizedBox(height: 20),
            LocalText('The drawing', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            DrawingCanvas(players: lanPlayers(view), strokes: view.strokes),
          ],
          const SizedBox(height: 20),
          if (result.roundId != null)
            AchievementsUnlockedCard(roundId: result.roundId!),
          LocalText('The votes', style: theme.textTheme.titleLarge),
          for (final p in view.roundPlayers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PlayerAvatar(name: p.name, radius: 18),
              title: Text(p.name),
              subtitle: LocalText(result.accusedIds.contains(p.id)
                  ? 'Accused by the group'
                  : 'Not accused'),
              trailing: LocalText(votesText(result.votes[p.id] ?? 0)),
            ),
          const SizedBox(height: 20),
          LocalText('Scoreboard', style: theme.textTheme.titleLarge),
          if (view.matchTarget > 0) ...[
            const SizedBox(height: 4),
            LocalText(
                view.matchTied
                    ? 'Tied at the top. Keep playing until one player leads.'
                    : 'First to ${view.matchTarget} pts',
                style: theme.textTheme.bodyMedium),
          ],
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
              child: LocalText(champion != null
                  ? 'New match'
                  : view.matchTarget > 0
                      ? 'Next round'
                      : 'Play again'),
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
              title:
                  champion == null ? copy.title : '$champion wins the match!',
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
