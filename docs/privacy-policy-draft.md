# Suspecto privacy policy — draft for release review

Suspecto is an offline party word game. The current beta has no account system,
ads SDK, analytics SDK, crash-reporting service or custom backend.

The app stores player display names, preferences, completed rounds and derived
player statistics on your device. These are used to restore game setup and show
your game history. The app retains up to 200 completed rounds. Game roles are
not transmitted to a server by the application.

You can clear round history and statistics from History & Stats. Removing app
data using operating-system settings removes locally stored app data. Device
backup services and web-browser storage may have separate retention behavior
controlled by the device/browser provider. Other people with access to an
unlocked device can see stored names and game history.

The bundled word packs work offline. No microphone, location or contacts
permission is needed. Multi-phone games use the local network (Wi-Fi or a phone
hotspot) to connect phones directly; player names, roles needed by each phone,
votes and scores are exchanged only between phones in that game and are not
sent to the internet. On iOS this requires Local Network permission. The camera
is used only, if you choose, to scan a host's join QR code; images are processed
on the device and not stored. The host phone saves completed multi-phone rounds
to its own history. Tapping Share on a results screen creates an image on
the device (round outcome, word, player names, awards and points) and opens the
system share sheet; nothing is sent unless you choose an app to share with. Any network permission in a debug build is
used by development tooling; release manifests must be reviewed before release.

Online rooms (builds configured with a game server) send the same game
messages through the publisher's relay server so phones on different networks
can play: player names, each phone's own card, votes and results. The server
keeps rooms in memory only while a game is open, does not store or log message
contents, and connections are encrypted (wss). The hosting provider may log IP
addresses. The publisher must name the server operator and location here
before enabling online rooms in a release.

This draft applies only to the current build. Introducing ads, purchases,
analytics or cloud features requires revising the policy and store declarations.

Before publication, the publisher must supply its legal identity, privacy contact,
effective date, policy-hosting URL and relevant regional disclosures. This is
product documentation for review, not a finalized legal assessment.
