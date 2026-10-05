import { createServer } from 'node:http';
import { WebSocketServer, type WebSocket } from 'ws';
import { config } from './config.js';
import {
  RELAY_VERSION,
  normalizeRoomCode,
  parseClientMessage,
  type ErrorReason,
} from './protocol.js';
import { RoomRegistry, send, type Room } from './rooms.js';

const rooms = new RoomRegistry();

const http = createServer((request, response) => {
  if (request.url === '/health') {
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ ok: true, rooms: rooms.size }));
    return;
  }
  response.writeHead(404).end();
});

const wss = new WebSocketServer({
  server: http,
  path: '/rooms',
  maxPayload: config.maxMessageBytes,
  verifyClient: ({ origin }: { origin?: string }) =>
    !origin ||
    config.allowedOrigins.length === 0 ||
    config.allowedOrigins.includes(origin),
});

/** Per-connection state. */
interface Client {
  room?: Room;
  role?: 'host' | 'guest';
  peerId?: string;
  alive: boolean;
  tokens: number;
  lastRefill: number;
}

const clients = new WeakMap<WebSocket, Client>();

function fail(socket: WebSocket, reason: ErrorReason, close = true): void {
  send(socket, { op: 'error', reason });
  if (close) socket.close(1008, reason);
}

/** Token bucket: [messagesPerSecond] with a burst of twice that. */
function allow(client: Client): boolean {
  const now = Date.now();
  const burst = config.messagesPerSecond * 2;
  client.tokens = Math.min(
    burst,
    client.tokens + ((now - client.lastRefill) / 1000) * config.messagesPerSecond,
  );
  client.lastRefill = now;
  if (client.tokens < 1) return false;
  client.tokens -= 1;
  return true;
}

wss.on('connection', (socket) => {
  const client: Client = {
    alive: true,
    tokens: config.messagesPerSecond * 2,
    lastRefill: Date.now(),
  };
  clients.set(socket, client);
  socket.on('pong', () => {
    client.alive = true;
  });

  socket.on('message', (raw, isBinary) => {
    if (isBinary) return fail(socket, 'bad-request');
    if (!allow(client)) return fail(socket, 'rate-limited');
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw.toString());
    } catch {
      return fail(socket, 'bad-request');
    }
    const message = parseClientMessage(parsed);
    if (!message) return fail(socket, 'bad-request');
    const room = client.room;
    if (room) room.lastActivity = Date.now();

    switch (message.op) {
      case 'create': {
        if (client.room) return fail(socket, 'bad-request');
        if (message.v !== RELAY_VERSION) return fail(socket, 'bad-version');
        const created = rooms.create(socket);
        if (!created) return fail(socket, 'server-full');
        Object.assign(client, { room: created, role: 'host' });
        return send(socket, {
          op: 'created',
          room: created.code,
          hostToken: created.hostToken,
        });
      }
      case 'resume': {
        if (client.room) return fail(socket, 'bad-request');
        if (message.v !== RELAY_VERSION) return fail(socket, 'bad-version');
        const target = rooms.get(normalizeRoomCode(message.room));
        if (!target || target.host || !rooms.tokenMatches(target, message.hostToken)) {
          return fail(socket, 'room-not-found');
        }
        clearTimeout(target.hostGraceTimer);
        target.host = socket;
        target.lastActivity = Date.now();
        Object.assign(client, { room: target, role: 'host' });
        send(socket, { op: 'resumed', room: target.code, peers: [...target.peers.keys()] });
        for (const peer of target.peers.values()) send(peer, { op: 'host-back' });
        return;
      }
      case 'join': {
        if (client.room) return fail(socket, 'bad-request');
        if (message.v !== RELAY_VERSION) return fail(socket, 'bad-version');
        const target = rooms.get(normalizeRoomCode(message.room));
        if (!target) return fail(socket, 'room-not-found');
        const peerId = rooms.addPeer(target, socket);
        if (!peerId) return fail(socket, 'room-full');
        Object.assign(client, { room: target, role: 'guest', peerId });
        send(socket, { op: 'joined', peer: peerId });
        if (!target.host) send(socket, { op: 'host-away' });
        return send(target.host, { op: 'peer-open', peer: peerId });
      }
      case 'send': {
        if (!room) return fail(socket, 'bad-request');
        if (client.role === 'host') {
          if (!message.to) return;
          return send(room.peers.get(message.to), { op: 'data', data: message.data });
        }
        return send(room.host, { op: 'data', from: client.peerId, data: message.data });
      }
      case 'kick': {
        if (!room || client.role !== 'host') return fail(socket, 'bad-request');
        const peer = room.peers.get(message.peer);
        room.peers.delete(message.peer);
        peer?.close(1000, 'removed by host');
        return;
      }
      case 'close': {
        if (!room || client.role !== 'host') return fail(socket, 'bad-request');
        client.room = undefined;
        return rooms.close(room);
      }
    }
  });

  socket.on('close', () => {
    const room = client.room;
    if (!room) return;
    if (client.role === 'guest' && client.peerId) {
      if (room.peers.get(client.peerId) === socket) {
        room.peers.delete(client.peerId);
        send(room.host, { op: 'peer-close', peer: client.peerId });
      }
      return;
    }
    if (client.role === 'host' && room.host === socket) {
      // Keep the room briefly: phones drop connections when locked.
      room.host = null;
      for (const peer of room.peers.values()) send(peer, { op: 'host-away' });
      room.hostGraceTimer = setTimeout(() => rooms.close(room), config.hostGraceMs);
    }
  });
});

// Heartbeat: drop connections that stop answering pings.
const heartbeat = setInterval(() => {
  for (const socket of wss.clients) {
    const client = clients.get(socket);
    if (!client) continue;
    if (!client.alive) {
      socket.terminate();
      continue;
    }
    client.alive = false;
    socket.ping();
  }
  rooms.sweepIdle();
}, 20_000);

function shutdown(): void {
  clearInterval(heartbeat);
  for (const socket of wss.clients) socket.close(1001, 'server restarting');
  http.close(() => process.exit(0));
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

http.listen(config.port, () => {
  console.log(`Suspecto rooms relay listening on :${config.port} (path /rooms)`);
});
