import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';

/// Game mode, difficulty and optional rules for the setup screens.
class GameOptionsSection extends StatelessWidget {
  const GameOptionsSection(
      {super.key, required this.options, required this.onChanged});
  final GameOptions options;
  final ValueChanged<GameOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = options.mode;
    final classic = mode == GameMode.classic;
    final questions = mode == GameMode.questions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocalText('Game mode', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, icon, label) in const [
              (GameMode.classic, Icons.theater_comedy_outlined, 'Classic'),
              (GameMode.undercover, Icons.masks_outlined, 'Undercover'),
              (GameMode.questions, Icons.record_voice_over, 'Questions'),
            ])
              ChoiceChip(
                avatar: Icon(icon, size: 18),
                label: LocalText(label),
                selected: mode == value,
                onSelected: (_) => onChanged(options.copyWith(mode: value)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LocalText(
          switch (mode) {
            GameMode.classic => 'Imposters know their role and get no word.',
            GameMode.undercover =>
              'Imposters secretly get a similar word and may not know they are imposters.',
            GameMode.questions =>
              'Everyone answers a question out loud. Imposters secretly get a different question.',
          },
          style: theme.textTheme.bodyMedium,
        ),
        if (!questions) ...[
          const SizedBox(height: 16),
          LocalText('Word difficulty', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (value, label) in const [
                (WordDifficulty.mixed, 'Mixed'),
                (WordDifficulty.easy, 'Easy'),
                (WordDifficulty.medium, 'Medium'),
                (WordDifficulty.hard, 'Hard'),
              ])
                ChoiceChip(
                  label: LocalText(label),
                  selected: options.difficulty == value,
                  onSelected: (_) =>
                      onChanged(options.copyWith(difficulty: value)),
                ),
            ],
          ),
        ],
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
          subtitle: LocalText(questions
              ? 'Not used in question mode.'
              : 'Caught imposters can steal the win by guessing the word.'),
          value: !questions && options.lastChanceGuess,
          onChanged: questions
              ? null
              : (value) => onChanged(options.copyWith(lastChanceGuess: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Text('🃏', style: TextStyle(fontSize: 24)),
          title: const LocalText('Jester role'),
          subtitle: const LocalText(
              'One innocent player wins alone if the group votes them out. Needs 5+ players.'),
          value: options.jester,
          onChanged: (value) => onChanged(options.copyWith(jester: value)),
        ),
      ],
    );
  }
}
