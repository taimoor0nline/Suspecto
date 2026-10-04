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
        const SnackBar(content: Text('Choose at least one category.')),
      );
      return;
    }
    final players = List.generate(
      _names.length,
      (i) => Player(id: '$i', name: _names[i].text.trim()),
    );
    final words = starterWords
        .where((w) => _categories.contains(w.category))
        .toList();
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
                    CircleAvatar(child: Text('${i + 1}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _names[i],
                        maxLength: 24,
                        decoration: InputDecoration(
                          labelText: 'Player ${i + 1}',
                          counterText: '',
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) {
                            return 'Enter a name';
                          }
                          if (_names
                                  .where(
                                    (c) =>
                                        c.text.trim().toLowerCase() ==
                                        name.toLowerCase(),
                                  )
                                  .length >
                              1) {
                            return 'Use a different name';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove player ${i + 1}',
                      onPressed: _names.length > 3
                          ? () {
                              setState(() {
                                _names.removeAt(i).dispose();
                                if (_imposters >
                                    GameEngine.maxImposters(_names.length)) {
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
                  TextEditingController(text: 'Player ${_names.length + 1}'),
                ),
              )
            : null,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Add player (${_names.length}/20)'),
      ),
      const SizedBox(height: 24),
      Text('Imposters', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (var n = 1; n <= GameEngine.maxImposters(_names.length); n++)
            ChoiceChip(
              label: Text('$n'),
              selected: _imposters == n,
              onSelected: (_) => setState(() => _imposters = n),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Text('Word packs', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: starterWords
            .map((w) => w.category)
            .toSet()
            .map(
              (category) => FilterChip(
                label: Text(category),
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
      Text('Discussion time', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final n in [1, 3, 5])
            ChoiceChip(
              label: Text('$n min'),
              selected: _minutes == n,
              onSelected: (_) => setState(() => _minutes = n),
            ),
        ],
      ),
      const SizedBox(height: 28),
      FilledButton(onPressed: _start, child: const Text('Deal secret roles')),
    ],
  );
}
