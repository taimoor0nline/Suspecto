import 'dart:async';
import 'dart:convert';

import 'package:suspecto/features/lan/data/lan_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Relay protocol version; must match the server (server/src/protocol.ts).
const relayVersion = 1;

const _unreachable = LanUnreachable(
    "Couldn't reach the online game server. Check your internet connection.");

Map<String, Object?>? _decode(Object? frame) {
  if (frame is! String) {
    return null;
  }
  try {
    final json = jsonDecode(frame);
    return json is Map<String, Object?> && json['op'] is String ? json : null;
  } catch (_) {
    return null;
  }
}

String _errorText(Object? reason) => switch (reason) {
      'room-not-found' =>
        'No game with that code. Check the code and try again.',
      'room-full' => 'This game is full.',
      'server-full' => 'The online game server is busy. Try again soon.',
      'bad-version' => 'Update Suspecto on every phone to play together.',
      _ => 'Could not join this game.',
    };

/// The host side of an online room. Each guest appears as a [LanSocket], so
/// the host session treats online guests exactly like Wi-Fi guests. If the
/// connection to the server drops, it resumes the room with its host token.
class RelayHost {
  RelayHost._(this.serverUrl, this._onConnect);

  final String serverUrl;
  final void Function(LanSocket socket) _onConnect;

  /// Called when the server connection is lost (true) or restored (false).
  void Function(bool reconnecting)? onReconnecting;

  /// Called when the room could not be resumed and has ended.
  void Function()? onRoomLost;

  late String roomCode;
  late String _hostToken;
  WebSocketChannel? _channel;
  final Map<String, _RelayPeerSocket> _peers = {};
  bool _closed = false;
  Timer? _retry;
  DateTime? _awaySince;

  /// Server keeps a room this long after the host disconnects.
  static const _grace = Duration(seconds: 55);

  static Future<RelayHost> create(
      String serverUrl, void Function(LanSocket socket) onConnect) async {
    final host = RelayHost._(serverUrl, onConnect);
    final created = await host._open({'op': 'create', 'v': relayVersion});
    if (created['op'] != 'created') {
      host._channel?.sink.close();
      throw LanException(_errorText(created['reason']));
    }
    host
      ..roomCode = created['room'] as String
      .._hostToken = created['hostToken'] as String;
    return host;
  }

  /// Connects, sends [hello] and returns the server's first reply; later
  /// frames go to [_onFrame].
  Future<Map<String, Object?>> _open(Map<String, Object?> hello) async {
    final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    try {
      await channel.ready.timeout(const Duration(seconds: 8));
    } catch (_) {
      throw _unreachable;
    }
    _channel = channel;
    final first = Completer<Map<String, Object?>>();
    channel.stream.listen(
      (frame) {
        final message = _decode(frame);
        if (message == null) {
          return;
        }
        if (!first.isCompleted) {
          first.complete(message);
        } else {
          _onFrame(message);
        }
      },
      onDone: () {
        if (!first.isCompleted) {
          first.completeError(_unreachable);
        } else if (_channel == channel) {
          _onDrop();
        }
      },
      onError: (Object _) {},
      cancelOnError: false,
    );
    channel.sink.add(jsonEncode(hello));
    return first.future.timeout(const Duration(seconds: 8),
        onTimeout: () => throw _unreachable);
  }

  void _onFrame(Map<String, Object?> message) {
    switch (message['op']) {
      case 'peer-open':
        final id = message['peer'];
        if (id is String) {
          final socket = _RelayPeerSocket(this, id);
          _peers[id] = socket;
          _onConnect(socket);
        }
      case 'data':
        final from = message['from'];
        final data = message['data'];
        if (from is String && data is String) {
          _peers[from]?._receive(data);
        }
      case 'peer-close':
        final id = message['peer'];
        if (id is String) {
          _peers.remove(id)?._closed();
        }
    }
  }

