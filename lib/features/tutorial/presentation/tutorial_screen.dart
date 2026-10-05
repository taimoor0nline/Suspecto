import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';

const _pages = [
  (
    '🕵️',
    'One secret word',
    'Everyone gets the same secret word, except the imposters. They have to fake it.'
  ),
  (
    '🤫',
    'Pass and peek',
    'Pass the phone around. Hold the card to see your role, and let go to hide it.'
  ),
  (
    '💬',
    'Give a clue',
    'Take turns saying one clue about the word. Too obvious helps the imposter; too vague looks suspicious.'
  ),
  (
    '🗳️',
    'Vote them out',
    'Vote privately for whoever seems to be bluffing. Catch every imposter to win, but caught imposters get one guess at the word!'
  ),
  (
    '🎭',
    'Mix it up',
    'Try Undercover and Question modes, add a Jester, or play on everyone\'s phone over Wi-Fi.'
  ),
];

/// A short swipeable guide to the rules. Finishing or skipping it hides the
/// "New here?" card on the home screen.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    StoreScope.maybeOf(context)?.markTutorialSeen();
    Navigator.pop(context);
  }

  void _go(int page) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(page,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _pages.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const LocalText('Quick tutorial'),
        actions: [
          if (!last)
            TextButton(onPressed: _finish, child: const LocalText('Skip')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _page = page),
                    children: [
                      for (final (emoji, title, body) in _pages)
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              Text(emoji, style: const TextStyle(fontSize: 88)),
                              const SizedBox(height: 24),
                              LocalText(title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 16),
                              LocalText(body,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Semantics(
                  label: translate(
                      context, 'Page ${_page + 1} of ${_pages.length}'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_page > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56)),
                            onPressed: () => _go(_page - 1),
                            child: const LocalText('Back'),
                          ),
                        ),
                      if (_page > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: last ? _finish : () => _go(_page + 1),
                          child: LocalText(last ? "Let's play!" : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
