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
to its own history. Any network permission in a debug build is
used by development tooling; release manifests must be reviewed before release.

This draft applies only to the current offline build. Introducing ads, purchases,
analytics or cloud features requires revising the policy and store declarations.

Before publication, the publisher must supply its legal identity, privacy contact,
effective date, policy-hosting URL and relevant regional disclosures. This is
product documentation for review, not a finalized legal assessment.
