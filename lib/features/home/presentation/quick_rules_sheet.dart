import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';

/// A one-screen summary of modes, roles and scoring.
Future<void> showQuickRules(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        Widget heading(String text) => Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: LocalText(text,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            );
        Widget rule(IconData icon, String title, String body) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: LocalText(title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: LocalText(body),
            );
        Widget points(String event, String value) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: LocalText(event)),
                  const SizedBox(width: 12),
                  Text(value,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary)),
                ],
              ),
            );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              LocalText('Quick rules',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              heading('Game mode'),
              rule(Icons.theater_comedy_outlined, 'Classic',
                  'Imposters know their role and get no word.'),
              rule(Icons.masks_outlined, 'Undercover',
                  'Imposters secretly get a similar word and may not know they are imposters.'),
              rule(Icons.record_voice_over, 'Questions',
                  'Everyone answers a question out loud. Imposters secretly get a different question.'),
              heading('Optional rules'),
              rule(Icons.psychology_alt_outlined, 'Last-chance guess',
                  'Caught imposters can steal the win by guessing the word.'),
              rule(Icons.celebration_outlined, 'Jester role',
                  'One innocent player wins alone if the group votes them out. Needs 5+ players.'),
              rule(Icons.search, 'Detective role',
                  'One innocent player secretly learns that another player is innocent. Needs 4+ players.'),
              rule(Icons.handshake_outlined, 'Accomplice role',
                  'One player gets the real word, knows the imposters and wins with them. Needs 6+ players.'),
              rule(Icons.bolt, 'Speed round',
                  '30-second discussion with one-word clues.'),
              heading('Scoring'),
              points('Innocent players catch every imposter', '+1'),
              points('Your vote named an imposter', '+1'),
              points('An imposter escapes', '+2'),
              points('Caught imposters guess the word', '+3'),
              points('The Jester is voted out', '+3'),
            ],
          ),
        );
      },
    );
