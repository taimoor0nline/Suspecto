import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/setup_screen.dart';
import 'package:suspecto/features/home/presentation/quick_rules_sheet.dart';
import 'package:suspecto/features/home/presentation/widgets/dashboard_widgets.dart';
import 'package:suspecto/features/lan/domain/room_code.dart';
import 'package:suspecto/features/lan/presentation/lan_menu_screen.dart';
import 'package:suspecto/features/lan/presentation/online_menu_screen.dart';
import 'package:suspecto/features/packs/data/word_pack_catalog.dart';
import 'package:suspecto/features/profiles/presentation/profiles_screen.dart';
import 'package:suspecto/features/tutorial/presentation/tutorial_screen.dart';

/// The brand indigo used for the main call to action in both themes.
const brandColor = Color(0xFF5B45F5);

/// Tabs of the home shell that the dashboard can switch to.
enum HomeTab { play, packs, stats, setup }

const _steps = [
  (
    'Check secret word',
    'Private peek',
    'Pass the phone around. Memorize your card in silence.'
  ),
  (
    'Share clues',
    '1-word hint',
    'Give one careful hint that proves you know the word without giving it away.'
  ),
  (
    'Interrogate & vote',
    'Debate',
    'Question suspicious clues, debate, and vote for a suspect.'
  ),
  (
    'Unmask the imposter',
    'Eliminate',
    'Innocent players win if every hidden imposter is caught.'
  ),
];

/// The Play tab: start a game, choose how to play, learn the rules and jump
/// to packs, players, stats and settings.
class PlayDashboard extends StatelessWidget {
  const PlayDashboard({super.key, required this.onSelectTab});
  final ValueChanged<HomeTab> onSelectTab;

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = StoreScope.maybeOf(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(onTutorial: () => _push(context, const TutorialScreen())),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LocalText(
                        'Trust no one.\nSuspect everyone.',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      LocalText(
                        'The secret party game of bluffs and deductions.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      const _HeroCard(),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _push(context, const SetupScreen()),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const LocalText('Start game'),
                      ),
                      const SizedBox(height: 12),
                      _ModeRow(
                        icon: Icons.wifi_tethering,
                        title: 'Play across multiple phones',
                        tag: 'LAN / Wi-Fi',
                        onTap: () => _push(context, const LanMenuScreen()),
                      ),
                      if (onlineRoomsAvailable) ...[
                        const SizedBox(height: 8),
                        _ModeRow(
                          icon: Icons.public,
                          title: 'Play online with friends anywhere',
                          tag: 'Room code',
                          onTap: () => _push(context, const OnlineMenuScreen()),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _HowToPlay(
                        tutorialSeen: store?.tutorialSeen ?? true,
                        onQuickRules: () => showQuickRules(context),
                        onTutorial: () =>
                            _push(context, const TutorialScreen()),
                      ),
                      const SizedBox(height: 24),
                      SectionLabel(
                        'GAME HUB',
                        trailing: TextButton(
                          onPressed: () => _push(context, const SetupScreen()),
                          child: const LocalText('Custom setup'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _GameHub(
                        onSelectTab: onSelectTab,
                        onPlayers: () => _push(context, const ProfilesScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onTutorial});
  final VoidCallback onTutorial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = StoreScope.maybeOf(context);
    final soundsOn = store?.sounds ?? true;
    const green = Color(0xFF34C77B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/branding/suspecto-icon.png',
                width: 30, height: 30, excludeFromSemantics: true),
          ),
          const SizedBox(width: 10),
          Text('SUSPECTO',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TagPill(
                'Offline ready',
                icon: Icons.circle,
                color: green.withValues(alpha: 0.14),
                textColor: green,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: translate(context, 'Sound effects'),
            onPressed: store == null
                ? null
                : () => store.updateSettings(sounds: !soundsOn),
            icon: Icon(
                soundsOn ? Icons.volume_up_rounded : Icons.volume_off_rounded),
          ),
          IconButton.filledTonal(
            tooltip: translate(context, 'Quick tutorial'),
            onPressed: onTutorial,
            icon: const Icon(Icons.menu_book_rounded),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF34C77B);
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/branding/suspecto-icon.png',
                width: 72, height: 72, semanticLabel: 'Suspecto'),
          ),
          const SizedBox(height: 12),
          LocalText('Pass & Play',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          LocalText('One phone. A room full of suspects.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              const TagPill('3–20 players', icon: Icons.group_outlined),
              const TagPill('1–3 imposters',
                  icon: Icons.person_search_outlined),
              TagPill('100% offline',
                  color: green.withValues(alpha: 0.14), textColor: green),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.icon,
    required this.title,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: LocalText(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            TagPill(tag),
          ],
        ),
      );
}

class _HowToPlay extends StatelessWidget {
  const _HowToPlay({
    required this.tutorialSeen,
    required this.onQuickRules,
    required this.onTutorial,
  });

  final bool tutorialSeen;
  final VoidCallback onQuickRules;
  final VoidCallback onTutorial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: LocalText('HOW TO PLAY',
                    style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
              ActionChip(
                label: const LocalText('Quick rules'),
                onPressed: onQuickRules,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final (i, (title, tag, body)) in _steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Panel(
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.surfaceContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${i + 1}',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: LocalText(title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              TagPill(tag),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LocalText(body,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Panel(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalText('Special rule: Undercover mode',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      LocalText(
                          'Imposters get a similar word (like Coffee and Tea) and might not even know they are bluffing!',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTutorial,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline_rounded, size: 20),
                const SizedBox(width: 8),
                const Flexible(child: LocalText('Take the 1-minute tutorial')),
                if (!tutorialSeen) ...[
                  const SizedBox(width: 8),
                  TagPill('New',
                      color: theme.colorScheme.tertiary,
                      textColor: theme.colorScheme.onTertiary),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameHub extends StatelessWidget {
  const _GameHub({required this.onSelectTab, required this.onPlayers});
  final ValueChanged<HomeTab> onSelectTab;
  final VoidCallback onPlayers;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.maybeOf(context);
    final packCount = builtInPacks.length + (store?.customPacks.length ?? 0);
    final playerCount = store?.profiles.length ?? 0;
    final language = store?.languageConfig.resolve(store.language).name;
    final tiles = [
      _HubTile(
        icon: Icons.style_outlined,
        title: 'Word packs',
        subtitle: 'Themes, kids & your own',
        tag: '$packCount available',
        onTap: () => onSelectTab(HomeTab.packs),
      ),
      _HubTile(
        icon: Icons.groups_outlined,
        title: 'Players & rosters',
        subtitle: 'Profiles & avatars',
        tag: '$playerCount saved',
        onTap: onPlayers,
      ),
      _HubTile(
        icon: Icons.emoji_events_outlined,
        title: 'Leaderboard',
        subtitle: 'Points, wins & badges',
        tag: 'Rankings',
        onTap: () => onSelectTab(HomeTab.stats),
      ),
      _HubTile(
        icon: Icons.tune_rounded,
        title: 'Game settings',
        subtitle: 'Language, theme & sounds',
        tag: language ?? 'English',
        translateTag: false,
        onTap: () => onSelectTab(HomeTab.setup),
      ),
    ];
    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[row]),
                const SizedBox(width: 12),
                Expanded(child: tiles[row + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
    this.translateTag = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;
  final bool translateTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: TagPill(tag, translate: translateTag),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LocalText(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          LocalText(subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
