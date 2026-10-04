import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return GamePage(title: 'Make it your party', subtitle: 'Preferences are saved on this device.', children: [
      const LocalText('Language', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [for (final item in [('en', 'English'), ('ar', 'العربية')]) ChoiceChip(label: Text(item.$2), selected: store.language == item.$1, onSelected: (_) => store.updateSettings(language: item.$1))]),
      const SizedBox(height: 24),
      const LocalText('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [for (final item in [('system', 'System'), ('light', 'Light'), ('dark', 'Dark')]) ChoiceChip(label: LocalText(item.$2), selected: store.theme == item.$1, onSelected: (_) => store.updateSettings(theme: item.$1))]),
      const SizedBox(height: 24),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const LocalText('Haptics'), value: store.haptics, onChanged: (value) { store.updateSettings(haptics: value); if (value) { store.feedback(); } }),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const LocalText('System click sounds'), subtitle: const LocalText('Sound availability depends on device settings.'), value: store.sounds, onChanged: (value) { store.updateSettings(sounds: value); if (value) { store.feedback(); } }),
      if (!store.storageAvailable) const LocalText('Storage is unavailable. Changes may not survive restarting the app.'),
    ]);
  }
}
