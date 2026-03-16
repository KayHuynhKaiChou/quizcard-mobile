import 'dart:convert';

import '../services/auth_service.dart';

class LearningRepository {
  final AuthService _auth;
  LearningRepository(this._auth);

  Future<List<Map<String, dynamic>>> getTodayReview() async {
    final response = await _auth.authenticatedGet('/learning/today');
    if (response.statusCode != 200) throw Exception('Failed to load reviews');
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> submitReview({
    required String termId,
    required int quality,
  }) async {
    final response = await _auth.authenticatedPost('/learning/review', body: {
      'termId': termId,
      'quality': quality,
    });
    if (response.statusCode != 200) throw Exception('Failed to submit review');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _auth.authenticatedGet('/learning/stats');
    if (response.statusCode != 200) throw Exception('Failed to load stats');
    return jsonDecode(response.body);
  }
}
