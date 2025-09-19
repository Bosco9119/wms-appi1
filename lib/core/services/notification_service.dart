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

  /// Schedule a notification - using timer-based approach for reliability
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
      print('🔔 Time difference: ${scheduledDate.difference(DateTime.now())}');
      print('🔔 Time difference in hours: ${scheduledDate.difference(DateTime.now()).inHours}');

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

      // Use timer-based scheduling for better reliability
      final delay = scheduledDate.difference(DateTime.now());
      print('🔔 Using timer-based scheduling with delay: ${delay.inMinutes} minutes');
      
      // Store the notification info for later use
      _scheduledNotifications[id] = {
        'title': title,
        'body': body,
        'payload': payload,
        'scheduledDate': scheduledDate,
      };
      
      // Use Timer for more reliable scheduling
      Timer(delay, () async {
        print('🔔 Timer fired for notification: $title');
        print('🔔 Scheduled time was: $scheduledDate');
        print('🔔 Current time is: ${DateTime.now()}');
        
        // Remove from scheduled notifications
        _scheduledNotifications.remove(id);
        
        // Show the notification
        await showImmediateNotification(
          title: title,
          body: body,
          payload: payload,
        );
        
        print('✅ Timer-based notification shown: $title');
      });
      
      print('✅ Notification scheduled with timer (ID: $id)');
      print('✅ Will show in ${delay.inMinutes} minutes');
      
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

  // Store scheduled notifications for tracking
  final Map<int, Map<String, dynamic>> _scheduledNotifications = {};

  /// Show immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      print('🔔 showImmediateNotification called with title: $title');
      
      if (!_isInitialized) {
        print('🔔 Service not initialized, initializing now...');
        await initialize();
      }

      print('🔔 Creating notification details...');
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

      print('🔔 Calling _notifications.show...');
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('🔔 Notification ID: $notificationId');
      
      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('✅ Immediate notification shown successfully: $title');
      print('✅ Notification ID: $notificationId');
      
      // Verify the notification was actually shown
      final pending = await _notifications.pendingNotificationRequests();
      print('🔍 Pending notifications after show: ${pending.length}');
      
    } catch (e) {
      print('❌ Error showing immediate notification: $e');
      print('❌ Error details: ${e.toString()}');
      print('❌ Stack trace: ${StackTrace.current}');
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

  /// Cancel only scheduled/future notifications (not immediate ones)
  Future<void> cancelScheduledNotifications() async {
    try {
      final pending = await getPendingNotifications();
      int cancelledCount = 0;
      
      for (final notification in pending) {
        // Cancel all scheduled notifications (they have IDs > 1000 typically)
        if (notification.id > 1000) {
          await cancelNotification(notification.id);
          cancelledCount++;
        }
      }
      
      print('✅ Cancelled $cancelledCount scheduled notifications');
    } catch (e) {
      print('❌ Error cancelling scheduled notifications: $e');
    }
  }

  /// Cancel notifications for a specific booking
  Future<void> cancelBookingNotifications(String bookingId) async {
    try {
      final pending = await getPendingNotifications();
      int cancelledCount = 0;
      
      for (final notification in pending) {
        final payload = notification.payload ?? '';
        if (payload.contains(bookingId)) {
          await cancelNotification(notification.id);
          cancelledCount++;
        }
      }
      
      print('✅ Cancelled $cancelledCount notifications for booking: $bookingId');
    } catch (e) {
      print('❌ Error cancelling booking notifications: $e');
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

  /// Get scheduled notifications (timer-based)
  Map<int, Map<String, dynamic>> getScheduledNotifications() {
    print('📋 Scheduled notifications (timer-based): ${_scheduledNotifications.length}');
    for (final entry in _scheduledNotifications.entries) {
      print('   - ID: ${entry.key}, Title: ${entry.value['title']}');
      print('     Scheduled for: ${entry.value['scheduledDate']}');
    }
    return _scheduledNotifications;
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
