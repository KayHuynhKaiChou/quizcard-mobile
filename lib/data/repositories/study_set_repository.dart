import 'dart:convert';

import '../models/page_response.dart';
import '../models/study_set_models.dart';
import '../models/study_set_summary.dart';
import '../services/auth_service.dart';

class StudySetRepository {
  final AuthService _auth;
  StudySetRepository(this._auth);

  Future<PageResponse<StudySetSummary>> getMyStudySets({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _auth.authenticatedGet(
      '/study-sets',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load study sets');
    }
    return PageResponse<StudySetSummary>.fromJson(
      jsonDecode(response.body),
      StudySetSummary.fromJson,
    );
  }

  Future<StudySetDetail> getById(String id) async {
    final response = await _auth.authenticatedGet('/study-sets/$id');
    if (response.statusCode != 200) throw Exception('Failed to load study set');
    return StudySetDetail.fromJson(jsonDecode(response.body));
  }

  Future<CursorPage<Term>> getTerms(String studySetId,
      {int? cursor, int limit = 20}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor.toString(),
    };
    final response =
        await _auth.authenticatedGet('/study-sets/$studySetId/terms', queryParams: params);
    if (response.statusCode != 200) throw Exception('Failed to load terms');
    return CursorPage<Term>.fromJson(jsonDecode(response.body), Term.fromJson);
  }

  Future<StudySetDetail> create({
    required String title,
    String? description,
    String? category,
    String visibility = 'PUBLIC',
    List<Map<String, dynamic>> terms = const [],
  }) async {
    final response = await _auth.authenticatedPost('/study-sets', body: {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'visibility': visibility,
      'terms': terms,
    });
    if (response.statusCode != 201) throw Exception('Failed to create study set');
    return StudySetDetail.fromJson(jsonDecode(response.body));
  }

  Future<StudySetDetail> update(String id, {
    required String title,
    String? description,
    String? category,
    String visibility = 'PUBLIC',
  }) async {
    final response = await _auth.authenticatedPut('/study-sets/$id', body: {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'visibility': visibility,
    });
    if (response.statusCode != 200) throw Exception('Failed to update study set');
    return StudySetDetail.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(String id) async {
    final response = await _auth.authenticatedDelete('/study-sets/$id');
    if (response.statusCode != 204) throw Exception('Failed to delete study set');
  }

  Future<void> bookmark(String id) async {
    await _auth.authenticatedPost('/study-sets/$id/bookmark');
  }

  Future<void> unbookmark(String id) async {
    await _auth.authenticatedDelete('/study-sets/$id/bookmark');
  }

  Future<void> rate(String id, int rating) async {
    await _auth.authenticatedPost('/study-sets/$id/rate', body: {'rating': rating});
  }

  // Term CRUD
  Future<Term> addTerm(String studySetId, {
    required String term,
    required String definition,
    String? exampleSentence,
    String? imageUrl,
  }) async {
    final response = await _auth.authenticatedPost('/study-sets/$studySetId/terms', body: {
      'term': term,
      'definition': definition,
      if (exampleSentence != null) 'exampleSentence': exampleSentence,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    if (response.statusCode != 201) throw Exception('Failed to add term');
    return Term.fromJson(jsonDecode(response.body));
  }

  Future<Term> updateTerm(String termId, {
    required String term,
    required String definition,
    String? exampleSentence,
    String? imageUrl,
  }) async {
    final response = await _auth.authenticatedPut('/terms/$termId', body: {
      'term': term,
      'definition': definition,
      if (exampleSentence != null) 'exampleSentence': exampleSentence,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    if (response.statusCode != 200) throw Exception('Failed to update term');
    return Term.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteTerm(String termId) async {
    final response = await _auth.authenticatedDelete('/terms/$termId');
    if (response.statusCode != 204) throw Exception('Failed to delete term');
  }
}
