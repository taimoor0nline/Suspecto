import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/quick_start.dart';
import 'package:suspecto/features/history/presentation/history_screen.dart';
import 'package:suspecto/features/home/presentation/play_dashboard.dart';
import 'package:suspecto/features/packs/presentation/packs_screen.dart';
import 'package:suspecto/features/settings/presentation/settings_screen.dart';

/// The app's home: a bottom navigation shell around the Play dashboard,
/// Packs, Stats and Setup, with a centre button that quick-starts a game.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab _tab = HomeTab.play;

  void _select(HomeTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) => PopScope(
        // Back from another tab returns to Play before leaving the app.
        canPop: _tab == HomeTab.play,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _select(HomeTab.play);
          }
        },
        child: Scaffold(
          // Only the visible tab is built, so each tab keeps one scroll view.
          body: switch (_tab) {
            HomeTab.play => PlayDashboard(onSelectTab: _select),
            HomeTab.packs => const PacksScreen(),
            HomeTab.stats => const HistoryScreen(),
            HomeTab.setup => const SettingsScreen(),
          },
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            tooltip: translate(context, 'Quick start'),
            shape: const CircleBorder(),
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            elevation: 2,
            onPressed: () => quickStart(context),
            child: const Icon(Icons.shuffle_rounded),
          ),
          bottomNavigationBar: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 6,
              padding: EdgeInsets.zero,
              height: 64,
              child: Row(
                children: [
                  _NavItem(
                      icon: Icons.sports_esports_rounded,
                      label: 'Play',
                      selected: _tab == HomeTab.play,
                      onTap: () => _select(HomeTab.play)),
                  _NavItem(
                      icon: Icons.style_rounded,
                      label: 'Packs',
                      selected: _tab == HomeTab.packs,
                      onTap: () => _select(HomeTab.packs)),
                  const SizedBox(width: 72),
                  _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Stats',
                      selected: _tab == HomeTab.stats,
                      onTap: () => _select(HomeTab.stats)),
                  _NavItem(
                      icon: Icons.settings_rounded,
                      label: 'Setup',
                      selected: _tab == HomeTab.setup,
                      onTap: () => _select(HomeTab.setup)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkResponse(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      selected ? scheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              LocalText(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
