class QuizConfig {
  final String studySetId;
  final String quizType; // multiple_choice, true_false, fill_blank
  final int questionCount;
  final int? timeLimitSeconds;

  QuizConfig({
    required this.studySetId,
    this.quizType = 'multiple_choice',
    this.questionCount = 10,
    this.timeLimitSeconds,
  });

  Map<String, dynamic> toJson() => {
    'studySetId': studySetId,
    'quizType': quizType,
    'questionCount': questionCount,
    if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
  };
}

class QuizQuestion {
  final String id;
  final String questionText;
  final String type;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['question'] ?? json['questionText'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }
}

class GeneratedQuiz {
  final String quizId;
  final String studySetId;
  final String quizType;
  final List<QuizQuestion> questions;
  final int? timeLimitSeconds;

  GeneratedQuiz({
    required this.quizId,
    required this.studySetId,
    required this.quizType,
    required this.questions,
    this.timeLimitSeconds,
  });

  factory GeneratedQuiz.fromJson(Map<String, dynamic> json) {
    return GeneratedQuiz(
      quizId: json['quizId']?.toString() ?? '',
      studySetId: json['studySetId']?.toString() ?? '',
      quizType: json['quizType'] ?? 'multiple_choice',
      questions: (json['questions'] as List?)
          ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      timeLimitSeconds: json['timeLimitSeconds'],
    );
  }
}

class QuizAnswer {
  final String questionId;
  final String selectedAnswer;

  QuizAnswer({required this.questionId, required this.selectedAnswer});

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'selectedAnswer': selectedAnswer,
  };
}

class QuizSubmission {
  final String quizId;
  final List<QuizAnswer> answers;
  final int timeSpentSeconds;

  QuizSubmission({
    required this.quizId,
    required this.answers,
    required this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() => {
    'quizId': quizId,
    'answers': answers.map((a) => a.toJson()).toList(),
    'timeSpentSeconds': timeSpentSeconds,
  };
}

class QuizResult {
  final String id;
  final String studySetTitle;
  final String quizType;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final int timeSpentSeconds;
  final DateTime createdAt;

  QuizResult({
    required this.id,
    required this.studySetTitle,
    required this.quizType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.timeSpentSeconds,
    required this.createdAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id']?.toString() ?? '',
      studySetTitle: json['studySetTitle'] ?? '',
      quizType: json['quizType'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class QuizResultDetail extends QuizResult {
  final List<QuestionDetail> details;

  QuizResultDetail({
    required super.id,
    required super.studySetTitle,
    required super.quizType,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.score,
    required super.timeSpentSeconds,
    required super.createdAt,
    required this.details,
  });

  factory QuizResultDetail.fromJson(Map<String, dynamic> json) {
    return QuizResultDetail(
      id: json['id']?.toString() ?? '',
      studySetTitle: json['studySetTitle'] ?? '',
      quizType: json['quizType'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      details: (json['details'] as List?)
          ?.map((e) => QuestionDetail.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class QuestionDetail {
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;

  QuestionDetail({
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) {
    return QuestionDetail(
      questionText: json['term'] ?? json['questionText'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      correctAnswer: json['correctAnswer'] ?? '',
      isCorrect: json['correct'] ?? false,
    );
  }
}
