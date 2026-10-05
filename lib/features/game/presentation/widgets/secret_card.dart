import 'dart:math';

import 'package:flutter/material.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';

/// A hold-to-reveal role card. It shows the role only while [visible]; the
/// parent decides visibility from [onHold] and hides it when the app is
/// backgrounded. Revealing flips the card in; hiding is instant so the role
/// never lingers on screen.
class SecretCard extends StatelessWidget {
  const SecretCard({
    super.key,
    required this.visible,
    required this.onHold,
    this.word,
    this.hint,
    this.question = false,
    this.jester = false,
    this.ownerName,
  });

  final bool visible;
  final ValueChanged<bool> onHold;

  /// The word or question on this card; null means "You are the imposter".
  final WordEntry? word;

  /// Pack hint for classic imposters, shown under the role.
  final WordEntry? hint;

  /// [word] is a question to answer aloud rather than a word to clue.
  final bool question;

  /// This player is the Jester.
  final bool jester;

  /// Shows this player's avatar on the hidden card so they know it is theirs.
  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Listener(
      onPointerDown: (_) => onHold(true),
      onPointerUp: (_) => onHold(false),
      onPointerCancel: (_) => onHold(false),
      child: Semantics(
        label: translate(context, 'Hold to reveal your secret card'),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(visible),
          tween: Tween(begin: visible && !reduceMotion ? pi / 2 : 0, end: 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, angle, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: child,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 260),
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: visible
                  ? (jester
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.primaryContainer)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: visible ? _front(theme) : _back(theme),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _back(ThemeData theme) => [
        if (ownerName == null)
          const Icon(Icons.fingerprint, size: 60)
        else
          PlayerAvatar(name: ownerName!, radius: 30),
        const SizedBox(height: 20),
        LocalText('Hold to reveal',
            textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        const LocalText('Release to hide your card.',
            textAlign: TextAlign.center),
      ];

  List<Widget> _front(ThemeData theme) {
    final word = this.word;
    return [
      if (jester) ...[
        const Text('🃏', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 8),
        LocalText('You are the Jester',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const LocalText(
            "Get the group to vote you out to win alone, but don't make it obvious!",
            textAlign: TextAlign.center),
        const Divider(height: 32),
      ] else ...[
        Icon(
            word == null
                ? Icons.theater_comedy
                : (question ? Icons.record_voice_over : Icons.visibility),
            size: 60),
        const SizedBox(height: 20),
      ],
      if (word == null)
        LocalText('You are the imposter',
            textAlign: TextAlign.center, style: theme.textTheme.headlineMedium)
      else ...[
        if (question) const LocalText('YOUR QUESTION'),
        WordText(word,
            textAlign: TextAlign.center,
            style: question
                ? theme.textTheme.headlineSmall
                : theme.textTheme.headlineMedium),
      ],
      const SizedBox(height: 12),
      LocalText(
        word == null
            ? 'Blend in. Listen to the clues. Bluff your way through.'
            : question
                ? 'Answer out loud when it is your turn. Never read the question aloud.'
                : 'Remember the word. Give a clue, but do not say it.',
        textAlign: TextAlign.center,
      ),
      if (word == null && hint != null) ...[
        const SizedBox(height: 16),
        const LocalText('Hint: the word is from this pack',
            textAlign: TextAlign.center),
        Builder(
          builder: (context) => Text(
            categoryLabel(context, hint!),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ];
  }
}
