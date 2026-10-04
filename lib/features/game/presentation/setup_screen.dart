import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:flutter/material.dart';
import 'package:suspecto/features/game/data/local/starter_words.dart';
import 'package:suspecto/features/game/domain/models/player.dart';
import 'package:suspecto/features/game/domain/services/game_engine.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/game/presentation/play_screen.dart';

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
  final _categories = starterWords.map((w) => w.category).toSet();
  int _imposters = 1;
  int _minutes = 3;
  bool _restored = false;

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
      _names.clear();
      _names.addAll(
          store.lastPlayers.map((name) => TextEditingController(text: name)));
    }
    final saved = store.lastCategories.where(_categories.contains).toSet();
    if (saved.isNotEmpty) {
      _categories.clear();
      _categories.addAll(saved);
    }
    _imposters =
        store.lastImposters.clamp(1, GameEngine.maxImposters(_names.length));
    _minutes = [1, 3, 5].contains(store.lastMinutes) ? store.lastMinutes : 3;
  }

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  void _start() {
    if (!_form.currentState!.validate()) {
      return;
    }
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalText('Choose at least one category.')),
      );
      return;
    }
    final players = List.generate(
      _names.length,
      (i) => Player(id: '$i', name: _names[i].text.trim()),
    );
    final words =
        starterWords.where((w) => _categories.contains(w.category)).toList();
    StoreScope.maybeOf(context)?.saveSetup(players.map((p) => p.name).toList(),
        _categories.toList(), _imposters, _minutes);
    StoreScope.maybeOf(context)?.feedback();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(
          players: players,
          words: words,
          imposterCount: _imposters,
          discussionMinutes: _minutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GamePage(
        title: 'Gather your suspects',
        subtitle: 'Add your friends, pick your packs, and pass the phone.',
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                for (var i = 0; i < _names.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                            backgroundColor: Colors
                                .primaries[i % Colors.primaries.length]
                                .withValues(alpha: 0.18),
                            child: Icon([
                              Icons.pets,
                              Icons.bolt,
                              Icons.star,
                              Icons.rocket_launch,
                              Icons.local_florist,
                              Icons.sports_esports
                            ][i % 6])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _names[i],
                            maxLength: 24,
                            decoration: InputDecoration(
                              labelText: translate(context, 'Player ${i + 1}'),
                              counterText: '',
                            ),
                            validator: (value) {
                              final name = value?.trim() ?? '';
                              if (name.isEmpty) {
                                return translate(context, 'Enter a name');
                              }
                              if (_names
                                      .where(
                                        (c) =>
                                            c.text.trim().toLowerCase() ==
                                            name.toLowerCase(),
                                      )
                                      .length >
                                  1) {
                                return translate(
                                    context, 'Use a different name');
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: translate(context, 'Remove player ${i + 1}'),
                          onPressed: _names.length > 3
                              ? () {
                                  setState(() {
                                    _names.removeAt(i).dispose();
                                    if (_imposters >
                                        GameEngine.maxImposters(
                                            _names.length)) {
                                      _imposters = GameEngine.maxImposters(
                                        _names.length,
                                      );
                                    }
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _names.length < 20
                ? () => setState(
                      () => _names.add(
                        TextEditingController(
                            text: 'Player ${_names.length + 1}'),
                      ),
                    )
                : null,
            icon: const Icon(Icons.person_add_alt_1),
            label: LocalText('Add player (${_names.length}/20)'),
          ),
          const SizedBox(height: 24),
          LocalText('Imposters', style: Theme.of(context).textTheme.titleLarge),
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
          LocalText('Word packs',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: starterWords
                .map((w) => w.category)
                .toSet()
                .map(
                  (category) => FilterChip(
                    label: LocalText(category),
                    selected: _categories.contains(category),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _categories.add(category);
                      } else {
                        _categories.remove(category);
                      }
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          LocalText('Discussion time',
              style: Theme.of(context).textTheme.titleLarge),
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
          const SizedBox(height: 28),
          FilledButton(
              onPressed: _start, child: const LocalText('Deal secret roles')),
        ],
      );
}
