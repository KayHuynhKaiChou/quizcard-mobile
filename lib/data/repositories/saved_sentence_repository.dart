import 'dart:convert';

import 'package:quizcard_mobile/data/models/page_response.dart';
import 'package:quizcard_mobile/data/models/sentence_models.dart';
import 'package:quizcard_mobile/data/services/auth_service.dart';

/// Repository for the standalone saved-sentences store.
class SavedSentenceRepository {
  final AuthService _authService;

  SavedSentenceRepository(this._authService);

  Future<PageResponse<SavedSentence>> getSaved({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _authService.authenticatedGet(
      '/saved-sentences',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load saved sentences');
    }
    return PageResponse<SavedSentence>.fromJson(
      json.decode(response.body),
      SavedSentence.fromJson,
    );
  }

  /// Bulk save of the sentences ticked in the picker sheet.
  Future<void> saveAll(List<AiSentence> sentences) async {
    final response = await _authService.authenticatedPost(
      '/saved-sentences',
      body: {'sentences': sentences.map((s) => s.toJson()).toList()},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save sentences');
    }
  }

  Future<void> delete(String id) async {
    final response = await _authService.authenticatedDelete('/saved-sentences/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete sentence');
    }
  }
}
