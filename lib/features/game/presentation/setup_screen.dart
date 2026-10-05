import 'package:flutter/material.dart';
import 'package:suspecto/features/profiles/presentation/player_avatar.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/game_options.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';
import 'package:suspecto/features/game/presentation/widgets/game_options_section.dart';
import 'package:suspecto/features/game/presentation/widgets/pack_picker.dart';
import 'package:suspecto/features/packs/data/word_pack_catalog.dart';
import 'package:suspecto/features/packs/domain/dealable_words.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';
import 'package:suspecto/features/packs/presentation/packs_screen.dart';

/// The untouched default names, which are never saved as players.
final _placeholderName = RegExp(r'^Player \d+$');

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _form = GlobalKey<FormState>();
  final _names = List.generate(
    3,
    (i) => TextEditingController(text: 'Player ${i + 1}'),
  );
  Set<String> _packIds = builtInPacks.map((p) => p.id).toSet();
  int _imposters = 1;
  int _minutes = 3;
  GameOptions _options = const GameOptions();
  bool _restored = false;

  List<WordPack> get _packs => [
        ...builtInPacks,
        ...?StoreScope.maybeOf(context)?.customPacks,
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) {
      return;
    }
    _restored = true;
    final store = StoreScope.maybeOf(context);
    if (store == null) {
      return;
    }
    if (store.lastPlayers.length >= 3 && store.lastPlayers.length <= 20) {
      for (final c in _names) {
        c.dispose();
      }
      _names
        ..clear()
        ..addAll(
            store.lastPlayers.map((name) => TextEditingController(text: name)));
    }
    final available = _packs.map((p) => p.id).toSet();
    final saved = store.lastCategories.where(available.contains).toSet();
    if (saved.isNotEmpty) {
      _packIds = saved;
    }
    _imposters =
        store.lastImposters.clamp(1, GameEngine.maxImposters(_names.length));
    _minutes = [1, 3, 5].contains(store.lastMinutes) ? store.lastMinutes : 3;
    _options = store.lastOptions;
  }

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() => setState(() =>
      _names.add(TextEditingController(text: 'Player ${_names.length + 1}')));

  /// Puts a saved player into the first empty or placeholder row, or a new row.
  void _addSaved(String name) => setState(() {
        final free = _names.where((c) =>
            c.text.trim().isEmpty || _placeholderName.hasMatch(c.text.trim()));
        if (free.isNotEmpty) {
          free.first.text = name;
        } else if (_names.length < 20) {
          _names.add(TextEditingController(text: name));
        }
      });

  void _removePlayer(int index) => setState(() {
        _names.removeAt(index).dispose();
        _imposters =
            _imposters.clamp(1, GameEngine.maxImposters(_names.length));
      });

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return translate(context, 'Enter a name');
    }
    final duplicates = _names
        .where((c) => c.text.trim().toLowerCase() == name.toLowerCase())
        .length;
    return duplicates > 1 ? translate(context, 'Use a different name') : null;
  }

  void _start() {
    if (!_form.currentState!.validate()) {
      return;
    }
    final packs = _packs.where((p) => _packIds.contains(p.id)).toList();
    final deal = dealableWords(packs, _options);
    if (deal.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: LocalText(deal.error!)));
      return;
    }
    final players = List.generate(
      _names.length,
      (i) => Player(id: '$i', name: _names[i].text.trim()),
    );
    final store = StoreScope.maybeOf(context);
    store?.saveSetup(players.map((p) => p.name).toList(),
        packs.map((p) => p.id).toList(), _imposters, _minutes,
        options: _options);
    store?.rememberPlayers(players
        .map((p) => p.name)
        .where((name) => !_placeholderName.hasMatch(name)));
    store?.feedback();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(
          players: players,
          words: deal.words,
          imposterCount: _imposters,
          discussionMinutes: _minutes,
          options: _options,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GamePage(
      title: 'Gather your suspects',
      subtitle: 'Add your friends, pick your packs, and pass the phone.',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              for (var i = 0; i < _names.length; i++) _playerRow(i),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _names.length < 20 ? _addPlayer : null,
          icon: const Icon(Icons.person_add_alt_1),
          label: LocalText('Add player (${_names.length}/20)'),
        ),
        _savedPlayers(theme),
        const SizedBox(height: 24),
        LocalText('Imposters', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var n = 1; n <= GameEngine.maxImposters(_names.length); n++)
              ChoiceChip(
                label: LocalText('$n'),
                selected: _imposters == n,
                onSelected: (_) => setState(() => _imposters = n),
              ),
          ],
        ),
        const SizedBox(height: 24),
        GameOptionsSection(
          options: _options,
          onChanged: (options) => setState(() => _options = options),
        ),
        const SizedBox(height: 24),
        if (_options.mode != GameMode.questions) ...[
          PackPicker(
            packs: _packs,
            selected: _packIds,
            onChanged: (ids) => setState(() => _packIds = ids),
            onManage: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PacksScreen())),
          ),
          const SizedBox(height: 24),
        ],
        if (!_options.speedRound) ...[
          LocalText('Discussion time', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in [1, 3, 5])
                ChoiceChip(
                  label: LocalText('$n min'),
                  selected: _minutes == n,
                  onSelected: (_) => setState(() => _minutes = n),
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
            onPressed: _start, child: const LocalText('Deal secret roles')),
      ],
    );
  }

  /// One-tap chips for remembered players who are not in the list yet.
  Widget _savedPlayers(ThemeData theme) {
    final inList = _names.map((c) => c.text.trim().toLowerCase()).toSet();
    final saved = [
      ...?StoreScope.maybeOf(context)?.profiles,
    ].where((p) => !inList.contains(p.name.toLowerCase())).toList();
    if (saved.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalText('Saved players', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final profile in saved)
                ActionChip(
                  avatar: PlayerAvatar(name: profile.name, radius: 12),
                  label: Text(profile.name),
                  onPressed: _names.length < 20 ||
                          _names.any((c) =>
                              _placeholderName.hasMatch(c.text.trim()) ||
                              c.text.trim().isEmpty)
                      ? () => _addSaved(profile.name)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerRow(int i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            PlayerAvatar(name: _names[i].text),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _names[i],
                maxLength: 24,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: translate(context, 'Player ${i + 1}'),
                  counterText: '',
                ),
                validator: _validateName,
                onChanged: (_) => setState(() {}),
              ),
            ),
            IconButton(
              tooltip: translate(context, 'Remove player ${i + 1}'),
              onPressed: _names.length > 3 ? () => _removePlayer(i) : null,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
}
