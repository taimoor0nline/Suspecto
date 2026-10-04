import 'package:flutter/material.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/game/presentation/setup_screen.dart';

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
              Icon(
                Icons.visibility_rounded,
                size: 88,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'One phone. A room full of suspects.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                '3–20 friends • 1–3 imposters • Fully offline',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const SetupScreen())),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start game'),
      ),
      const SizedBox(height: 24),
      const Text('HOW TO PLAY', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text(
        '1. Each player privately checks their card.\n2. Take turns giving a clue without saying the word.\n3. Discuss, then vote privately for a suspect.\n4. Catch every imposter to win. A tie means a revote.',
      ),
    ],
  );
}
