import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/lan/data/lan_transport.dart';
import 'package:suspecto/features/lan/presentation/host_setup_screen.dart';
import 'package:suspecto/features/lan/presentation/join_screen.dart';

/// Entry point for playing with one phone per player.
class LanMenuScreen extends StatelessWidget {
  const LanMenuScreen({super.key});

  @override
  Widget build(BuildContext context) => GamePage(
        title: 'Play on several phones',
        subtitle:
            'Everyone sees their card and votes on their own phone. No internet needed.',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (icon, text) in const [
                    (
                      Icons.wifi,
                      'Connect every phone to the same Wi-Fi, or to the host phone\'s hotspot.'
                    ),
                    (
                      Icons.wifi_tethering,
                      'One phone hosts and shows a QR code.'
                    ),
                    (
                      Icons.qr_code_scanner,
                      'Everyone else scans it or types the join code.'
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
          if (!lanSupported)
            const LocalText(
                'Multi-phone games are not available in the web version.',
                textAlign: TextAlign.center)
          else ...[
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const HostSetupScreen())),
              icon: const Icon(Icons.wifi_tethering),
              label: const LocalText('Host a game'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const JoinScreen())),
              icon: const Icon(Icons.login_rounded),
              label: const LocalText('Join a game'),
            ),
          ],
          const SizedBox(height: 16),
          const LocalText(
            'Tip: some public or office Wi-Fi blocks phones from seeing each other. Use a phone hotspot instead.',
            textAlign: TextAlign.center,
          ),
        ],
      );
}
