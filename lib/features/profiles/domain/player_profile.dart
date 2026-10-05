/// A remembered player: the name used in history plus an avatar and colour.
/// History and achievements are keyed by name, so a profile keeps a person's
/// spelling consistent and renaming one moves their stats with it.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
  });

  /// A stable avatar and colour derived from [name], used until a player
  /// picks their own.
  factory PlayerProfile.defaultFor(String name, {String? id}) {
    final hash = _hash(name.trim().toLowerCase());
    return PlayerProfile(
      id: id ?? newId(),
      name: name.trim(),
      avatar: avatars[hash % avatars.length],
      color: colors[(hash ~/ avatars.length) % colors.length],
    );
  }

  static const maxProfiles = 100;

  static const avatars = [
    '🦊', '🐼', '🐯', '🦁', '🐸', '🐵', '🐙', '🦄', //
    '🐧', '🐨', '🐻', '🐰', '🦉', '🐢', '🐬', '🦖', //
    '👽', '🤖', '👻', '🧙', '🥷', '🦸', '🧛', '🐱', //
  ];

  static const colors = [
    0xFF6C4DFF, 0xFFFF5D8F, 0xFF2EC4B6, 0xFFFFC233, //
    0xFF8BE04E, 0xFFFF8C42, 0xFF4D9DE0, 0xFFB565D9, //
  ];

  final String id;
  final String name;
  final String avatar;

  /// An ARGB colour from [colors].
  final int color;

  static String newId() => 'player:${DateTime.now().microsecondsSinceEpoch}';

  PlayerProfile copyWith({String? name, String? avatar, int? color}) =>
      PlayerProfile(
        id: id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        color: color ?? this.color,
      );

  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'avatar': avatar, 'color': color};

  static PlayerProfile? fromJson(Object? json) {
    if (json is! Map ||
        json['id'] is! String ||
        json['name'] is! String ||
        (json['name'] as String).trim().isEmpty ||
        (json['name'] as String).trim().length > 24) {
      return null;
    }
    final fallback = PlayerProfile.defaultFor(json['name'] as String,
        id: json['id'] as String);
    return fallback.copyWith(
      avatar:
          avatars.contains(json['avatar']) ? json['avatar'] as String : null,
      color: colors.contains(json['color']) ? json['color'] as int : null,
    );
  }

  /// Deterministic across runs and platforms (unlike String.hashCode on web).
  static int _hash(String text) {
    var hash = 7;
    for (final unit in text.codeUnits) {
      hash = (hash * 31 + unit) % 1000003;
    }
    return hash;
  }
}
