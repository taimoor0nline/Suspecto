import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:suspecto/features/game/domain/models/round_result.dart';
import 'package:suspecto/features/lan/application/lan_host_game.dart';
import 'package:suspecto/features/lan/data/lan_socket.dart';
import 'package:suspecto/features/lan/data/lan_transport.dart';
import 'package:suspecto/features/lan/domain/join_code.dart';
import 'package:suspecto/features/lan/domain/lan_view.dart';

enum LanStatus { connecting, connected, reconnecting, closed }

/// One phone's connection to a multi-phone game. The UI only reads [view]
/// and calls [send], so host and guest phones share the same screens.
abstract class LanSession extends ChangeNotifier {
  LanView? get view;
  LanStatus get status;

  /// Why the session closed, as an English message.
  String? get closedReason;

  /// Set on the host phone only.
  JoinCode? get joinCode => null;

  void send(String action, [Map<String, Object?> data = const {}]);

  /// Leaves the game. On the host this ends it for everyone.
  Future<void> leave();
}

/// Message types on the wire, besides [LanAction]s from phones.
abstract final class _Wire {
  static const hello = 'hello';
  static const view = 'view';
  static const reject = 'reject';
  static const closed = 'closed';
}

Map<String, Object?>? _decode(String message) {
  try {
    final json = jsonDecode(message);
    return json is Map<String, Object?> && json['t'] is String ? json : null;
  } catch (_) {
    return null;
  }
}

/// Runs the game and the server on the host phone; the host also plays.
class HostSession extends LanSession {
  HostSession._(this.joinCode, this._server);

  late final LanHostGame _game;
  final LanServer _server;
  final Map<String, LanSocket> _sockets = {};
  bool _closed = false;

  @override
  final JoinCode joinCode;

  static Future<HostSession> start({
    required String hostName,
    required LanGameConfig config,
    void Function(RoundResult result)? onRoundComplete,
  }) async {
    if (!lanSupported) {
      throw const LanException(
          'Multi-phone games are not available in the web version.');
    }
    final address = await findLanAddress();
    if (address == null) {
      throw const LanException(
          'Connect to Wi-Fi or turn on your hotspot, then try again.');
    }
    HostSession? session;
    final server = await startLanServer((socket) => session?._accept(socket));
    if (!JoinCode.canEncode(address, server.port)) {
      await server.close();
      throw const LanException(
          'Connect to Wi-Fi or turn on your hotspot, then try again.');
    }
    session = HostSession._(JoinCode(host: address, port: server.port), server);
    session._game = LanHostGame(
      hostName: hostName,
      config: config,
      onChanged: session._broadcast,
      onRoundComplete: onRoundComplete,
      onKicked: session._kick,
    );
    return session;
  }

  @override
  LanView get view => _game.viewFor(LanHostGame.hostId);

  @override
  LanStatus get status => _closed ? LanStatus.closed : LanStatus.connected;

  @override
  String? get closedReason => null;

  /// Enough connected players to deal a round.
  bool get canStart => _game.canStart;

  @override
  void send(String action, [Map<String, Object?> data = const {}]) =>
      _game.handle(LanHostGame.hostId, action, data);

