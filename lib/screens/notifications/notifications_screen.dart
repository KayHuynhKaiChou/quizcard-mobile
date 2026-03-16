import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification_model.dart';
import '../../data/models/page_response.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationRepository _repo;
  late Future<PageResponse<AppNotification>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = NotificationRepository(context.read<AuthService>());
    _future = _repo.getNotifications();
  }

  void _refresh() => setState(() => _future = _repo.getNotifications());

  Future<void> _markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      _refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: mark all as read
            },
            child: const Text('Mark All Read',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: FutureBuilder<PageResponse<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      color: AppTheme.textSecondaryColor, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load notifications'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final items = snapshot.data?.content ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                      size: 64),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _NotificationCard(
                notification: items[index],
                onRead: () => _markAsRead(items[index].id),
              ).animate(delay: Duration(milliseconds: 40 * index))
                  .fadeIn()
                  .slideX(begin: 0.03);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onRead;

  const _NotificationCard({required this.notification, required this.onRead});

  IconData get _icon {
    switch (notification.type.toUpperCase()) {
      case 'REMINDER':
        return Icons.notifications_active_outlined;
      case 'ACHIEVEMENT':
        return Icons.emoji_events_outlined;
      case 'STUDY':
        return Icons.menu_book_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color get _iconColor {
    switch (notification.type.toUpperCase()) {
      case 'REMINDER':
        return AppTheme.primaryColor;
      case 'ACHIEVEMENT':
        return const Color(0xFFF59E0B);
      case 'STUDY':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onRead,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title,
                        style: TextStyle(
                            fontWeight: notification.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(notification.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(notification.timeAgo,
                        style: const TextStyle(
                            color: AppTheme.textSecondaryColor, fontSize: 12)),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
