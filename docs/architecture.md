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

## Source layout

```
lib/
  app/                     MaterialApp, theme
  core/                    AppStore (settings + persistence), language config,
    l10n/                  localization helpers and the Arabic string table
  features/
    game/
      domain/models/       Player, WordEntry, GameOptions/GameMode, GameSession,
                           RoundResult
      domain/services/     GameEngine (dealing, undercover decoys, guess options),
                           Ballot, Scoring
      application/         RoundController: the round state machine
      data/local/          generated built-in words and translations
      presentation/        setup + play screens; phases/ holds one widget per
                           round phase; widgets/ holds shared pieces
    packs/                 WordPack model, built-in catalog, pack list/editor
    lan/                   multi-phone play on Wi-Fi/hotspot
      domain/              JoinCode (IPv4+port as 8 chars), LanView protocol
      application/         LanHostGame (authoritative game on the host),
                           HostSession / ClientSession (shared LanSession API)
      data/                WebSocket transport (dart:io; stub on web)
      presentation/        menu, host setup, join, QR scan, game screen + views
    history/  home/  settings/
```

### Multi-phone protocol

JSON over WebSocket at `ws://<host>:<port>/ws`. A guest sends
`{t: hello, v, name, token}`; the host replies with `view` messages, a
`reject` with a reason, or `closed`. Each `view` is personalised: it carries
only the receiving phone's card, and reveals all roles only in the result.
Guests send actions (`seen`, `vote`, `guess`, `leave`); host-only actions
(`start`, `discuss`, `startVote`, `addTime`, `lobby`, `kick`) are ignored from
other phones. A guest that reconnects with the same token, or with the name of
a disconnected player, resumes as that player. Bump `lanProtocolVersion` on
any incompatible change.

Presentation widgets render `RoundController` state and forward taps to it;
game rules live in the domain layer and contain no Flutter UI code.

## Engagement features

- `GameMode.questions` deals (innocent, imposter) question pairs from
  `questionPairs`; the innocent question is revealed during discussion (by the
  host in multi-phone games). The last-chance guess is not used in this mode.
- `GameOptions.jester` makes one innocent player the Jester when there are at
  least `GameOptions.jesterMinPlayers` players.
- `WordDifficulty` filters built-in words; `dealableWords` applies it in setup.
- `PartyAwards.compute` derives session titles from `RoundResult`s, which now
  keep the final ballot. Ties award nobody.
- `SoundEffects` (core/audio) plays bundled WAVs and is disabled under
  `flutter test`. `Celebration` and `CountdownSounds` add sound and confetti.
- `ResultShareCard` is rendered to PNG and shared with `share_plus`.
- `GameOptions.speedRound` sets a 30-second discussion.
- `PlayerProfile` (features/profiles) stores a name, avatar and colour.
  History stays keyed by name; `AppStore.saveProfile` renames a player across
  history, and `nameInUse` blocks renames that would merge two people. Names
  without a profile get a stable default look from `PlayerProfile.defaultFor`.
- `GamePage` uses a non-lazy scroll view so off-screen forms stay alive.
- `Achievements` (features/achievements) tallies saved history per player name
  and reports what a round unlocked; `AppStore.stats` uses the same winner rule.
- `PackCode` packs a custom pack as `suspecto:pack:1:` + base64url(gzip(JSON)),
  under the 2,800-character limit for one QR code (200 words of Arabic or
  Chinese is about 1,600). `ScanCodeScreen` (core/widgets) scans join codes and
  packs.
- Online rooms: `server/` is a Node.js WebSocket relay (no game logic, no
  storage). `RelayHost` exposes each online guest to `HostSession` as a
  `LanSocket`, and `connectRelay` gives guests the same interface, so Wi-Fi and
  online games share `LanHostGame` and all screens. Relay notices about the
  host become `host-away`/`host-back` app messages. The server keeps a room
  for 60 seconds after the host disconnects so it can resume with its token.
  `ROOM_SERVER` (dart-define) enables the feature.
- `GameOptions.matchTarget` (0, 5, 10 or 15; 0 is endless) turns a
  pass-the-phone session into a match. `RoundController.champion` is the
  single leader once they reach the target; a tie at the top keeps playing.
  `newMatch` clears session scores and awards. `MatchRules` holds the winner
  rule for both pass-the-phone and multi-phone games.
- `GameOptions.detective` and `GameOptions.accomplice` deal extra roles to
  innocent players, after the Jester and never
  leaving fewer than `GameEngine.minPlainCitizens` plain citizens. The
  Detective's card names `GameSession.detectiveClearId`, a non-imposter. The
  Accomplice sees the imposters, scores as one, and counts as an imposter-team
  winner in stats; history saves both roles by name.
- `GameOptions.drawing` adds `RoundPhase.drawing` between reveal and
  discussion (not in question mode). Each player, in seat order from the
  starting player, adds one `DrawingStroke` per turn for
  `GameOptions.drawingLaps` laps. Points are normalised 0–1. `DrawingCanvas`
  claims touches with an `EagerGestureRecognizer` so drags draw instead of
  scrolling the page. Sketches are not saved to history.
- Multi-phone protocol version 3 adds `LanPhase.drawing` and the `draw`
  (current drawer's finished line) and host-only `skipDraw` actions; lines
  travel as whole thousandths, thinned to `lanMaxStrokePoints`. Cards carry
  the Accomplice's imposter IDs and the Detective's cleared ID, results name
  both, and views carry the match target, winner and tie. Once someone wins,
  the host's next `start` begins a new match.
- `JoinLink` builds and parses `suspecto://room/<code>` and
  `suspecto://join/<code>`; join QR codes now hold these links (the old
  `suspecto:room:`/`suspecto:join:` prefixes still parse). Android declares
  the scheme in an intent filter and iOS in `CFBundleURLTypes`; Flutter's
  built-in deep linking delivers the route, which may be the path only
  (`/ABC123`), so the code kind is decided by the last part's length.
  `MaterialApp.onGenerateRoute` opens a pre-filled `JoinScreen`.
- Reactions: phones send `react` with an index into `lanReactionEmoji`
  (no free text) in `lanReactionPhases`, at most one per `reactionGap` per
  player. Views carry the last `maxReactions` with an increasing `seq`, and
  `ReactionOverlay` animates only reactions newer than the first view it saw.
- Multi-phone protocol version 2 adds the Jester flag, revealed question and
  awards to each view.

## Scoring

| Event | Points |
| --- | --- |
| Citizens catch every imposter | +1 each citizen |
| Citizen's vote named an imposter | +1 that citizen |
| At least one imposter escapes | +2 each imposter |
| Caught imposters guess the word | +3 each imposter |
| The Jester is voted out | +3 Jester; nobody else wins (sharp votes still count) |
| The Accomplice | Scores as an imposter; no point for voting an imposter |

History records store points by player name. Rounds saved before scoring was
added contribute wins but no points to the leaderboard.
