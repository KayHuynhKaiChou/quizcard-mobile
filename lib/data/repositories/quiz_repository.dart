import 'dart:convert';

import '../models/quiz_models.dart';
import '../models/page_response.dart';
import '../services/auth_service.dart';

class QuizRepository {
  final AuthService _auth;
  QuizRepository(this._auth);

  Future<GeneratedQuiz> generateQuiz(QuizConfig config) async {
    final response =
        await _auth.authenticatedPost('/quiz/generate', body: config.toJson());
    if (response.statusCode != 200) throw Exception('Failed to generate quiz');
    return GeneratedQuiz.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> submitQuiz(QuizSubmission submission) async {
    final response =
        await _auth.authenticatedPost('/quiz/submit', body: submission.toJson());
    if (response.statusCode != 200) throw Exception('Failed to submit quiz');
    return jsonDecode(response.body);
  }

  Future<PageResponse<QuizResult>> getHistory({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _auth.authenticatedGet(
      '/quiz/history',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );
    if (response.statusCode != 200) throw Exception('Failed to load history');
    return PageResponse<QuizResult>.fromJson(
      jsonDecode(response.body),
      QuizResult.fromJson,
    );
  }

  Future<QuizResultDetail> getResultDetail(String id) async {
    final response = await _auth.authenticatedGet('/quiz/history/$id');
    if (response.statusCode != 200) throw Exception('Failed to load result');
    return QuizResultDetail.fromJson(jsonDecode(response.body));
  }
}
