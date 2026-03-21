class PublicProfileModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int streakCount;
  final int xpPoints;
  final int level;
  final int publicStudySetCount;
  final DateTime createdAt;

  const PublicProfileModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.streakCount = 0,
    this.xpPoints = 0,
    this.level = 1,
    this.publicStudySetCount = 0,
    required this.createdAt,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      xpPoints: (json['xpPoints'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      publicStudySetCount: (json['publicStudySetCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
