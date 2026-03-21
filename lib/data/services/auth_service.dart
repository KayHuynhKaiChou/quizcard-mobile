import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/user_model.dart';

/// Manages JWT authentication: login, register, token storage, auto-refresh.
class AuthService extends ChangeNotifier {
  AuthService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'QUIZCARD_API_BASE_URL',
              defaultValue: 'http://localhost:8081/api',
            );

  final http.Client _client;
  final String _baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  UserModel? _user;
  String? _accessToken;
  bool _loading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _accessToken != null && _user != null;
  bool get loading => _loading;
  String? get accessToken => _accessToken;

  /// Try to restore session from stored tokens on app startup.
  Future<bool> tryAutoLogin() async {
    _accessToken = await _storage.read(key: _keyAccessToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (_accessToken == null) return false;

    try {
      _user = await _fetchCurrentUser();
      notifyListeners();
      return true;
    } catch (_) {
      // Access token expired → try refresh
      if (refreshToken != null) {
        try {
          await _refreshTokens(refreshToken);
          _user = await _fetchCurrentUser();
          notifyListeners();
          return true;
        } catch (_) {
          await _clearTokens();
          return false;
        }
      }
      await _clearTokens();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Login failed');
      }
      final auth = AuthResponse.fromJson(jsonDecode(response.body));
      await _saveTokens(auth.accessToken, auth.refreshToken);
      _accessToken = auth.accessToken;
      _user = auth.user;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );
      if (response.statusCode != 201) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Registration failed');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Request failed');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Reset failed');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await authenticatedPost('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to change password');
    }
  }

  Future<void> resendVerification(String email) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Resend failed');
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken != null) {
      try {
        await _client.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      } catch (_) {
        // Ignore logout API errors
      }
    }
    await _clearTokens();
    _user = null;
    _accessToken = null;
    notifyListeners();
  }

  /// Returns auth headers for use by other services.
  Map<String, String> get authHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Makes an authenticated GET request with auto-refresh on 401.
  Future<http.Response> authenticatedGet(String path,
      {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null) uri = uri.replace(queryParameters: queryParams);
    var response = await _client.get(uri, headers: authHeaders);
    if (response.statusCode == 401) {
      await _tryRefresh();
      response = await _client.get(uri, headers: authHeaders);
    }
    return response;
  }

  /// Makes an authenticated POST request with auto-refresh on 401.
  Future<http.Response> authenticatedPost(String path,
      {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final encoded = body != null ? jsonEncode(body) : null;
    var response =
        await _client.post(uri, headers: authHeaders, body: encoded);
    if (response.statusCode == 401) {
      await _tryRefresh();
      response =
          await _client.post(uri, headers: authHeaders, body: encoded);
    }
    return response;
  }

  /// Makes an authenticated PUT request with auto-refresh on 401.
  Future<http.Response> authenticatedPut(String path,
      {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final encoded = body != null ? jsonEncode(body) : null;
    var response =
        await _client.put(uri, headers: authHeaders, body: encoded);
    if (response.statusCode == 401) {
      await _tryRefresh();
      response =
          await _client.put(uri, headers: authHeaders, body: encoded);
    }
    return response;
  }

  /// Makes an authenticated multipart POST request (for file uploads).
  Future<http.Response> authenticatedMultipartPost(
    String path, {
    required String fieldName,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: fileName,
      contentType: MediaType.parse(mimeType),
    ));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 401) {
      await _tryRefresh();
      request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_accessToken';
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ));
      streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    }
    return response;
  }

  /// Updates the cached user model and notifies listeners.
  Future<void> updateUser(UserModel user) async {
    _user = user;
    notifyListeners();
  }

  /// Makes an authenticated DELETE request with auto-refresh on 401.
  Future<http.Response> authenticatedDelete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    var response = await _client.delete(uri, headers: authHeaders);
    if (response.statusCode == 401) {
      await _tryRefresh();
      response = await _client.delete(uri, headers: authHeaders);
    }
    return response;
  }

  // ─── Private helpers ───

  Future<UserModel> _fetchCurrentUser() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: authHeaders,
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch user');
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<void> _tryRefresh() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken == null) throw Exception('No refresh token');
    await _refreshTokens(refreshToken);
  }

  Future<void> _refreshTokens(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode != 200) throw Exception('Refresh failed');
    final auth = AuthResponse.fromJson(jsonDecode(response.body));
    await _saveTokens(auth.accessToken, auth.refreshToken);
    _accessToken = auth.accessToken;
    _user = auth.user;
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: _keyAccessToken, value: access);
    await _storage.write(key: _keyRefreshToken, value: refresh);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
