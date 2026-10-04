# Suspecto

Suspecto is a Flutter party word game where everyone knows the secret word except the imposter.

## Product direction

- Offline-first local party gameplay
- Modern Flutter UI and animations
- Expandable category/word-pack system
- Optional cloud services for analytics, remote config, crash reporting, and purchases
- Custom backend added when online multiplayer or account-based features are introduced

## Current foundation

- Flutter app shell
- Material 3 theme
- Home screen
- Game domain models
- Testable game engine
- Starter local word data
- Unit tests
- Backend architecture decision documented in `docs/architecture.md`

## Local setup

This repository currently contains the application source foundation. If platform folders are not present after cloning, run:

```bash
flutter create . --project-name suspecto
flutter pub get
flutter test
flutter run
```

The generated Android/iOS platform folders can then be committed as part of the next setup milestone.
