/**
 * Relay protocol, version 1. JSON text frames over WebSocket at /rooms.
 *
 * The relay never reads game messages: `data` is an opaque string carrying
 * the app's own multi-phone protocol between the host and each guest.
 *
 * Host -> server:   create | resume | send {to, data} | kick {peer} | close
 * Guest -> server:  join {room} | send {data}
 * Server -> host:   created {room, hostToken} | resumed {room, peers}
 *                   peer-open {peer} | peer-close {peer} | data {from, data}
 * Server -> guest:  joined {peer} | data {data} | host-away | host-back
 *                   room-closed
 * Server -> anyone: error {reason}
 */
export const RELAY_VERSION = 1;

export type ErrorReason =
  | 'bad-version'
  | 'bad-request'
  | 'room-not-found'
  | 'room-full'
  | 'server-full'
  | 'rate-limited';

export type ClientMessage =
  | { op: 'create'; v: number }
  | { op: 'resume'; v: number; room: string; hostToken: string }
  | { op: 'join'; v: number; room: string }
  | { op: 'send'; to?: string; data: string }
  | { op: 'kick'; peer: string }
  | { op: 'close' };

const isString = (value: unknown, max = 64): value is string =>
  typeof value === 'string' && value.length > 0 && value.length <= max;

/** Validates a parsed frame; returns null for anything malformed. */
export function parseClientMessage(raw: unknown): ClientMessage | null {
  if (typeof raw !== 'object' || raw === null) return null;
  const m = raw as Record<string, unknown>;
  switch (m.op) {
    case 'create':
      return typeof m.v === 'number' ? { op: 'create', v: m.v } : null;
    case 'resume':
      return typeof m.v === 'number' && isString(m.room) && isString(m.hostToken)
        ? { op: 'resume', v: m.v, room: m.room, hostToken: m.hostToken }
        : null;
    case 'join':
      return typeof m.v === 'number' && isString(m.room)
        ? { op: 'join', v: m.v, room: m.room }
        : null;
    case 'send':
      if (typeof m.data !== 'string') return null;
      if (m.to !== undefined && !isString(m.to)) return null;
      return { op: 'send', to: m.to as string | undefined, data: m.data };
    case 'kick':
      return isString(m.peer) ? { op: 'kick', peer: m.peer } : null;
    case 'close':
      return { op: 'close' };
    default:
      return null;
  }
}

/** Room codes leave out look-alike characters (0/O, 1/I/L). */
export const ROOM_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const ROOM_CODE_LENGTH = 6;

export function normalizeRoomCode(input: string): string {
  return input.toUpperCase().replace(/[\s-]/g, '');
}
