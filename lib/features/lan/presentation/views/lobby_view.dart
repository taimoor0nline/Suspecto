import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/application/lan_session.dart';
import 'package:suspecto/features/lan/presentation/widgets/lan_widgets.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({super.key, required this.session, required this.onLeave});
  final LanSession session;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final view = session.view!;
    final theme = Theme.of(context);
    final code = session.invite;
    final connected = view.players.where((p) => p.connected).length;
    return LanPage(
      view: view,
      onLeave: onLeave,
      reconnecting: session.status == LanStatus.reconnecting,
      title: view.isHost ? 'Invite your friends' : "You're in!",
      subtitle: !view.isHost
          ? 'Waiting for the host to start the round.'
          : (code?.online ?? false)
              ? 'Friends anywhere can join with this code.'
              : 'Friends join on the same Wi-Fi or your hotspot. No internet needed.',
      children: [
        if (code != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: code.qrData,
                      size: 200,
                      backgroundColor: Colors.white,
                      semanticsLabel: translate(context, 'Join QR code'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LocalText(code.online ? 'ROOM CODE' : 'JOIN CODE'),
                  SelectableText(
                    code.code,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LocalText(
                    'On other phones: Play on several phones → Join a game.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(switch (view.mode) {
                GameMode.classic => Icons.theater_comedy_outlined,
                GameMode.undercover => Icons.masks_outlined,
                GameMode.questions => Icons.record_voice_over,
              }),
              label: LocalText(switch (view.mode) {
                GameMode.classic => 'Classic',
                GameMode.undercover => 'Undercover',
                GameMode.questions => 'Questions',
              }),
            ),
            Chip(
              avatar: const Icon(Icons.person_search_outlined),
              label: LocalText('Imposters: ${view.imposterCount}'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LocalText('Players ($connected/20)', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        LanPlayerList(
          view: view,
          onKick: view.isHost
              ? (id) => session.send(LanAction.kick, {'id': id})
              : null,
        ),
        const SizedBox(height: 24),
        if (view.isHost) ...[
          FilledButton.icon(
            onPressed:
                connected >= 3 ? () => session.send(LanAction.start) : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const LocalText('Deal secret roles'),
          ),
          if (connected < 3) ...[
            const SizedBox(height: 8),
            const LocalText('You need at least 3 players.',
                textAlign: TextAlign.center),
          ],
        ] else
          const WaitingNote('Waiting for the host to start the round.'),
      ],
    );
  }
}
