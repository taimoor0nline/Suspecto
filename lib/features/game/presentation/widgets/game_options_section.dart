import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';

/// Game mode and optional rules for the setup screen.
class GameOptionsSection extends StatelessWidget {
  const GameOptionsSection(
      {super.key, required this.options, required this.onChanged});
  final GameOptions options;
  final ValueChanged<GameOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classic = options.mode == GameMode.classic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocalText('Game mode', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<GameMode>(
          segments: const [
            ButtonSegment(
                value: GameMode.classic,
                icon: Icon(Icons.theater_comedy_outlined),
                label: LocalText('Classic')),
            ButtonSegment(
                value: GameMode.undercover,
                icon: Icon(Icons.masks_outlined),
                label: LocalText('Undercover')),
          ],
          selected: {options.mode},
          onSelectionChanged: (selection) =>
              onChanged(options.copyWith(mode: selection.first)),
        ),
        const SizedBox(height: 8),
        LocalText(
          classic
              ? 'Imposters know their role and get no word.'
              : 'Imposters secretly get a similar word and may not know they are imposters.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const LocalText('Category hint for imposters'),
          subtitle: LocalText(classic
              ? 'Imposters see which pack the word is from.'
              : 'Classic mode only.'),
          value: classic && options.imposterHint,
          onChanged: classic
              ? (value) => onChanged(options.copyWith(imposterHint: value))
              : null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const LocalText('Last-chance guess'),
          subtitle: const LocalText(
              'Caught imposters can steal the win by guessing the word.'),
          value: options.lastChanceGuess,
          onChanged: (value) =>
              onChanged(options.copyWith(lastChanceGuess: value)),
        ),
      ],
    );
  }
}
