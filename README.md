# Suspecto

An offline pass-the-phone party game in Flutter. No API, accounts or remote database.

## Offline beta features

- 3–20 players, 1–3 imposters (strictly fewer than half the party)
- 340 unique words across 17 family-friendly packs in seven languages, including
  themed packs: Football Fever, Countries, Movies & TV, Ramadan & Eid and Kids
- Saved player setup, categories and discussion duration
- Private hold-to-reveal roles, hiding on release/cancellation/background
- Classic mode, Undercover mode where imposters secretly get a similar word, and
  Question mode where everyone answers a question aloud and imposters secretly
  get a different one (27 question pairs in every language)
- Word difficulty: Mixed, Easy, Medium or Hard (custom words match every level)
- Optional Jester: one innocent player who wins alone if voted out (5+ players)
- Sound effects (card, vote, countdown, time-up, win/lose stings), card-flip
  reveal and confetti, all respecting the sound setting and reduced motion
- Party awards (MVP, Best Bluffer, Sharpest Detective, Most Suspected, Chaos
  Jester) and a shareable results image
- Speed round: a 30-second discussion with one-word clues
- 11 achievements per player, derived from saved history (so earlier rounds
  count), shown on results and in History
- Share custom packs by QR code and import them with "Scan a pack"
- A five-page quick tutorial, offered on Home until seen
- Optional category hint for imposters (classic mode)
- Last-chance guess: caught imposters can steal the win by picking the word
- Timed discussion (+1 minute), random first speaker, private ballots, ties/revotes
- Points per round, session scoreboard across rematches and all-time leaderboard
- Custom word packs (up to 50 packs of 3–200 words) created and stored on device
- Multi-phone play on the same Wi-Fi or a phone hotspot, with no internet or server:
  one phone hosts and shows a QR/join code, everyone reveals and votes on their own
  phone at the same time, and dropped phones rejoin with their role and score
- Last 200 completed rounds and player statistics on this device
- English, Arabic, Spanish, French, Japanese and Simplified/Traditional Chinese
  interface, RTL layout for Arabic, light/dark/system theme
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

Edit `assets/content/words.json` (words and their 1–3 difficulty) or
`assets/content/questions.json` (question pairs) and regenerate Dart constants.
Sound effects are synthesized by `python scripts/generate_sounds.py`, so they are
original audio with no third-party licence. The generator checks
unique IDs, every locale's terms and required fields without a network connection.

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

English, Arabic, Spanish, French, Japanese, Simplified Chinese and Traditional
Chinese are enabled. Each has all 340 word concepts; new locales include the full
UI catalog and dynamic messages. User names are preserved. New translations
need native-speaker review before release.

New UI strings are added in English with their Arabic translation in
`lib/core/l10n/arabic_strings.dart`; that table defines the required keys.
Edit `assets/content/ui_translations.json` for the other languages' UI strings and
`assets/content/words.json` for vocabulary. Run `python scripts/generate_content.py`
to regenerate Dart constants. Validation rejects missing entries, duplicate word
translations and mismatched placeholders. Run the validation unit tests with
`python -m unittest discover -s scripts -p 'test_*.py'`.