  void _accept(LanSocket socket) {
    String? playerId;
    socket.messages.listen(
      (message) {
        final json = _decode(message);
        if (json == null) {
          return;
        }
        final type = json['t'] as String;
        if (playerId == null) {
          if (type != _Wire.hello) {
            return;
          }
          if (json['v'] != lanProtocolVersion) {
            _reject(socket, 'Update Suspecto on every phone to play together.');
            return;
          }
          final joined = _game.join(
            name: json['name'] is String ? json['name'] as String : '',
            token: json['token'] is String ? json['token'] as String : '',
          );
          if (joined.error != null) {
            _reject(socket, joined.error!);
            return;
          }
          playerId = joined.id;
          final previous = _sockets[playerId!];
          _sockets[playerId!] = socket;
          if (previous != null && previous != socket) {
            unawaited(previous.close());
          }
          _sendView(playerId!, socket);
          return;
        }
        _game.handle(playerId!, type, json);
      },
      onDone: () {
        final id = playerId;
        if (id != null && _sockets[id] == socket) {
          _sockets.remove(id);
          _game.disconnected(id);
        }
      },
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  void _reject(LanSocket socket, String reason) {
    socket.send(jsonEncode({'t': _Wire.reject, 'reason': reason}));
    unawaited(socket.close());
  }

  void _kick(String id) {
    final socket = _sockets.remove(id);
    if (socket != null) {
      _reject(socket, 'The host removed you from the game.');
    }
  }

  void _sendView(String id, LanSocket socket) => socket
      .send(jsonEncode({'t': _Wire.view, 'view': _game.viewFor(id).toJson()}));

  void _broadcast() {
    if (_closed) {
      return;
    }
    _sockets.forEach(_sendView);
    notifyListeners();
  }

  @override
  Future<void> leave() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _game.dispose();
    for (final socket in _sockets.values) {
      socket.send(jsonEncode({'t': _Wire.closed}));
      unawaited(socket.close());
    }
    _sockets.clear();
    await _server.close();
    notifyListeners();
  }
}

/// A guest phone. Reconnects automatically after Wi-Fi blips, rejoining as the
/// same player with the same role and score.
class ClientSession extends LanSession {
  ClientSession({required this.name, required this.code}) {
    unawaited(_connect());
  }

  final String name;
  final JoinCode code;
  final String _token =
      List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16))
          .join();
  LanSocket? _socket;
  LanView? _view;
  LanStatus _status = LanStatus.connecting;
  String? _closedReason;
  bool _left = false;
  int _failures = 0;
  Timer? _retry;

  @override
  LanView? get view => _view;

  @override
  LanStatus get status => _status;

  @override
  String? get closedReason => _closedReason;

  Future<void> _connect() async {
    final LanSocket socket;
    try {
      socket = await connectLan(code.host, code.port);
    } catch (_) {
      _dropped(null);
      return;
    }
    if (_left || _status == LanStatus.closed) {
      unawaited(socket.close());
      return;
    }
    _socket = socket;
    socket.messages.listen(_onMessage,
        onDone: () => _dropped(socket),
        onError: (Object _) {},
        cancelOnError: false);
    socket.send(jsonEncode({
      't': _Wire.hello,
      'v': lanProtocolVersion,
      'name': name,
      'token': _token,
    }));
  }

  void _onMessage(String message) {
    if (_left) {
      return;
    }
    final json = _decode(message);
    switch (json?['t']) {
      case _Wire.view:
        final view = LanView.fromJson(json!['view']);
        if (view != null) {
          _view = view;
          _status = LanStatus.connected;
          _failures = 0;
          notifyListeners();
        }
      case _Wire.reject:
        _close(json!['reason'] is String
            ? json['reason'] as String
            : 'Could not join this game.');
      case _Wire.closed:
        _close('The host ended the game.');
    }
  }

  void _dropped(LanSocket? socket) {
    if (_left || _status == LanStatus.closed || socket != _socket) {
      return;
    }
    _socket = null;
    _failures++;
    if (_view == null && _failures >= 3) {
      _close(
          "Couldn't reach the host. Check that you're on the same Wi-Fi or hotspot and the code is right.");
      return;
    }
    _status = _view == null ? LanStatus.connecting : LanStatus.reconnecting;
    notifyListeners();
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 2), _connect);
  }

  void _close(String reason) {
    _status = LanStatus.closed;
    _closedReason = reason;
    _retry?.cancel();
    final socket = _socket;
    _socket = null;
    unawaited(socket?.close());
    notifyListeners();
  }

  @override
  void send(String action, [Map<String, Object?> data = const {}]) =>
      _socket?.send(jsonEncode({...data, 't': action}));

  @override
  Future<void> leave() async {
    if (_left) {
      return;
    }
    _left = true;
    send(LanAction.leave);
    _retry?.cancel();
    await _socket?.close();
    _socket = null;
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }
}
