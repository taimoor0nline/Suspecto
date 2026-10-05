import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/profiles/domain/player_profile.dart';

/// A player's avatar: their profile's emoji on its colour, or a stable
/// default for names without a profile.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.name, this.radius = 20});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final look = StoreScope.maybeOf(context)?.lookOf(name) ??
        PlayerProfile.defaultFor(name, id: '');
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Color(look.color).withValues(alpha: 0.22),
        child: Text(look.avatar, style: TextStyle(fontSize: radius * 1.05)),
      ),
    );
  }
}
