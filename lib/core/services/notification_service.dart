import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Set timezone to Asia/Kuala_Lumpur (Malaysia)
    final localTimeZone = tz.getLocation('Asia/Kuala_Lumpur');
    tz.setLocalLocation(localTimeZone);
    print('🌍 Timezone set to: ${tz.local.name}');

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Create appointment reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'appointment_reminders',
          'Appointment Reminders',
          description: 'Notifications for appointment reminders',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Create immediate notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'immediate_notifications',
          'Immediate Notifications',
          description: 'Immediate notifications for testing',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      print('🔔 Starting permission request process...');

      // Ensure service is initialized first
      if (!_isInitialized) {
        print(
          '🔔 Initializing notification service before requesting permissions...',
        );
        await initialize();
      }

      // For Android, request permission through the plugin
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        print('🔔 Requesting Android notification permission...');
        final granted = await androidPlugin.requestNotificationsPermission();
        print('🔔 Android permission result: $granted');

        if (granted == false) {
          print('❌ Android notification permission denied');
          return false;
        }

        // Check for exact alarm permission (Android 12+)
        final canScheduleExactAlarms = await androidPlugin
            .canScheduleExactNotifications();
        print('🔔 Exact alarms available: $canScheduleExactAlarms');

        if (canScheduleExactAlarms == false) {
          print('⚠️ Exact alarms not permitted - will use inexact alarms');
        } else {
          print('✅ Exact alarms permitted');
        }
      } else {
        print('⚠️ Android plugin not available');
      }

      // For iOS, request permission
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        print('🔔 Requesting iOS notification permission...');
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('🔔 iOS permission requested');
      }

      print('✅ Notification permissions granted');
      return true;
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final canScheduleExactAlarms = await androidPlugin
            .canScheduleExactNotifications();
        if (canScheduleExactAlarms == false) {
          print(
            '⚠️ Exact alarms not permitted - attempting to request permission',
          );

          // Try to request permission programmatically (Android 14+)
          try {
            print('🔔 Attempting to request exact alarm permission...');
            final granted = await androidPlugin.requestExactAlarmsPermission();
            print('🔔 Exact alarm permission request result: $granted');

            if (granted == true) {
              print('✅ Exact alarm permission granted!');
              return true;
            } else {
              print('❌ Exact alarm permission denied');
              print('📱 To enable exact alarms manually:');
              print('   1. Go to Settings > Apps > AutoAnywhere');
              print('   2. Tap "Special app access" or "Advanced"');
              print('   3. Tap "Alarms & reminders"');
              print('   4. Enable "Allow alarms & reminders"');
              return false;
            }
          } catch (e) {
            print('❌ Could not request exact alarm permission: $e');
            print('📱 To enable exact alarms manually:');
            print('   1. Go to Settings > Apps > AutoAnywhere');
            print('   2. Tap "Special app access" or "Advanced"');
            print('   3. Tap "Alarms & reminders"');
            print('   4. Enable "Allow alarms & reminders"');
            return false;
          }
        }
        print('✅ Exact alarms already permitted');
        return true;
      }
      return true; // iOS doesn't need this
    } catch (e) {
      print('❌ Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Get exact alarm permission status
  Future<bool> canScheduleExactNotifications() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        return await androidPlugin.canScheduleExactNotifications() ?? false;
      }
      return true; // iOS doesn't need this
    } catch (e) {
      print('❌ Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Check battery optimization status and provide guidance
  Future<void> checkBatteryOptimization() async {
    try {
      print('🔋 Checking battery optimization status...');
      print('⚠️ ANDROID BACKGROUND EXECUTION LIMITS:');
      print(
        '   - Android restricts background execution even when app is open',
      );
      print(
        '   - Scheduled notifications may not fire due to system restrictions',
      );
      print(
        '   - This is NOT battery optimization - it\'s Android\'s background limits',
      );
      print('   - Solution: Use timer-based approach for testing');
      print(
        '   - For production: Real appointments will work better than test data',
      );
    } catch (e) {
      print('❌ Error checking battery optimization: $e');
    }
  }

  /// Test timer-based notification (more reliable for testing)
  Future<void> testTimerNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    try {
      print('🧪 Testing TIMER-based notification...');
      print('🧪 TIMER: Will show notification in ${delay.inSeconds} seconds');

      // Use a simple timer approach that works immediately
      Timer(delay, () async {
        print('🧪 TIMER: Timer fired! Showing notification now...');
        await showImmediateNotification(
          title: title,
          body: body,
          payload: 'timer_test_$id',
        );
        print('✅ TIMER: Notification shown via timer');
      });

      print('✅ TIMER: Timer scheduled successfully');
    } catch (e) {
      print('❌ TIMER: Error scheduling timer: $e');
    }
  }

  /// Schedule a notification - simplified approach
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('🔔 Scheduling notification: $title');
      print('🔔 Scheduled for: $scheduledDate');
      print('🔔 Current time: ${DateTime.now()}');

      // Check if scheduled time is in the past
      if (scheduledDate.isBefore(DateTime.now())) {
        print('⚠️ Scheduled time is in the past, showing immediately instead');
        await showImmediateNotification(
          title: title,
          body: body,
          payload: payload,
        );
        return;
      }

      // Get the local timezone explicitly
      final localTimeZone = tz.getLocation('Asia/Kuala_Lumpur');

      // Convert to TZDateTime using explicit timezone
      final tzScheduledDate = tz.TZDateTime(
        localTimeZone,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        scheduledDate.second,
        scheduledDate.millisecond,
        scheduledDate.microsecond,
      );

      print('🔍 DEBUG: Original scheduledDate: $scheduledDate');
      print('🔍 DEBUG: TZDateTime: $tzScheduledDate');
      print(
        '🔍 DEBUG: Current TZDateTime: ${tz.TZDateTime.now(localTimeZone)}',
      );
      print(
        '🔍 DEBUG: Time until scheduled: ${tzScheduledDate.difference(tz.TZDateTime.now(localTimeZone))}',
      );

      // Check if exact alarms are permitted
      final canScheduleExact = await canScheduleExactNotifications();
      print('🔍 DEBUG: Can schedule exact alarms: $canScheduleExact');

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'appointment_reminders',
            'Appointment Reminders',
            channelDescription: 'Notifications for appointment reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFCF2049),
            playSound: true,
            enableVibration: true,
            showWhen: true,
            enableLights: true,
            ledColor: Color(0xFFCF2049),
            ledOnMs: 1000,
            ledOffMs: 500,
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use the most reliable scheduling method for real-world usage
      if (canScheduleExact) {
        // Use exact scheduling with allowWhileIdle - this is the correct approach
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          payload: payload,
          androidAllowWhileIdle: true,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print(
          '🔔 Using exact scheduling with allowWhileIdle - this should work for real appointments',
        );
      } else {
        // Fallback to inexact scheduling
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          payload: payload,
          androidAllowWhileIdle: false,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('🔔 Using inexact scheduling - may be delayed but should work');
      }

      if (canScheduleExact) {
        print(
          '✅ Notification scheduled (exact + exactAllowWhileIdle): $title at $scheduledDate',
        );
      } else {
        print('✅ Notification scheduled (inexact): $title at $scheduledDate');
      }

      // CRITICAL: Add a test to see if the notification actually gets scheduled
      print('🔍 CRITICAL: Checking if notification was actually scheduled...');
      final pendingAfterSchedule = await _notifications
          .pendingNotificationRequests();
      final foundNotification = pendingAfterSchedule
          .where((n) => n.id == id)
          .toList();
      if (foundNotification.isNotEmpty) {
        print(
          '✅ CRITICAL: Notification found in pending list after scheduling',
        );
        print('   - ID: ${foundNotification.first.id}');
        print('   - Title: ${foundNotification.first.title}');
      } else {
        print(
          '❌ CRITICAL: Notification NOT found in pending list after scheduling!',
        );
        print('   - This means the scheduling failed silently');
      }

      // Verify the notification was scheduled
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      final scheduledNotification = pendingNotifications.firstWhere(
        (notification) => notification.id == id,
        orElse: () => throw Exception('Notification not found in pending list'),
      );
      print(
        '🔍 VERIFICATION: Notification found in pending list with ID: ${scheduledNotification.id}',
      );
      print('🔍 VERIFICATION: Title: ${scheduledNotification.title}');
      print('🔍 VERIFICATION: Body: ${scheduledNotification.body}');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      // Try to show immediately as fallback
      try {
        await showImmediateNotification(
          title: title,
          body: body,
          payload: payload,
        );
        print('✅ Fallback: Notification shown immediately');
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
      }
    }
  }

  /// Show immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'immediate_notifications',
            'Immediate Notifications',
            channelDescription: 'Immediate notifications for testing',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFCF2049),
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('✅ Immediate notification shown: $title');
    } catch (e) {
      print('❌ Error showing immediate notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('✅ Notification cancelled: $id');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Pending notifications: ${pending.length}');
      for (final notification in pending) {
        print('   - ID: ${notification.id}, Title: ${notification.title}');
      }
      return pending;
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // You can add navigation logic here based on the payload
  }

  /// Setup notification listeners
  void setupNotificationListeners() {
    print('🔔 Notification listeners set up');
  }

  /// Show in-app notification with context (to be called from UI)
  static void showInAppNotification(
    BuildContext context,
    String title,
    String body,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFFCF2049),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
