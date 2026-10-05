/// A short, typeable code that carries the host phone's local IPv4 address
/// and port, e.g. `K7FQ-2D9A`. No server is needed to look it up.
///
/// Layout (40 bits, 8 Crockford base-32 characters):
/// 32 bits IPv4 address, 4 bits port offset from [basePort], 4 bits checksum.
class JoinCode {
  const JoinCode({required this.host, required this.port});

  static const basePort = 47820;
  static const portRange = 16;

  /// The prefix older versions put in join QR codes; still accepted.
  static const qrPrefix = 'suspecto:join:';
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  final String host;
  final int port;

  /// The display form, grouped as `XXXX-XXXX`.
  String get code {
    final parts = host.split('.').map(int.parse).toList();
    // Arithmetic instead of bit shifts: web integers are 32-bit for shifts.
    final ip = parts.fold<int>(0, (value, part) => value * 256 + part);
    final payload = ip * 16 + (port - basePort);
    var value = payload * 16 + _checksum(payload);
    final chars = List.filled(8, '');
    for (var i = 7; i >= 0; i--) {
      chars[i] = _alphabet[value % 32];
      value ~/= 32;
    }
    return '${chars.take(4).join()}-${chars.skip(4).join()}';
  }

  /// The QR code holds the join link, so phone cameras open the app.
  String get qrData => 'suspecto://join/${code.replaceAll('-', '')}';

  static bool canEncode(String host, int port) =>
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) &&
      host.split('.').every((p) => int.parse(p) <= 255) &&
      port >= basePort &&
      port < basePort + portRange;

  /// Parses typed or scanned input. Tolerates lower case, spaces, dashes and
  /// the look-alike letters O, I and L. Returns null for invalid codes.
  static JoinCode? parse(String input) {
    var text = input.trim().toUpperCase();
    for (final prefix in [qrPrefix, 'suspecto://join/']) {
      if (text.startsWith(prefix.toUpperCase())) {
        text = text.substring(prefix.length);
      }
    }
    text = text
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll('O', '0')
        .replaceAll(RegExp('[IL]'), '1');
    if (text.length != 8) {
      return null;
    }
    var value = 0;
    for (final char in text.split('')) {
      final digit = _alphabet.indexOf(char);
      if (digit < 0) {
        return null;
      }
      value = value * 32 + digit;
    }
    final payload = value ~/ 16;
    if (_checksum(payload) != value % 16) {
      return null;
    }
    final ip = payload ~/ 16;
    final host = [16777216, 65536, 256, 1].map((d) => ip ~/ d % 256).join('.');
    return JoinCode(host: host, port: basePort + payload % 16);
  }

  static int _checksum(int payload) {
    var sum = 7;
    for (var rest = payload, i = 0; i < 9; i++, rest ~/= 16) {
      sum = (sum * 31 + rest % 16) % 16;
    }
    return sum;
  }
}
