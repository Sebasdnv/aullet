class Profile {
  final String id;
  final String userId;
  String displayName;
  String? avatarUrl;

  Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    displayName: map['display_name'] as String,
    avatarUrl: map['avatar_url'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'display_name': displayName,
    'avatar_url': avatarUrl
  };
}