import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';

/// Party mode setting: endless rounds or first to a target score.
class MatchLengthPicker extends StatelessWidget {
  const MatchLengthPicker(
      {super.key, required this.options, required this.onChanged});
  final GameOptions options;
  final ValueChanged<GameOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocalText('Match length', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final target in GameOptions.matchTargets)
              ChoiceChip(
                avatar: Icon(
                    target == 0
                        ? Icons.all_inclusive
                        : Icons.emoji_events_outlined,
                    size: 18),
                label:
                    LocalText(target == 0 ? 'Endless' : 'First to $target pts'),
                selected: options.matchTarget == target,
                onSelected: (_) =>
                    onChanged(options.copyWith(matchTarget: target)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LocalText(
            options.matchTarget == 0
                ? 'Play as many rounds as you like.'
                : 'Play rounds until one player reaches the target score.',
            style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
