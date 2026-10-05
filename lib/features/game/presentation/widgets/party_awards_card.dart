import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/services/party_awards.dart';

/// Emoji, English title and English detail text for an award. The detail
/// uses message templates so it translates with the count filled in.
(String, String, String) awardLabel(PartyAward award) => switch (award.kind) {
      AwardKind.mvp => ('🏆', 'MVP', '${award.count} pts'),
      AwardKind.bluffer => (
          '🎭',
          'Best Bluffer',
          '${award.count} imposter wins'
        ),
      AwardKind.detective => (
          '🔍',
          'Sharpest Detective',
          '${award.count} imposters spotted'
        ),
      AwardKind.suspect => (
          '😬',
          'Most Suspected',
          '${award.count} votes received'
        ),
      AwardKind.jester => ('🃏', 'Chaos Jester', '${award.count} Jester wins'),
    };

/// Session titles shown under the results.
class PartyAwardsCard extends StatelessWidget {
  const PartyAwardsCard(
      {super.key, required this.awards, required this.nameOf});

  final List<PartyAward> awards;
  final String Function(String playerId) nameOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final award in awards)
              Builder(builder: (context) {
                final (emoji, title, detail) = awardLabel(award);
                return ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 28)),
                  title: LocalText(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: LocalText(detail),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(nameOf(award.playerId),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
