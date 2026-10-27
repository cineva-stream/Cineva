import 'dart:convert';

/// Domain entity representing a local user profile in Cineva.
class UserProfile {
  final String name;
  final String username;
  final String avatarId;
  final String? customAvatarPath;
  final DateTime createdAt;
  final bool isConfigured;

  const UserProfile({
    required this.name,
    required this.username,
    required this.avatarId,
    this.customAvatarPath,
    required this.createdAt,
    this.isConfigured = false,
  });

  /// Default profile when app is freshly installed
  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: 'Penikmat Film',
      username: 'cineva_fan',
      avatarId: 'avatar_popcorn',
      customAvatarPath: null,
      createdAt: DateTime.now(),
      isConfigured: false,
    );
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? avatarId,
    String? customAvatarPath,
    bool clearCustomAvatar = false,
    DateTime? createdAt,
    bool? isConfigured,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      customAvatarPath: clearCustomAvatar
          ? null
          : (customAvatarPath ?? this.customAvatarPath),
      createdAt: createdAt ?? this.createdAt,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'avatarId': avatarId,
      'customAvatarPath': customAvatarPath,
      'createdAt': createdAt.toIso8601String(),
      'isConfigured': isConfigured,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Penikmat Film',
      username: (map['username'] as String?)?.trim().isNotEmpty == true
          ? (map['username'] as String).replaceAll('@', '')
          : 'cineva_fan',
      avatarId: (map['avatarId'] as String?) ?? 'avatar_popcorn',
      customAvatarPath: map['customAvatarPath'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isConfigured: (map['isConfigured'] as bool?) ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.name == name &&
        other.username == username &&
        other.avatarId == avatarId &&
        other.customAvatarPath == customAvatarPath &&
        other.isConfigured == isConfigured;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      username,
      avatarId,
      customAvatarPath,
      isConfigured,
    );
  }
}