  void _onDrop() {
    if (_closed) {
      return;
    }
    _channel = null;
    _awaySince ??= DateTime.now();
    onReconnecting?.call(true);
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 2), _resume);
  }

  Future<void> _resume() async {
    if (_closed) {
      return;
    }
    if (DateTime.now().difference(_awaySince!) > _grace) {
      // The server has closed the room; guests were told.
      _closed = true;
      for (final peer in _peers.values) {
        peer._closed();
      }
      _peers.clear();
      onRoomLost?.call();
      return;
    }
    try {
      final reply = await _open({
        'op': 'resume',
        'v': relayVersion,
        'room': roomCode,
        'hostToken': _hostToken,
      });
      if (reply['op'] != 'resumed') {
        _channel?.sink.close();
        _channel = null;
        _awaySince = DateTime(2000); // Room is gone: stop retrying.
        _resume();
        return;
      }
      _awaySince = null;
      final present = (reply['peers'] as List?)?.whereType<String>().toSet() ??
          const <String>{};
      for (final id in _peers.keys.toList()) {
        if (!present.contains(id)) {
          _peers.remove(id)?._closed();
        }
      }
      // Guests who joined while the host was away.
      for (final id in present.difference(_peers.keys.toSet())) {
        final socket = _RelayPeerSocket(this, id);
        _peers[id] = socket;
        _onConnect(socket);
      }
      onReconnecting?.call(false);
    } catch (_) {
      _retry = Timer(const Duration(seconds: 2), _resume);
    }
  }

  void _send(Map<String, Object?> message) =>
      _channel?.sink.add(jsonEncode(message));

  /// Ends the room for every guest.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _retry?.cancel();
    _send({'op': 'close'});
    await _channel?.sink.close();
    for (final peer in _peers.values) {
      peer._closed();
    }
    _peers.clear();
  }
}

class _RelayPeerSocket implements LanSocket {
  _RelayPeerSocket(this._host, this.id);
  final RelayHost _host;
  final String id;
  final _messages = StreamController<String>();

  @override
  Stream<String> get messages => _messages.stream;

  void _receive(String data) {
    if (!_messages.isClosed) {
      _messages.add(data);
    }
  }

  void _closed() {
    if (!_messages.isClosed) {
      _messages.close();
    }
  }

  @override
  void send(String message) =>
      _host._send({'op': 'send', 'to': id, 'data': message});

  @override
  Future<void> close() async {
    if (_host._peers.remove(id) != null) {
      _host._send({'op': 'kick', 'peer': id});
    }
    _closed();
  }
}

/// Joins online room [room] as a guest. Relay notices about the host are
/// turned into the app's own messages (`host-away`, `host-back`, `closed`),
/// so the guest session handles online and Wi-Fi games the same way.
Future<LanSocket> connectRelay(String serverUrl, String room) async {
  final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
  try {
    await channel.ready.timeout(const Duration(seconds: 8));
  } catch (_) {
    throw _unreachable;
  }
  final joined = Completer<void>();
  final messages = StreamController<String>();
  channel.stream.listen(
    (frame) {
      final message = _decode(frame);
      switch (message?['op']) {
        case 'joined':
          joined.complete();
        case 'data':
          final data = message!['data'];
          if (data is String) {
            messages.add(data);
          }
        case 'host-away':
          messages.add(jsonEncode({'t': 'host-away'}));
        case 'host-back':
          messages.add(jsonEncode({'t': 'host-back'}));
        case 'room-closed':
          messages.add(jsonEncode({'t': 'closed'}));
        case 'error':
          if (!joined.isCompleted) {
            joined.completeError(LanException(_errorText(message!['reason'])));
          }
      }
    },
    onDone: () {
      if (!joined.isCompleted) {
        joined.completeError(_unreachable);
      }
      messages.close();
    },
    onError: (Object _) {},
    cancelOnError: false,
  );
  channel.sink.add(jsonEncode({'op': 'join', 'v': relayVersion, 'room': room}));
  try {
    await joined.future.timeout(const Duration(seconds: 8));
  } on LanException {
    await channel.sink.close();
    rethrow;
  } catch (_) {
    await channel.sink.close();
    throw _unreachable;
  }
  return _RelayGuestSocket(channel, messages.stream);
}

class _RelayGuestSocket implements LanSocket {
  _RelayGuestSocket(this._channel, this.messages);
  final WebSocketChannel _channel;

  @override
  final Stream<String> messages;

  @override
  void send(String message) =>
      _channel.sink.add(jsonEncode({'op': 'send', 'data': message}));

  @override
  Future<void> close() => _channel.sink.close();
}
