import 'dart:io';

import 'package:suspecto/features/lan/data/lan_socket.dart';
import 'package:suspecto/features/lan/domain/join_code.dart';

const lanSupported = true;

/// Larger messages are dropped; real views are a few kilobytes.
const _maxMessageLength = 64 * 1024;

class _IoSocket implements LanSocket {
  _IoSocket(this._socket) {
    // Detects phones that vanished without closing (screen locked, out of
    // range) so the host can mark them disconnected.
    _socket.pingInterval = const Duration(seconds: 4);
  }

  final WebSocket _socket;

  @override
  late final Stream<String> messages = _socket
      .where((m) => m is String && m.length <= _maxMessageLength)
      .cast<String>();

  @override
  void send(String message) {
    if (_socket.readyState == WebSocket.open) {
      _socket.add(message);
    }
  }

  @override
  Future<void> close() => _socket.close();
}

class _IoServer implements LanServer {
  _IoServer(this._server);
  final HttpServer _server;

  @override
  int get port => _server.port;

  @override
  Future<void> close() => _server.close(force: true);
}

/// Listens on the first free port in the join-code range, on all IPv4
/// interfaces, so phones on the same Wi-Fi or this phone's hotspot can join.
Future<LanServer> startLanServer(
    void Function(LanSocket socket) onConnect) async {
  for (var offset = 0; offset < JoinCode.portRange; offset++) {
    final HttpServer server;
    try {
      server = await HttpServer.bind(
          InternetAddress.anyIPv4, JoinCode.basePort + offset);
    } on SocketException {
      continue;
    }
    server.listen((request) async {
      if (request.uri.path == '/ws' &&
          WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          onConnect(_IoSocket(await WebSocketTransformer.upgrade(request)));
        } catch (_) {/* A failed handshake affects only that phone. */}
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    }, onError: (Object _) {});
    return _IoServer(server);
  }
  throw const LanException(
      'Could not open a network port. Close other apps and try again.');
}

Future<LanSocket> connectLan(String host, int port) async {
  final socket = await WebSocket.connect('ws://$host:$port/ws')
      .timeout(const Duration(seconds: 5));
  return _IoSocket(socket);
}

/// The address other phones should use to reach this one: a private IPv4
/// address on Wi-Fi or a hotspot, never a mobile-data interface.
Future<String?> findLanAddress() async {
  final List<NetworkInterface> interfaces;
  try {
    interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  } catch (_) {
    return null;
  }
  const cellular = ['pdp_ip', 'rmnet', 'ccmni', 'clat', 'v4-rmnet'];
  int? rank(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    if (parts[0] == 192 && parts[1] == 168) {
      return 0;
    }
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) {
      return 1;
    }
    if (parts[0] == 10) {
      return 2;
    }
    return null;
  }

  String? best;
  var bestRank = 99;
  for (final interface in interfaces) {
    if (cellular.any(interface.name.startsWith)) {
      continue;
    }
    for (final address in interface.addresses) {
      final r = rank(address.address);
      if (r != null && r < bestRank) {
        best = address.address;
        bestRank = r;
      }
    }
  }
  return best;
}
