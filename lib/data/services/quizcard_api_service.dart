import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/page_response.dart';
import '../models/study_set_summary.dart';

class QuizcardApiService {
  QuizcardApiService({
    http.Client? client,
    String? baseUrl,
    String? accessToken,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment(
          'QUIZCARD_API_BASE_URL',
          defaultValue: 'http://localhost:8081/api',
        ),
        _accessToken = accessToken ??
            const String.fromEnvironment('QUIZCARD_API_TOKEN');

  final http.Client _client;
  final String _baseUrl;
  final String _accessToken;

  Future<PageResponse<StudySetSummary>> getTrending({
    int page = 0,
    int size = 20,
    String? category,
  }) {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (category != null && category.trim().isNotEmpty) 'category': category,
    };
    return _getStudySetPage('/explore/trending', params);
  }

  Future<PageResponse<StudySetSummary>> getRecent({
    int page = 0,
    int size = 20,
  }) {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    return _getStudySetPage('/explore/recent', params);
  }

  Future<PageResponse<StudySetSummary>> searchStudySets({
    required String query,
    int page = 0,
    int size = 20,
  }) {
    final params = <String, String>{
      'q': query,
      'page': page.toString(),
      'size': size.toString(),
    };
    return _getStudySetPage('/explore/search', params);
  }

  Future<List<String>> getCategories() async {
    final uri =
        Uri.parse('$_baseUrl/explore/categories').replace(queryParameters: {});
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load categories (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded.map((e) => e.toString()).toList();
  }

  Future<PageResponse<StudySetSummary>> _getStudySetPage(
    String path,
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);

    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response payload');
    }

    return PageResponse<StudySetSummary>.fromJson(
      decoded,
      StudySetSummary.fromJson,
    );
  }

  Map<String, String> get _headers {
    if (_accessToken.trim().isEmpty) {
      return const {'Accept': 'application/json'};
    }
    return <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }
}
