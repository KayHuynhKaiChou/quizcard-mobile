import 'dart:convert';

import '../models/user_model.dart';
import '../models/page_response.dart';
import '../models/study_set_summary.dart';
import '../services/auth_service.dart';

class UserRepository {
  final AuthService _auth;
  UserRepository(this._auth);

  Future<UserModel> getMe() async {
    final response = await _auth.authenticatedGet('/users/me');
    if (response.statusCode != 200) throw Exception('Failed to load profile');
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> updateMe({
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
  }) async {
    final response = await _auth.authenticatedPut('/users/me', body: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    if (response.statusCode != 200) throw Exception('Failed to update profile');
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<PageResponse<StudySetSummary>> getBookmarks({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _auth.authenticatedGet(
      '/users/me/bookmarks',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );
    if (response.statusCode != 200) throw Exception('Failed to load bookmarks');
    return PageResponse<StudySetSummary>.fromJson(
      jsonDecode(response.body),
      StudySetSummary.fromJson,
    );
  }

  Future<UserModel> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final response = await _auth.authenticatedMultipartPost(
      '/users/me/avatar',
      fieldName: 'file',
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    if (response.statusCode != 200) throw Exception('Failed to upload avatar');
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _auth.authenticatedGet('/users/$userId/profile');
    if (response.statusCode != 200) throw Exception('Failed to load profile');
    return jsonDecode(response.body);
  }
}
