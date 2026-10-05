/// Online play: the relay server address, set at build time with
/// `--dart-define=ROOM_SERVER=wss://rooms.example.com/rooms`. Builds without
/// it hide online rooms.
const roomServerUrl = String.fromEnvironment('ROOM_SERVER');

bool get onlineRoomsAvailable => roomServerUrl.isNotEmpty;

/// A 6-character online room code, e.g. `K7F2QD`. Unlike a Wi-Fi [JoinCode]
/// it is issued by the relay server rather than derived from an address.
class RoomCode {
  const RoomCode(this.code);

  /// The prefix older versions put in room QR codes; still accepted.
  static const qrPrefix = 'suspecto:room:';
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const length = 6;

  final String code;

  /// The QR code holds the join link, so phone cameras open the app.
  String get qrData => 'suspecto://room/$code';

  /// Parses typed or scanned input, or returns null.
  static RoomCode? parse(String input) {
    var text = input.trim().toUpperCase();
    for (final prefix in [qrPrefix, 'suspecto://room/']) {
      if (text.startsWith(prefix.toUpperCase())) {
        text = text.substring(prefix.length);
      }
    }
    text = text.replaceAll(RegExp(r'[\s-]'), '');
    if (text.length != length || !text.split('').every(alphabet.contains)) {
      return null;
    }
    return RoomCode(text);
  }
}

/// What the lobby shows so friends can join: a code to type and a QR code.
class Invite {
  const Invite(
      {required this.code, required this.qrData, required this.online});
  final String code;
  final String qrData;

  /// An online room (any network) rather than a Wi-Fi/hotspot game.
  final bool online;
}
