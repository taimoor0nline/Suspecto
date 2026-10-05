/// A text message channel between two phones.
abstract class LanSocket {
  Stream<String> get messages;
  void send(String message);
  Future<void> close();
}

/// The host phone's listening server.
abstract class LanServer {
  int get port;
  Future<void> close();
}

/// A failure with an English message suitable for showing to players.
class LanException implements Exception {
  const LanException(this.message);
  final String message;
  @override
  String toString() => message;
}
