class StudySetSummary {
  final String id;
  final String title;
  final String? description;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final String? category;
  final int termsCount;
  final int cloneCount;
  final double ratingAvg;

  const StudySetSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.authorDisplayName,
    required this.authorAvatarUrl,
    required this.category,
    required this.termsCount,
    required this.cloneCount,
    required this.ratingAvg,
  });

  factory StudySetSummary.fromJson(Map<String, dynamic> json) {
    return StudySetSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled').toString(),
      description: json['description'] as String?,
      authorDisplayName: json['authorDisplayName'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      category: json['category'] as String?,
      termsCount: (json['termsCount'] as num?)?.toInt() ?? 0,
      cloneCount: (json['cloneCount'] as num?)?.toInt() ?? 0,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
    );
  }
}
