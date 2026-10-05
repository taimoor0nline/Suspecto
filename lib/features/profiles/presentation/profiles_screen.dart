import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/achievements/domain/achievements.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/profiles/domain/player_profile.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';

/// Remembered players with their avatars, stats and badge counts.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profiles = store.profiles;
    final stats = store.stats;
    final badges = Achievements.tally(store.history);
    final full = profiles.length >= PlayerProfile.maxProfiles;
    return GamePage(
      title: 'Players',
      subtitle:
          'Saved players keep their avatar, stats and achievements. New names are saved when a game starts.',
      children: [
        if (profiles.isEmpty) ...[
          const Icon(Icons.groups_outlined, size: 80),
          const SizedBox(height: 16),
          const LocalText('No saved players yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ] else
          for (final profile in profiles)
            Card(
              child: ListTile(
                leading: PlayerAvatar(name: profile.name),
                title: Text(profile.name),
                subtitle: LocalText(
                    'Rounds: ${stats[profile.name]?.played ?? 0} • Points: ${stats[profile.name]?.points ?? 0} • Badges: ${badges[profile.name]?.unlocked.length ?? 0}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => editProfile(context, profile),
              ),
            ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: full ? null : () => editProfile(context, null),
          icon: const Icon(Icons.person_add_alt_1),
          label: const LocalText('Add player'),
        ),
      ],
    );
  }
}

/// Opens the editor for [profile], or for a new player when null.
Future<void> editProfile(BuildContext context, PlayerProfile? profile) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ProfileEditorScreen(profile: profile)));

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, this.profile});
  final PlayerProfile? profile;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final _name = TextEditingController(text: widget.profile?.name);
  late String _avatar = widget.profile?.avatar ?? PlayerProfile.avatars.first;
  late int _color = widget.profile?.color ?? PlayerProfile.colors.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = StoreScope.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    if (store.nameInUse(name, exceptProfileId: widget.profile?.id)) {
      setState(() => _error =
          'That name already has a profile or stats. Choose another name.');
      return;
    }
    final renaming = widget.profile != null && widget.profile!.name != name;
    if (renaming) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const LocalText('Rename this player?'),
          content: const LocalText(
              'Their rounds, stats and achievements will move to the new name.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const LocalText('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const LocalText('Rename')),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    final profile = (widget.profile ?? PlayerProfile.defaultFor(name))
        .copyWith(name: name, avatar: _avatar, color: _color);
    await store.saveProfile(profile);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final store = StoreScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalText('Remove this player?'),
        content: const LocalText(
            'Their past rounds stay in history. You can add them again anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const LocalText('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const LocalText('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await store.deleteProfile(widget.profile!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GamePage(
      title: widget.profile == null ? 'New player' : 'Edit player',
      subtitle: 'Pick a name, an avatar and a colour.',
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Color(_color).withValues(alpha: 0.22),
            child: Text(_avatar, style: const TextStyle(fontSize: 46)),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          maxLength: 24,
          decoration: InputDecoration(
            labelText: translate(context, 'Name'),
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          LocalText(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 20),
        LocalText('Avatar', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final avatar in PlayerProfile.avatars)
              Semantics(
                selected: avatar == _avatar,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _avatar = avatar),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 3,
                        color: avatar == _avatar
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(avatar, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        LocalText('Colour', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in PlayerProfile.colors)
              Semantics(
                selected: color == _color,
                button: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 3,
                        color: color == _color
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const LocalText('Save player'),
        ),
        if (widget.profile != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.person_remove_outlined),
            label: const LocalText('Remove player'),
          ),
        ],
      ],
    );
  }
}
