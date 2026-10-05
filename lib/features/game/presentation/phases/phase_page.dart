import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';

/// A non-poppable in-round page. Rounds can only be left via [onEndRound],
/// which asks for confirmation, so a stray back gesture cannot leak roles.
class PhasePage extends StatelessWidget {
  const PhasePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onEndRound,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shows an "End round" button when set.
  final VoidCallback? onEndRound;

  @override
  Widget build(BuildContext context) => GamePage(
        canPop: false,
        title: title,
        subtitle: subtitle,
        children: [
          ...children,
          if (onEndRound != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onEndRound,
              child: const LocalText('End round'),
            ),
          ],
        ],
      );
}
