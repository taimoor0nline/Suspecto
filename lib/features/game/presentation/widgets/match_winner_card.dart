import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';

/// Crowns the party-mode winner above the round's results.
class MatchWinnerCard extends StatelessWidget {
  const MatchWinnerCard({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            LocalText('Match winner',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            PlayerAvatar(name: name, radius: 28),
            const SizedBox(height: 8),
            LocalText('$name wins the match!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}
