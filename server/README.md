# Suspecto online rooms relay

A small Node.js WebSocket server that lets phones on different networks play
the same game. It creates 6-character room codes and passes messages between
the phones in a room. **It has no game logic and stores nothing on disk**: the
host phone runs the game exactly as in Wi-Fi mode, and each message is an
opaque string of the app's own multi-phone protocol.

## Run locally

```bash
cd server
npm install
npm run build
PORT=8080 npm start          # ws://localhost:8080/rooms, health at /health
```

Run the app against it (Android emulators reach your computer at `10.0.2.2`):

```bash
flutter run --dart-define=ROOM_SERVER=ws://localhost:8080/rooms
```

## Deploy on your own VPS (Docker + automatic HTTPS)

Requirements: a Linux server with Docker and Docker Compose, and a domain
name (for example `rooms.example.com`) whose DNS A/AAAA record points to it.
Ports 80 and 443 must be open.

```bash
git clone <this repo> && cd Suspecto/server
cp .env.example .env          # set ROOMS_DOMAIN=rooms.example.com
docker compose up -d --build
curl https://rooms.example.com/health
```

Caddy obtains and renews the HTTPS certificate automatically. Update with
`git pull && docker compose up -d --build`.

## Deploy on a hosting platform

Any platform that runs a Dockerfile and supports WebSockets works (for example
Fly.io, Render, Railway, or a cloud container service). Point it at the
`server/` directory; it listens on the `PORT` the platform provides and serves
WebSockets at `/rooms`. HTTPS is provided by the platform.

Run **one instance**: rooms live in memory, so several instances would each
see only their own rooms.

## Build the app for your server

```bash
flutter build appbundle --dart-define=ROOM_SERVER=wss://rooms.example.com/rooms
flutter build ipa       --dart-define=ROOM_SERVER=wss://rooms.example.com/rooms
flutter build web       --dart-define=ROOM_SERVER=wss://rooms.example.com/rooms
```

Builds without `ROOM_SERVER` hide online rooms; Wi-Fi play still works.
Always use `wss://` in release builds.

## Settings (environment variables)

| Variable | Default | Meaning |
| --- | --- | --- |
| `PORT` | 8080 | HTTP/WebSocket port |
| `MAX_ROOMS` | 2000 | Rooms open at once |
| `MAX_PEERS_PER_ROOM` | 19 | Guests per room (plus the host = 20 players) |
| `HOST_GRACE_SECONDS` | 60 | How long a room waits for its host to reconnect |
| `IDLE_ROOM_MINUTES` | 120 | Rooms with no traffic are closed after this |
| `MAX_MESSAGE_BYTES` | 65536 | Largest accepted message |
| `MESSAGES_PER_SECOND` | 30 | Per-connection rate limit (burst is double) |
| `ALLOWED_ORIGINS` | (any) | Comma-separated browser origins for the web app |

## Protocol (version 1)

JSON text frames at `/rooms`. See `src/protocol.ts`.

- Host: `create` → `created {room, hostToken}`; then `peer-open`,
  `data {from, data}` and `peer-close` as guests come and go. It sends
  `send {to, data}`, `kick {peer}` and `close`.
- Guest: `join {room}` → `joined {peer}`; sends `send {data}` and receives
  `data {data}`, `host-away`, `host-back` and `room-closed`.
- If the host disconnects (for example the phone locks), guests get
  `host-away` and the room waits `HOST_GRACE_SECONDS` for `resume {room,
  hostToken}`.
- Errors: `error {reason}` with `bad-version`, `bad-request`,
  `room-not-found`, `room-full`, `server-full` or `rate-limited`.

## Privacy and operations

The server keeps room state in memory only and does not log message
contents. Game messages (player names, each player's own card, votes and
results) pass through it in transit; with `wss://` they are encrypted between
each phone and the server. Your hosting provider may log IP addresses.
