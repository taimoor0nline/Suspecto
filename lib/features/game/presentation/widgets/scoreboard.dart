import 'package:flutter/material.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/player.dart';

/// Session standings with this round's points next to each player.
class Scoreboard extends StatelessWidget {
  const Scoreboard({
    super.key,
    required this.standings,
    required this.roundPoints,
  });

  final List<MapEntry<Player, int>> standings;
  final Map<String, int> roundPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = standings.isEmpty ? 0 : standings.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final (rank, entry) in standings.indexed)
              ListTile(
                dense: true,
                leading: PlayerAvatar(name: entry.key.name, radius: 18),
                title: Text(
                    '${entry.value == best && best > 0 ? '👑 ' : '${rank + 1}. '}${entry.key.name}',
                    style: theme.textTheme.titleMedium),
                subtitle: (roundPoints[entry.key.id] ?? 0) > 0
                    ? LocalText('+${roundPoints[entry.key.id]} this round',
                        style: TextStyle(color: theme.colorScheme.primary))
                    : null,
                trailing: LocalText('${entry.value} pts',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
