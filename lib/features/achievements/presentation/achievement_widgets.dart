import 'package:flutter/material.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/achievements/domain/achievements.dart';

/// Celebrates achievements earned in the round [roundId]. Shows nothing when
/// this phone did not save that round (e.g. a guest in a multi-phone game).
class AchievementsUnlockedCard extends StatelessWidget {
  const AchievementsUnlockedCard({super.key, required this.roundId});
  final String roundId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.maybeOf(context);
    if (store == null) {
      return const SizedBox.shrink();
    }
    final unlocked = Achievements.unlockedBy(store.history, roundId);
    if (unlocked.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: theme.colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalText('🏅 Achievements unlocked!',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final MapEntry(key: name, value: earned) in unlocked.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(earned.map((a) => a.emoji).join(),
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(earned
                                .map((a) => translate(context, a.title))
                                .join(' • ')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every achievement for [name], earned ones first.
Future<void> showPlayerAchievements(BuildContext context, String name) {
  final store = StoreScope.of(context);
  final earned = Achievements.tally(store.history)[name]?.unlocked ?? const {};
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final ordered = [
        ...Achievement.values.where(earned.contains),
        ...Achievement.values.where((a) => !earned.contains(a)),
      ];
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Row(
              children: [
                PlayerAvatar(name: name, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(name, style: theme.textTheme.headlineSmall)),
              ],
            ),
            LocalText(
                '${earned.length} of ${Achievement.values.length} achievements'),
            const SizedBox(height: 16),
            for (final achievement in ordered)
              Opacity(
                opacity: earned.contains(achievement) ? 1 : 0.45,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(achievement.emoji,
                      style: const TextStyle(fontSize: 30)),
                  title: LocalText(achievement.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: LocalText(achievement.description),
                  trailing: earned.contains(achievement)
                      ? Icon(Icons.verified, color: theme.colorScheme.primary)
                      : const Icon(Icons.lock_outline),
                ),
              ),
          ],
        ),
      );
    },
  );
}
