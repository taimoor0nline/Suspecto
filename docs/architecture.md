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
