import 'dart:convert';

import 'package:quizcard_mobile/data/services/auth_service.dart';

/// Repository for AI-powered features: generate terms, extract from text, usage.
class AiRepository {
  final AuthService _authService;

  AiRepository(this._authService);

  /// Fetch AI usage stats for the current user.
  Future<Map<String, dynamic>> getUsage() async {
    final response = await _authService.authenticatedGet('/ai/usage');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch AI usage');
  }

  /// Generate a list of term/definition pairs based on a topic.
  Future<List<Map<String, dynamic>>> generateTerms({
    required String topic,
    required int count,
    String language = 'vi',
  }) async {
    final response = await _authService.authenticatedPost(
      '/ai/generate-terms',
      body: {
        'topic': topic,
        'count': count,
        'language': language,
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['terms'] ?? data);
    }
    throw Exception('Failed to generate terms');
  }

  /// Extract term/definition pairs from a block of text.
  Future<List<Map<String, dynamic>>> extractFromText({
    required String text,
  }) async {
    final response = await _authService.authenticatedPost(
      '/ai/extract-from-text',
      body: {'text': text},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['terms'] ?? data);
    }
    throw Exception('Failed to extract terms');
  }
}
