/** Settings from environment variables, with safe defaults. */
function int(name: string, fallback: number): number {
  const value = Number.parseInt(process.env[name] ?? '', 10);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

export const config = {
  /** HTTP port. Hosting platforms usually set PORT. */
  port: int('PORT', 8080),
  /** Simultaneous rooms before new rooms are refused. */
  maxRooms: int('MAX_ROOMS', 2000),
  /** Phones per room besides the host (the app allows 20 players). */
  maxPeersPerRoom: int('MAX_PEERS_PER_ROOM', 19),
  /** How long a room waits for its host to reconnect. */
  hostGraceMs: int('HOST_GRACE_SECONDS', 60) * 1000,
  /** Rooms with no traffic for this long are closed. */
  idleRoomMs: int('IDLE_ROOM_MINUTES', 120) * 60 * 1000,
  /** Largest accepted message in bytes. Game views are a few kilobytes. */
  maxMessageBytes: int('MAX_MESSAGE_BYTES', 64 * 1024),
  /** Messages per second allowed per connection (burst is twice this). */
  messagesPerSecond: int('MESSAGES_PER_SECOND', 30),
  /**
   * Comma-separated browser origins allowed to connect (for the web app).
   * Empty allows any origin; native apps send no Origin header.
   */
  allowedOrigins: (process.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
} as const;
