/// One AI-generated example sentence, before the user decides to keep it.
class AiSentence {
  final String word;
  final String sentence;
  final String? translation;

  const AiSentence({
    required this.word,
    required this.sentence,
    this.translation,
  });

  factory AiSentence.fromJson(Map<String, dynamic> json) {
    return AiSentence(
      word: json['word']?.toString() ?? '',
      sentence: json['sentence']?.toString() ?? '',
      translation: _stringOrNull(json['translation']),
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'sentence': sentence,
        if (translation != null) 'translation': translation,
      };
}

/// A sentence the user kept. Standalone on the server: linked to the user only.
class SavedSentence {
  final String id;
  final String word;
  final String sentence;
  final String? translation;
  final DateTime? createdAt;

  const SavedSentence({
    required this.id,
    required this.word,
    required this.sentence,
    this.translation,
    this.createdAt,
  });

  factory SavedSentence.fromJson(Map<String, dynamic> json) {
    return SavedSentence(
      id: json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      sentence: json['sentence']?.toString() ?? '',
      translation: _stringOrNull(json['translation']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
