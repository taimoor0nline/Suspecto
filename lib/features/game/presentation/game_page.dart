import 'package:flutter/material.dart';

/// A shared scrolling layout that supports short screens and larger text.
class GamePage extends StatelessWidget {
  const GamePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.canPop = true,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool canPop;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: canPop,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('SUSPECTO'),
        automaticallyImplyLeading: canPop,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              key: ValueKey(title),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
