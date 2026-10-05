import 'package:suspecto/features/lan/data/lan_socket.dart';

const lanSupported = false;

const _unsupported =
    LanException('Multi-phone games are not available in the web version.');

Future<LanServer> startLanServer(void Function(LanSocket socket) onConnect) =>
    Future.error(_unsupported);

Future<LanSocket> connectLan(String host, int port) =>
    Future.error(_unsupported);

Future<String?> findLanAddress() async => null;
