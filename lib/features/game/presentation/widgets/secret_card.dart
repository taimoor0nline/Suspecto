import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';

/// A hold-to-reveal role card. It shows the role only while [visible]; the
/// parent decides visibility from [onHold] and hides it when the app is
/// backgrounded.
class SecretCard extends StatelessWidget {
  const SecretCard({
    super.key,
    required this.visible,
    required this.onHold,
    this.word,
    this.hint,
  });

  final bool visible;
  final ValueChanged<bool> onHold;

  /// The word on this card; null means "You are the imposter".
  final WordEntry? word;

  /// Pack hint for classic imposters, shown under the role.
  final WordEntry? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = this.word;
    return Listener(
      onPointerDown: (_) => onHold(true),
      onPointerUp: (_) => onHold(false),
      onPointerCancel: (_) => onHold(false),
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
                    Icon(word == null ? Icons.theater_comedy : Icons.visibility,
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
                    if (word == null && hint != null) ...[
                      const SizedBox(height: 16),
                      const LocalText('Hint: the word is from this pack',
                          textAlign: TextAlign.center),
                      Text(
                        categoryLabel(context, hint!),
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
    );
  }
}
