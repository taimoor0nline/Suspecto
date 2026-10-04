import 'package:suspecto/core/localization.dart';
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
            title: const LocalText('SUSPECTO'),
            automaticallyImplyLeading: canPop,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(title),
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                          offset: Offset(0, 12 * (1 - value)), child: child)),
                  child: ListView(
                    key: ValueKey(title),
                    padding: const EdgeInsets.all(24),
                    children: [
                      LocalText(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      LocalText(subtitle,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 28),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
