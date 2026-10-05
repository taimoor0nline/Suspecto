// Local-network sockets need dart:io, which the web build does not have.
export 'package:suspecto/features/lan/data/lan_transport_stub.dart'
    if (dart.library.io) 'package:suspecto/features/lan/data/lan_transport_io.dart';
