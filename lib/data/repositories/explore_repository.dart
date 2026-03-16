import '../models/page_response.dart';
import '../models/study_set_summary.dart';
import '../services/quizcard_api_service.dart';

class ExploreRepository {
  ExploreRepository({QuizcardApiService? apiService})
      : _apiService = apiService ?? QuizcardApiService();

  final QuizcardApiService _apiService;

  Future<PageResponse<StudySetSummary>> loadTrending({
    int page = 0,
    int size = 20,
    String? category,
  }) {
    return _apiService.getTrending(page: page, size: size, category: category);
  }

  Future<PageResponse<StudySetSummary>> loadRecent({
    int page = 0,
    int size = 20,
  }) {
    return _apiService.getRecent(page: page, size: size);
  }

  Future<PageResponse<StudySetSummary>> searchStudySets({
    required String query,
    int page = 0,
    int size = 20,
  }) {
    return _apiService.searchStudySets(query: query, page: page, size: size);
  }

  Future<List<String>> loadCategories() {
    return _apiService.getCategories();
  }
}
