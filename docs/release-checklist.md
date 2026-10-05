# Release checklist

## Automated delivery

CI validates bilingual content, resolves dependencies, generates platform runners
and launcher icons, analyzes source, runs tests, captures screenshots, builds the
web app and builds an Android debug APK. Download `suspecto-beta` from the successful
GitHub Actions run. Generated runners/lockfile are archived for committing after review.

## Device QA — requires real devices

- Android and iPhone: full game, exit confirmation, rematch and restart.
- 3/7/20 players, 1/2/3 imposters, ties and invalid names/categories.
- Portrait/landscape, small displays and 200% text scale.
- All seven locales and Arabic direction, long names and translated words.
- Pointer cancel, app switch, screen lock and interruptions during role reveal.
- Android secure-window behavior and iOS inactive-scene cover; validate recent-app previews.
- Timer resume, voting privacy, haptics and system sound preferences.
- Settings/history persistence, clear history and storage failure behavior.
- Airplane mode, accessibility screen reader and reduced motion.
- Verify screen-reader announcement timing does not disclose roles to other players.
- Sounds on real speakers and with the silent switch; confetti with reduced
  motion; sharing the results image to WhatsApp/Instagram on Android and iPhone
  (iPad needs the share popover position).
- Question mode wording in every language, and Jester rounds with 5+ players.
- Scan a shared pack QR code between Android and iPhone, including a 200-word
  Arabic or Chinese pack (dense code) at normal screen brightness.
- Achievements after upgrading with existing history; tutorial card on first run.
- Multi-phone: host on Android and iPhone; join by QR and typed code; 3 and 20
  phones; same Wi-Fi and phone hotspot; iOS Local Network and camera prompts;
  screen lock, Wi-Fi drop and app switch on guests and host; rejoin mid-round;
  duplicate names, kicked players and a guest joining during a round.

## Android release — requires publisher credentials

Finalize reverse-domain application ID; `com.suspecto` is a development placeholder.
Create/secure the upload key. Configure `android/key.properties` locally and
release signing in Gradle. Never commit a keystore, password or key.properties.
Build `flutter build appbundle --release`, then use Play Console internal testing.
Complete privacy URL, data-safety declarations, rating, target-audience selection,
listing assets and testing requirements. Final requirements must be checked in
Play Console at submission time.

## iOS release — requires macOS/Xcode and Apple developer account

Finalize bundle ID and team, configure signing/capabilities and launcher icon,
review privacy declarations, test on devices, build/archive with Xcode or
`flutter build ipa`, upload to TestFlight and complete the App Store listing.
A separate macOS CI job builds an iOS simulator app without publisher signing.
It does not produce an installable iPhone IPA or App Store approval.

## Commercial services — intentionally awaiting configuration

Ads require app/ad unit IDs, consent strategy and revised privacy disclosures.
Purchases require product IDs, pricing, restore flow and store sandbox testing.
Crash reporting/analytics require a project, platform registrations, collection
policy and configuration files. No placeholder service IDs should ship.
Do not enable these services simply to mark the checklist complete.

## Content and product decisions

Review all translations with native speakers. The current vocabulary is
original curated starter content, not the proposed tens-of-thousands-word catalog.
Check branding/name rights, finalize publisher/contact information and decide
whether children are a target audience before any monetization integration.
