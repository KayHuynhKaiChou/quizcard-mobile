class StudySetDetail {
  final String id;
  final String title;
  final String? description;
  final String? sourceLanguage;
  final String? targetLanguage;
  final String? category;
  final String visibility;
  final int termsCount;
  final double ratingAvg;
  final int cloneCount;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool isOwner;
  final bool isBookmarked;
  final int? userRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudySetDetail({
    required this.id,
    required this.title,
    this.description,
    this.sourceLanguage,
    this.targetLanguage,
    this.category,
    this.visibility = 'PUBLIC',
    this.termsCount = 0,
    this.ratingAvg = 0,
    this.cloneCount = 0,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.isOwner = false,
    this.isBookmarked = false,
    this.userRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudySetDetail.fromJson(Map<String, dynamic> json) {
    return StudySetDetail(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      category: json['category'],
      visibility: json['visibility'] ?? 'PUBLIC',
      termsCount: json['termsCount'] ?? 0,
      ratingAvg: (json['ratingAvg'] ?? 0).toDouble(),
      cloneCount: json['cloneCount'] ?? 0,
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName'] ?? '',
      authorAvatarUrl: json['authorAvatarUrl'],
      isOwner: json['owner'] ?? false,
      isBookmarked: json['bookmarked'] ?? false,
      userRating: json['userRating'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Term {
  final String id;
  final String term;
  final String definition;
  final String? ipa;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? imageUrl;
  final String? audioUrl;
  final String? synonyms;
  final String? antonyms;
  final int orderIndex;

  Term({
    required this.id,
    required this.term,
    required this.definition,
    this.ipa,
    this.exampleSentence,
    this.exampleTranslation,
    this.imageUrl,
    this.audioUrl,
    this.synonyms,
    this.antonyms,
    this.orderIndex = 0,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id']?.toString() ?? '',
      term: json['term'] ?? '',
      definition: json['definition'] ?? '',
      ipa: json['ipa'],
      exampleSentence: json['exampleSentence'],
      exampleTranslation: json['exampleTranslation'],
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      synonyms: json['synonyms'],
      antonyms: json['antonyms'],
      orderIndex: json['orderIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'definition': definition,
      if (ipa != null) 'ipa': ipa,
      if (exampleSentence != null) 'exampleSentence': exampleSentence,
      if (exampleTranslation != null) 'exampleTranslation': exampleTranslation,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (synonyms != null) 'synonyms': synonyms,
      if (antonyms != null) 'antonyms': antonyms,
      'orderIndex': orderIndex,
    };
  }
}

class CursorPage<T> {
  final List<T> content;
  final int? nextCursor;
  final bool hasMore;

  CursorPage({required this.content, this.nextCursor, this.hasMore = false});

  factory CursorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    final contentList = (json['items'] as List?)
        ?.map((e) => fromJsonItem(e as Map<String, dynamic>))
        .toList() ?? [];
    return CursorPage(
      content: contentList,
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}
