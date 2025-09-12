import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/notification_settings_service.dart';
import '../../../core/services/reminder_scheduler.dart';
import '../../../shared/models/notification_preferences_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  NotificationPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preferences = await _settingsService.getPreferences();
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to load notification settings');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      await _settingsService.toggleNotifications(enabled);
      await _loadPreferences();
      _showSuccessMessage(
        enabled ? 'Notifications enabled' : 'Notifications disabled',
      );
    } catch (e) {
      _showErrorMessage('Failed to update notification settings');
    }
  }

  Future<void> _addReminderInterval(ReminderInterval interval) async {
    try {
      final success = await _settingsService.addReminderInterval(interval);
      if (success) {
        await _loadPreferences();
        _showSuccessMessage('Reminder added: ${interval.displayName}');
      } else {
        _showErrorMessage('Cannot add more reminders (maximum 6)');
      }
    } catch (e) {
      _showErrorMessage('Failed to add reminder');
    }
  }

  Future<void> _removeReminderInterval(String intervalId) async {
    try {
      final success = await _settingsService.removeReminderInterval(intervalId);
      if (success) {
        await _loadPreferences();
        _showSuccessMessage('Reminder removed');
      } else {
        _showErrorMessage('Cannot remove the last reminder');
      }
    } catch (e) {
      _showErrorMessage('Failed to remove reminder');
    }
  }

  Future<void> _toggleReminderInterval(String intervalId, bool enabled) async {
    try {
      await _settingsService.toggleReminderInterval(intervalId, enabled);
      await _loadPreferences();
    } catch (e) {
      _showErrorMessage('Failed to update reminder');
    }
  }

  Future<void> _testNotificationSystem() async {
    try {
      final reminderScheduler = ReminderScheduler();
      await reminderScheduler.testRealAppointmentScheduling();
      _showSuccessMessage(
        'REAL appointment scheduling test started! Notifications will appear at 5s, 30s, and 2min - this tests production-ready scheduling.',
      );
    } catch (e) {
      _showErrorMessage('Failed to create test appointment: $e');
    }
  }

  Future<void> _checkPendingNotifications() async {
    try {
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      final count = pendingNotifications.length;
      _showSuccessMessage(
        'Found $count pending notifications. Check console for details.',
      );
      print('📋 Pending notifications: $count');
      for (final notification in pendingNotifications) {
        print('   - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      _showErrorMessage('Failed to check pending notifications: $e');
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
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
          ? const Center(child: Text('Failed to load settings'))
          : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main notification toggle
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.notifications,
                color: Color(0xFFCF2049),
              ),
              title: const Text(
                'Appointment Reminders',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Receive notifications for your appointments',
              ),
              trailing: Switch(
                value: _preferences!.isEnabled,
                onChanged: _toggleNotifications,
                activeColor: const Color(0xFFCF2049),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reminder intervals section
          if (_preferences!.isEnabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reminder Times',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_preferences!.reminderIntervals.length < 6)
                          TextButton.icon(
                            onPressed: _showAddReminderDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFCF2049),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can have up to 6 reminder times',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ..._buildReminderIntervals(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test notification
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.schedule,
                      color: Color(0xFFCF2049),
                    ),
                    title: const Text('Test REAL Notification System'),
                    subtitle: const Text(
                      'Test production-ready scheduling (5s, 30s, 2min delays)',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _testNotificationSystem,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.list, color: Color(0xFFCF2049)),
                    title: const Text('Check Pending Notifications'),
                    subtitle: const Text('View all scheduled notifications'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _checkPendingNotifications,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Disabled state
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notifications are disabled',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable notifications above to manage reminder times',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildReminderIntervals() {
    return _preferences!.reminderIntervals.map((interval) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            interval.isEnabled ? Icons.schedule : Icons.schedule_outlined,
            color: interval.isEnabled ? const Color(0xFFCF2049) : Colors.grey,
          ),
          title: Text(
            interval.displayName,
            style: TextStyle(color: interval.isEnabled ? null : Colors.grey),
          ),
          subtitle: Text(
            interval.isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              color: interval.isEnabled ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: interval.isEnabled,
                onChanged: (enabled) =>
                    _toggleReminderInterval(interval.id, enabled),
                activeColor: const Color(0xFFCF2049),
              ),
              if (_preferences!.reminderIntervals.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeReminderInterval(interval.id),
                  tooltip: 'Remove reminder',
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _showAddReminderDialog() async {
    final availableIntervals = await _settingsService.getAvailableIntervals();

    if (availableIntervals.isEmpty) {
      _showErrorMessage('No more reminder times available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableIntervals.map((interval) {
            return ListTile(
              title: Text(interval.displayName),
              onTap: () {
                Navigator.of(context).pop();
                _addReminderInterval(interval);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
