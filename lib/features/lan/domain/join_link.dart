import 'package:suspecto/features/lan/domain/join_code.dart';
import 'package:suspecto/features/lan/domain/room_code.dart';

/// Links that open the app on the join screen with the code filled in:
/// `suspecto://room/ABC123` for an online room and `suspecto://join/K7FQ2D9A`
/// for a Wi-Fi game. Join QR codes carry these links, so a phone's camera
/// app can open them too.
class JoinLink {
  JoinLink._();

  static const scheme = 'suspecto';

  static String forRoom(RoomCode room) => room.qrData;

  static String forWifi(JoinCode code) => code.qrData;

  /// A [RoomCode] or [JoinCode] from a link, or from the route the platform
  /// hands the app for one (`/ABC123`, `/room/ABC123` or the whole link).
  /// The two code kinds differ in length, so the last part decides.
  static Object? parse(String link) {
    final parts = link
        .trim()
        .split(RegExp(r'[/?#]'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty || !_known(parts)) {
      return null;
    }
    final last = parts.last;
    return RoomCode.parse(last) ?? JoinCode.parse(last);
  }

  /// Only our own links, or bare routes the platform derived from them.
  static bool _known(List<String> parts) {
    final first = parts.first.toLowerCase();
    if (first.endsWith(':')) {
      return first == '$scheme:' && parts.length == 3;
    }
    return parts.length == 1 ||
        (parts.length == 2 && (parts.first == 'room' || parts.first == 'join'));
  }
}
