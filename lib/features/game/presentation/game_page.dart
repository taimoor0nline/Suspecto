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
    this.bottomAction,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool canPop;

  /// A primary button pinned to the bottom of long pages, so the main action
  /// is always reachable without scrolling.
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: canPop,
        child: Scaffold(
          appBar: AppBar(
            title: const LocalText('SUSPECTO'),
            automaticallyImplyLeading: canPop,
          ),
          bottomNavigationBar: bottomAction == null
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Align(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                          child: bottomAction,
                        ),
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            // Top-aligned: a shrink-wrapping scroll view would otherwise be
            // centred vertically on short pages.
            child: Align(
              alignment: Alignment.topCenter,
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
                  // Not a lazy ListView: pages are short, and building every
                  // child keeps forms alive when scrolled out of view (setup
                  // validates its player names from the bottom button).
                  child: SingleChildScrollView(
                    key: ValueKey(title),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ),
      );
}
