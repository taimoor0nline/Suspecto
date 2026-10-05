import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';

/// The page frame for every multi-phone screen. Back navigation is disabled;
/// leaving goes through [onLeave], which confirms first.
class LanPage extends StatelessWidget {
  const LanPage({
    super.key,
    required this.view,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onLeave,
    this.reconnecting = false,
  });

  final LanView view;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onLeave;
  final bool reconnecting;

  @override
  Widget build(BuildContext context) => GamePage(
        canPop: false,
        title: title,
        subtitle: subtitle,
        children: [
          if (reconnecting) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const ListTile(
                leading: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3)),
                title: LocalText('Reconnecting…'),
                subtitle: LocalText('Stay on the same Wi-Fi or hotspot.'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
          const SizedBox(height: 20),
          TextButton(
            onPressed: onLeave,
            child:
                LocalText(view.isHost ? 'End game for everyone' : 'Leave game'),
          ),
        ],
      );
}

/// Who is in the game, with connection and progress state.
class LanPlayerList extends StatelessWidget {
  const LanPlayerList({
    super.key,
    required this.view,
    this.players,
    this.showProgress = false,
    this.onKick,
  });

  final LanView view;
  final List<LanPlayerView>? players;

  /// Marks players who have finished the current step.
  final bool showProgress;
  final ValueChanged<String>? onKick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          for (final p in players ?? view.players)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                child: Icon(
                  p.isHost ? Icons.wifi_tethering : Icons.smartphone,
                  size: 18,
                ),
              ),
              title: Text(
                p.id == view.you ? '${p.name} •' : p.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: p.connected ? null : theme.disabledColor,
                ),
              ),
              subtitle: !p.connected
                  ? const LocalText('Disconnected')
                  : p.isHost
                      ? const LocalText('Host')
                      : null,
              trailing: showProgress
                  ? Icon(
                      p.done ? Icons.check_circle : Icons.hourglass_empty,
                      color: p.done ? theme.colorScheme.primary : null,
                    )
                  : onKick != null && !p.isHost
                      ? IconButton(
                          tooltip: translate(context, 'Remove'),
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => onKick!(p.id),
                        )
                      : null,
            ),
        ],
      ),
    );
  }
}

/// A short "waiting" message with a spinner.
class WaitingNote extends StatelessWidget {
  const WaitingNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Flexible(child: LocalText(text, textAlign: TextAlign.center)),
          ],
        ),
      );
}
