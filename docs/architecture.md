# Suspecto Architecture

## V1 approach

Suspecto starts as an offline-first Flutter application.

### Flutter app responsibilities

- Local player setup
- Game rules and round state
- Imposter selection
- Secret-word selection
- Local category and word packs
- Settings and local preferences
- Offline game history and statistics

### Managed cloud services

V1 can use managed services without a custom backend:

- Firebase Analytics
- Firebase Crashlytics
- Firebase Remote Config
- Push notifications
- Google Play / App Store purchases, optionally through RevenueCat

### When a custom backend becomes necessary

Introduce a dedicated API when we add one or more of:

- Real-time multiplayer rooms
- User accounts and cross-device profiles
- Cloud game history
- Admin-managed dynamic word packs
- Leaderboards
- Friend systems
- Server-authoritative anti-cheat rules
- Subscription entitlements not delegated to a managed provider

## Recommended future backend

If/when required:

- ASP.NET Core Web API
- PostgreSQL
- Redis for rooms/presence
- SignalR/WebSockets for live multiplayer
- Object storage/CDN for downloadable content

Keep the Flutter domain layer independent from backend implementations so offline and online modes can coexist.

## Implemented offline beta storage

SharedPreferences stores one versioned JSON snapshot for settings, last party
setup and up to 200 completed rounds. Player statistics are derived from those
retained rounds by display name. This small snapshot does not need a database
server. Word packs are generated from a validated bilingual JSON content source
and compiled into the application. Unfinished role assignments are never saved.
Storage failure keeps gameplay available; saved changes may be lost.

English/Arabic translation and Flutter localization delegates provide RTL
support. Preferences independently control theme, haptic feedback and system
click sounds. No monetization or remote telemetry SDK is enabled.
