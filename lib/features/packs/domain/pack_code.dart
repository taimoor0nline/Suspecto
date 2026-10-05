import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

/// Encodes a custom pack into text small enough for one QR code:
/// `suspecto:pack:1:` + base64url(gzip(JSON {n: name, w: words})).
class PackCode {
  PackCode._();

  static const prefix = 'suspecto:pack:1:';

  /// Comfortably inside a version-40 QR code at low error correction.
  static const maxLength = 2800;

  /// The QR text for [pack], or null if it is too big for one code.
  static String? encode(WordPack pack) {
    final json = utf8.encode(jsonEncode({'n': pack.name, 'w': pack.words}));
    final packed = base64Url
        .encode(GZipEncoder().encodeBytes(json, level: 9))
        .replaceAll('=', '');
    final text = '$prefix$packed';
    return text.length <= maxLength ? text : null;
  }

  /// A scanned pack's name and words, or null if [text] is not a valid pack.
  static ({String name, List<String> words})? decode(String text) {
    if (!text.startsWith(prefix) || text.length > maxLength) {
      return null;
    }
    try {
      final body = text.substring(prefix.length);
      final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
      final json = jsonDecode(
          utf8.decode(GZipDecoder().decodeBytes(base64Url.decode(padded))));
      if (json is! Map || json['n'] is! String || json['w'] is! List) {
        return null;
      }
      final name = (json['n'] as String).trim();
      final words =
          WordPack.normalizeWords((json['w'] as List).whereType<String>());
      if (WordPack.validate(name: name, words: words) != null) {
        return null;
      }
      return (name: name, words: words);
    } catch (_) {
      return null;
    }
  }

  /// [name], or `name 2`, `name 3`… if a pack with that name exists.
  static String uniqueName(String name, Iterable<String> existing) {
    final taken = existing.map((n) => n.trim().toLowerCase()).toSet();
    if (!taken.contains(name.toLowerCase())) {
      return name;
    }
    for (var i = 2;; i++) {
      final suffix = ' $i';
      final base = name.length + suffix.length > WordPack.maxNameLength
          ? name.substring(0, WordPack.maxNameLength - suffix.length).trim()
          : name;
      final candidate = '$base$suffix';
      if (!taken.contains(candidate.toLowerCase())) {
        return candidate;
      }
    }
  }
}
