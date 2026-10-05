# Suspecto

An offline pass-the-phone party game in Flutter. No API, accounts or remote database.

## Offline beta features

- 3–20 players, 1–3 imposters (strictly fewer than half the party)
- 240 unique English/Arabic words across 12 family-friendly packs
- Saved player setup, categories and discussion duration
- Private hold-to-reveal roles, hiding on release/cancellation/background
- Classic mode, or Undercover mode where imposters secretly get a similar word
- Optional category hint for imposters (classic mode)
- Last-chance guess: caught imposters can steal the win by picking the word
- Timed discussion (+1 minute), random first speaker, private ballots, ties/revotes
- Points per round, session scoreboard across rematches and all-time leaderboard
- Custom word packs (up to 50 packs of 3–200 words) created and stored on device
- Multi-phone play on the same Wi-Fi or a phone hotspot, with no internet or server:
  one phone hosts and shows a QR/join code, everyone reveals and votes on their own
  phone at the same time, and dropped phones rejoin with their role and score
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

## Multi-phone play

The host phone runs a small WebSocket server on the local network (ports
47820–47835). The join code encodes the host's private IPv4 address and port,
so no discovery service or internet is needed. The host is authoritative and
sends each phone only its own card. Only the host phone saves the round to
history. Hosting and joining need Android/iOS; the web build hides this mode.
Some public or office Wi-Fi isolates devices; a phone hotspot avoids that.
Validate on physical devices, including iOS's Local Network permission prompt.

## Language availability

Edit `lib/core/language_config.dart` to enable or disable languages for the next
app build. English is the required enabled fallback. Settings and supported
locales use this catalog; a disabled or unknown saved language falls back to
English. Missing translation strings also use English.

English and Arabic are enabled. Spanish, French, Japanese, Simplified Chinese
and Traditional Chinese are registered but disabled: their UI and word
translations must be implemented and reviewed before enabling them. The catalog
includes native names, locale codes and text direction. This is bundled
configuration, so changes require a new build; no network is required.
