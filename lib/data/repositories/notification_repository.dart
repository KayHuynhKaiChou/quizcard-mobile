import 'dart:convert';

import '../models/notification_model.dart';
import '../models/page_response.dart';
import '../services/auth_service.dart';

class NotificationRepository {
  final AuthService _auth;
  NotificationRepository(this._auth);

  Future<PageResponse<AppNotification>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _auth.authenticatedGet(
      '/notifications',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications');
    }
    return PageResponse<AppNotification>.fromJson(
      jsonDecode(response.body),
      AppNotification.fromJson,
    );
  }

  Future<void> markAsRead(String id) async {
    final response = await _auth.authenticatedPut('/notifications/$id/read');
    if (response.statusCode != 200) {
      throw Exception('Failed to mark as read');
    }
  }
}
