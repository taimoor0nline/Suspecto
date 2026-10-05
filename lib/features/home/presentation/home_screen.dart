import 'package:suspecto/features/settings/presentation/settings_screen.dart';
import 'package:suspecto/features/history/presentation/history_screen.dart';
import 'package:suspecto/core/localization.dart';
import 'package:flutter/material.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/game/presentation/setup_screen.dart';
import 'package:suspecto/features/packs/presentation/packs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => GamePage(
        title: 'Trust no one.\nSuspect everyone.',
        subtitle: 'The secret word is out. Someone is bluffing.',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/branding/suspecto-icon.png',
                        width: 104, height: 104, semanticLabel: 'Suspecto'),
                  ),
                  const SizedBox(height: 20),
                  LocalText(
                    'One phone. A room full of suspects.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const LocalText(
                    '3–20 friends • 1–3 imposters • Fully offline',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SetupScreen())),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const LocalText('Start game'),
          ),
          const SizedBox(height: 24),
          const LocalText('HOW TO PLAY',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const LocalText(
            '1. Each player privately checks their card.\n2. Take turns giving a clue without saying the word.\n3. Discuss, then vote privately for a suspect.\n4. Catch every imposter to win. A tie means a revote.',
          ),
          const SizedBox(height: 12),
          const LocalText(
            'Try Undercover mode, where imposters get a similar word, and win points across rounds.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PacksScreen())),
              icon: const Icon(Icons.library_books_outlined),
              label: const LocalText('Word packs')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const HistoryScreen())),
              icon: const Icon(Icons.history_rounded),
              label: const LocalText('History & stats')),
          const SizedBox(height: 8),
          TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen())),
              icon: const Icon(Icons.tune_rounded),
              label: const LocalText('Settings')),
        ],
      );
}
