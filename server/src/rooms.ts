import { randomBytes, randomInt, timingSafeEqual } from 'node:crypto';
import type { WebSocket } from 'ws';
import { config } from './config.js';
import { ROOM_ALPHABET, ROOM_CODE_LENGTH } from './protocol.js';

export interface Room {
  code: string;
  hostToken: string;
  host: WebSocket | null;
  peers: Map<string, WebSocket>;
  nextPeer: number;
  lastActivity: number;
  hostGraceTimer?: NodeJS.Timeout;
}

/** In-memory rooms. One server instance owns all of its rooms. */
export class RoomRegistry {
  private readonly rooms = new Map<string, Room>();

  get size(): number {
    return this.rooms.size;
  }

  get(code: string): Room | undefined {
    return this.rooms.get(code);
  }

  /** Creates a room hosted by [host], or null when the server is full. */
  create(host: WebSocket): Room | null {
    if (this.rooms.size >= config.maxRooms) return null;
    let code: string;
    do {
      code = Array.from(
        { length: ROOM_CODE_LENGTH },
        () => ROOM_ALPHABET[randomInt(ROOM_ALPHABET.length)],
      ).join('');
    } while (this.rooms.has(code));
    const room: Room = {
      code,
      hostToken: randomBytes(18).toString('base64url'),
      host,
      peers: new Map(),
      nextPeer: 1,
      lastActivity: Date.now(),
    };
    this.rooms.set(code, room);
    return room;
  }

  tokenMatches(room: Room, token: string): boolean {
    const a = Buffer.from(room.hostToken);
    const b = Buffer.from(token);
    return a.length === b.length && timingSafeEqual(a, b);
  }

  addPeer(room: Room, socket: WebSocket): string | null {
    if (room.peers.size >= config.maxPeersPerRoom) return null;
    const id = `g${room.nextPeer++}`;
    room.peers.set(id, socket);
    return id;
  }

  /** Closes the room and tells every guest. */
  close(room: Room): void {
    clearTimeout(room.hostGraceTimer);
    this.rooms.delete(room.code);
    for (const peer of room.peers.values()) {
      send(peer, { op: 'room-closed' });
      peer.close(1000, 'room closed');
    }
    room.peers.clear();
    room.host?.close(1000, 'room closed');
    room.host = null;
  }

  /** Closes rooms that have been silent for too long. */
  sweepIdle(now = Date.now()): number {
    let closed = 0;
    for (const room of [...this.rooms.values()]) {
      if (now - room.lastActivity > config.idleRoomMs) {
        this.close(room);
        closed++;
      }
    }
    return closed;
  }
}

export function send(socket: WebSocket | null | undefined, message: object): void {
  if (socket && socket.readyState === socket.OPEN) {
    socket.send(JSON.stringify(message));
  }
}
