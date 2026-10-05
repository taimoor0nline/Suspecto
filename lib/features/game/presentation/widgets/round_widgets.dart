import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';
import 'package:suspecto/features/game/presentation/widgets/celebration.dart';
import 'package:suspecto/features/game/presentation/widgets/word_text.dart';

/// Result heading, explanation, icon and celebration tone for an outcome.
({String title, String subtitle, IconData icon, RoundTone tone}) outcomeCopy({
  required bool citizensWin,
  required bool stolen,
  required bool jesterWin,
}) {
  if (jesterWin) {
    return (
      title: 'The Jester fooled everyone!',
      subtitle: 'The group voted out the Jester, who wins this round alone.',
      icon: Icons.celebration,
      tone: RoundTone.jester,
    );
  }
  if (citizensWin) {
    return (
      title: 'Caught in the act!',
      subtitle: 'The group caught every imposter.',
      icon: Icons.emoji_events,
      tone: RoundTone.group,
    );
  }
  if (stolen) {
    return (
      title: 'Stolen at the last second!',
      subtitle: 'The imposters were caught but guessed the secret word.',
      icon: Icons.auto_awesome,
      tone: RoundTone.imposters,
    );
  }
  return (
    title: 'The bluff worked!',
    subtitle: 'At least one imposter escaped. Imposters win this round.',
    icon: Icons.theater_comedy,
    tone: RoundTone.imposters,
  );
}

/// Labels for the secret and the imposters' secret in each mode.
(String, String) secretLabels(GameMode mode) => mode == GameMode.questions
    ? ('THE QUESTION', "THE IMPOSTERS' QUESTION")
    : ('THE SECRET WORD', "THE IMPOSTERS' WORD");

/// The end-of-round reveal: secret, imposters' secret, roles.
class SecretRevealCard extends StatelessWidget {
  const SecretRevealCard({
    super.key,
    required this.icon,
    required this.mode,
    required this.secret,
    required this.imposterNames,
    this.decoy,
    this.jesterName,
  });

  final IconData icon;
  final GameMode mode;
  final WordEntry secret;
  final WordEntry? decoy;
  final String imposterNames;
  final String? jesterName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (secretLabel, decoyLabel) = secretLabels(mode);
    final question = mode == GameMode.questions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            LocalText(secretLabel),
            WordText(secret,
                textAlign: TextAlign.center,
                style: question
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineLarge),
            if (decoy != null) ...[
              const SizedBox(height: 12),
              LocalText(decoyLabel),
              WordText(decoy!,
                  textAlign: TextAlign.center,
                  style: question
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.headlineSmall),
            ],
            const SizedBox(height: 16),
            LocalText('Imposters: $imposterNames', textAlign: TextAlign.center),
            if (jesterName != null)
              LocalText('Jester: $jesterName', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Discussion countdown with the mode explainer above it.
class DiscussionTimerCard extends StatelessWidget {
  const DiscussionTimerCard(
      {super.key, required this.remainingSeconds, required this.mode});
  final int remainingSeconds;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = remainingSeconds;
    final banner = switch (mode) {
      GameMode.undercover => (
          Icons.masks_outlined,
          'Undercover round',
          'Imposters got a different word and may not know they are imposters.'
        ),
      GameMode.questions => (
          Icons.record_voice_over,
          'Question round',
          'Imposters got a different question and may not know they are imposters.'
        ),
      GameMode.classic => null,
    };
    return CountdownSounds(
      remainingSeconds: remaining,
      child: Column(
        children: [
          if (banner != null) ...[
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: ListTile(
                leading: Icon(banner.$1),
                title: LocalText(banner.$2),
                subtitle: LocalText(banner.$3),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 48,
                      color: remaining <= 10 && remaining > 0
                          ? theme.colorScheme.error
                          : null),
                  const SizedBox(height: 16),
                  Text(
                    '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.displayLarge?.copyWith(
                        color: remaining <= 10 && remaining > 0
                            ? theme.colorScheme.error
                            : null),
                  ),
                  LocalText(
                      remaining == 0 ? 'Time to vote!' : 'Discussion time'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Question mode: after everyone has answered, show the innocent players'
/// question so the group can spot answers that don't fit.
class QuestionRevealCard extends StatelessWidget {
  const QuestionRevealCard({super.key, this.question, this.onReveal});

  /// The revealed question, or null while still hidden.
  final WordEntry? question;

  /// Reveals the question; null when another phone (the host) decides.
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = this.question;
    if (question != null) {
      return Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const LocalText('THE QUESTION'),
              const SizedBox(height: 4),
              WordText(question,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const LocalText('Whose answer did not fit?',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const LocalText(
                'Everyone answers out loud first. Then reveal the real question.',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (onReveal != null)
              FilledButton.tonalIcon(
                onPressed: onReveal,
                icon: const Icon(Icons.visibility_outlined),
                label: const LocalText('Reveal the real question'),
              )
            else
              const LocalText('The host will reveal it.',
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
