# Suspecto

An offline pass-the-phone party game in Flutter. No API, accounts or remote database.

## Offline beta features

- 3–20 players, 1–3 imposters (strictly fewer than half the party)
- 240 unique English/Arabic words across 12 family-friendly packs
- Saved player setup, categories and discussion duration
- Private hold-to-reveal roles, hiding on release/cancellation/background
- Timed discussion, private ballots, ties/revotes, results and rematch
- Last 200 completed rounds and player statistics on this device
- English/Arabic interface, RTL layout, light/dark/system theme
- Avatars, reduced-motion-aware transitions, optional haptics/system click sounds
- App branding, launcher icons, automated analysis/tests/builds and screenshot capture

Stats identify players by their display names and reflect the retained 200 rounds.
Unfinished rounds are not restored. Clearing history is permanent. If local storage
fails, gameplay continues and saved changes may be lost after restart.

## Development

Use the Flutter version pinned in `.github/workflows/flutter.yml`.

```bash
flutter create --empty --platforms=android,ios,web --project-name suspecto --org com.suspecto .
flutter pub get
python scripts/generate_content.py
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter run
```

Edit `assets/content/words.json` and regenerate Dart constants. The generator checks
unique IDs, English/Arabic terms and required fields without a network connection.

## Beta artifacts

Android/iOS/web runners and the dependency lockfile are committed. GitHub Actions
builds a debug Android APK, a web bundle, review screenshots and an iOS simulator
app. Android prevents screenshots/recent-app role previews; iOS covers the app
when inactive. These protections still require validation on physical devices.
Android debug builds are for testing only. Release signing and iOS distribution
require your own keys and store accounts. See `docs/release-checklist.md`.

No ads, billing or remote analytics SDK is enabled. See the draft privacy policy
and store listing under `docs/`; review and finalize them before publishing.

## Language availability

Edit `lib/core/language_config.dart` to enable or disable languages for the next
app build. English is the required enabled fallback. Settings and supported
locales use this catalog; a disabled or unknown saved language falls back to
English. Missing translation strings also use English.

English, Arabic, Spanish, French, Japanese, Simplified Chinese and Traditional
Chinese are enabled. Each has all 240 word concepts; new locales include the full
UI catalog and dynamic messages. User names are preserved. New translations
need native-speaker review before release.

Edit `assets/content/ui_translations.json` for new-language UI strings and
`assets/content/words.json` for vocabulary. Run `python scripts/generate_content.py`
to regenerate Dart constants. Validation rejects missing entries, duplicate word
translations and mismatched placeholders. Run the validation unit tests with
`python -m unittest discover -s scripts -p 'test_*.py'`.
