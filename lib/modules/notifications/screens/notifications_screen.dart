import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      final notifications = pendingNotifications
          .map(
            (notification) => {
              'id': notification.id,
              'title': notification.title ?? 'Notification',
              'body': notification.body ?? '',
              'payload': notification.payload ?? '',
            },
          )
          .toList();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to load notifications: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      await _loadNotifications();
      _showSuccessMessage('All notifications cleared');
    } catch (e) {
      _showErrorMessage('Failed to clear notifications: $e');
    }
  }

  Future<void> _clearNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);
      await _loadNotifications();
      _showSuccessMessage('Notification cleared');
    } catch (e) {
      _showErrorMessage('Failed to clear notification: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF2049),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final id = notification['id'] as int;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final payload = notification['payload'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFCF2049),
          child: Icon(_getNotificationIcon(payload), color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            if (payload.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _getNotificationType(payload),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => _clearNotification(id),
          tooltip: 'Clear notification',
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getNotificationIcon(String payload) {
    if (payload.startsWith('booking_')) {
      return Icons.calendar_today;
    } else if (payload.startsWith('reminder_')) {
      return Icons.schedule;
    } else if (payload == 'test') {
      return Icons.bug_report;
    }
    return Icons.notifications;
  }

  String _getNotificationType(String payload) {
    if (payload.startsWith('booking_')) {
      return 'Appointment Booking';
    } else if (payload.startsWith('reminder_')) {
      return 'Appointment Reminder';
    } else if (payload == 'test') {
      return 'Test Notification';
    }
    return 'Notification';
  }
}
