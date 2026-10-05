import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/lan/presentation/host_setup_screen.dart';
import 'package:suspecto/features/lan/presentation/join_screen.dart';

/// Entry point for online rooms: friends on any network, joined by room code.
/// Shown only in builds configured with a room server.
class OnlineMenuScreen extends StatelessWidget {
  const OnlineMenuScreen({super.key});

  @override
  Widget build(BuildContext context) => GamePage(
        title: 'Play online',
        subtitle:
            'Friends anywhere join with a room code. Everyone needs internet.',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (icon, text) in const [
                    (Icons.public, 'One phone hosts an online room.'),
                    (
                      Icons.password_rounded,
                      'Share the 6-character room code or QR code with your friends.'
                    ),
                    (
                      Icons.devices_rounded,
                      'Everyone joins from their own phone, on any network.'
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(icon),
                          const SizedBox(width: 12),
                          Expanded(child: LocalText(text)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const HostSetupScreen(online: true))),
            icon: const Icon(Icons.public),
            label: const LocalText('Host an online game'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const JoinScreen(online: true))),
            icon: const Icon(Icons.login_rounded),
            label: const LocalText('Join an online game'),
          ),
        ],
      );
}
