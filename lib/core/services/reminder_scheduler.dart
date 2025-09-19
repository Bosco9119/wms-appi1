import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../../shared/models/booking_model.dart';

class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal();

  final NotificationService _notificationService = NotificationService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  /// Schedule all reminders for a booking
  Future<void> scheduleBookingReminders(Booking booking) async {
    try {
      // Initialize notification service
      await _notificationService.initialize();

      // Request permissions
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        print('❌ Cannot schedule reminders: Notification permission denied');
        return;
      }

      // Check if user has notifications enabled
      final notificationsEnabled = await _settingsService
          .areNotificationsEnabled();
      if (!notificationsEnabled) {
        print('❌ Cannot schedule reminders: Notifications disabled by user');
        return;
      }

      // Parse booking date and time
      final bookingDate = DateTime.parse(booking.date);
      print('🔍 DEBUG: Raw booking date: ${booking.date}');
      print('🔍 DEBUG: Parsed booking date: $bookingDate');
      print('🔍 DEBUG: Raw timeSlot: ${booking.timeSlot}');
      
      final timeParts = booking.timeSlot.split('-')[0].split(':');
      print('🔍 DEBUG: Time parts: $timeParts');
      
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      print('🔍 DEBUG: Current time: ${DateTime.now()}');
      print('🔍 DEBUG: Booking time: $bookingDateTime');
      print('🔍 DEBUG: Time difference: ${bookingDateTime.difference(DateTime.now())}');
      print('🔍 DEBUG: Time difference in hours: ${bookingDateTime.difference(DateTime.now()).inHours}');

      // Schedule immediate confirmation notification
      await _scheduleConfirmationReminder(booking, bookingDateTime);

      // Schedule user-configured reminders
      await _scheduleUserReminders(booking, bookingDateTime);

      print('✅ All reminders scheduled for booking: ${booking.id}');
    } catch (e) {
      print('❌ Error scheduling reminders: $e');
    }
  }

  /// Schedule immediate confirmation reminder
  Future<void> _scheduleConfirmationReminder(
    Booking booking,
    DateTime bookingDateTime,
  ) async {
    final title = 'Appointment Confirmed! 🎉';
    final body =
        'Your appointment with ${booking.shopName} is confirmed for ${_formatDateTime(bookingDateTime)}';
    final payload = 'booking_confirmation:${booking.id}';

    // Show immediate notification instead of scheduling
    await _notificationService.showImmediateNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Schedule user-configured reminders
  Future<void> _scheduleUserReminders(
    Booking booking,
    DateTime bookingDateTime,
  ) async {
    try {
      print('🔔 Scheduling reminders for booking from database:');
      print('   📅 Booking ID: ${booking.id}');
      print('   🏪 Shop: ${booking.shopName}');
      print('   📅 Date: ${booking.date}');
      print('   ⏰ Time: ${booking.timeSlot}');
      print('   🕐 Calculated DateTime: ${bookingDateTime.toString()}');

      final enabledIntervals = await _settingsService
          .getEnabledReminderIntervals();

      print(
        '   ⚙️ Enabled reminder intervals: ${enabledIntervals.map((i) => i.displayName).join(', ')}',
      );
      print('   📊 Total enabled intervals: ${enabledIntervals.length}');
      for (final interval in enabledIntervals) {
        print(
          '      - ${interval.id}: ${interval.displayName} (${interval.isEnabled ? "ON" : "OFF"})',
        );
      }
      
      if (enabledIntervals.isEmpty) {
        print('   ⚠️ WARNING: No reminder intervals are enabled!');
        print('   This means no reminders will be scheduled.');
        return;
      }

      for (final interval in enabledIntervals) {
        final reminderTime = bookingDateTime.subtract(interval.duration);
        final timeUntilReminder = reminderTime.difference(DateTime.now());
        
        print('   ⏰ ${interval.displayName} reminder:');
        print('      Calculated time: ${reminderTime.toString()}');
        print('      Time until reminder: ${timeUntilReminder.inHours}h ${timeUntilReminder.inMinutes % 60}m');
        print('      Is in future: ${reminderTime.isAfter(DateTime.now())}');

        // Only schedule if the reminder time is in the future AND at least 1 minute from now
        final minimumTime = DateTime.now().add(Duration(minutes: 1));
        if (reminderTime.isAfter(minimumTime)) {
          final title = 'Appointment Reminder - ${interval.displayName}';
          final body = _getReminderBody(booking, interval, bookingDateTime);
          final payload = 'reminder_${interval.id}:${booking.id}';

          await _notificationService.scheduleNotification(
            id: _getNotificationId(booking.id, interval.id),
            title: title,
            body: body,
            scheduledDate: reminderTime,
            payload: payload,
          );

          print('   ✅ ${interval.displayName} reminder scheduled successfully');
        } else {
          if (reminderTime.isBefore(DateTime.now())) {
            print(
              '   ⏭️ ${interval.displayName} reminder skipped (time in past)',
            );
          } else {
            print(
              '   ⏭️ ${interval.displayName} reminder skipped (too close to appointment)',
            );
          }
        }
        print(''); // Add blank line for better readability
      }
    } catch (e) {
      print('❌ Error scheduling user reminders: $e');
    }
  }

  /// Get reminder body text based on interval
  String _getReminderBody(
    Booking booking,
    dynamic interval,
    DateTime bookingDateTime,
  ) {
    final timeUntil = _getTimeUntilText(interval);
    return 'Your appointment with ${booking.shopName} is $timeUntil (${_formatDateTime(bookingDateTime)})';
  }

  /// Get human-readable time until text
  String _getTimeUntilText(dynamic interval) {
    switch (interval.id) {
      // Testing intervals
      case '1s':
        return 'in 1 second';
      case '3s':
        return 'in 3 seconds';
      case '5s':
        return 'in 5 seconds';
      case '10s':
        return 'in 10 seconds';
      // Production intervals
      case '1h':
        return 'in 1 hour';
      case '2h':
        return 'in 2 hours';
      case '3h':
        return 'in 3 hours';
      case '12h':
        return 'in 12 hours';
      case '1d':
        return 'tomorrow';
      case '3d':
        return 'in 3 days';
      case '1w':
        return 'in 1 week';
      default:
        return 'soon';
    }
  }

  /// Cancel all reminders for a booking
  Future<void> cancelBookingReminders(String bookingId) async {
    try {
      // Cancel confirmation notification
      await _notificationService.cancelNotification(
        _getNotificationId(bookingId, 'confirmation'),
      );

      // Cancel all possible reminder intervals (testing + production)
      final allIntervals = [
        '1s',
        '3s',
        '5s',
        '10s',
        '1h',
        '2h',
        '3h',
        '12h',
        '1d',
        '3d',
        '1w',
      ];
      for (final intervalId in allIntervals) {
        await _notificationService.cancelNotification(
          _getNotificationId(bookingId, intervalId),
        );
      }

      print('✅ All reminders cancelled for booking: $bookingId');
    } catch (e) {
      print('❌ Error cancelling reminders: $e');
    }
  }

  // Reschedule function removed - only confirmation and reminder emails

  /// Get notification ID for a specific booking and reminder type
  int _getNotificationId(String bookingId, String reminderType) {
    // Create a unique ID by combining booking ID hash and reminder type
    final bookingHash = bookingId.hashCode.abs();
    final typeHash = reminderType.hashCode.abs();
    // Use a more unique approach to avoid collisions
    return (bookingHash % 10000) * 10000 + (typeHash % 10000);
  }

  /// Format date and time for display
  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  /// Get all pending reminders
  Future<List<Map<String, dynamic>>> getPendingReminders() async {
    try {
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      final reminders = <Map<String, dynamic>>[];

      for (final notification in pendingNotifications) {
        final payload = notification.payload ?? '';
        if (payload.startsWith('booking_')) {
          final parts = payload.split(':');
          if (parts.length >= 2) {
            reminders.add({
              'id': notification.id,
              'title': notification.title ?? 'Notification',
              'body': notification.body ?? '',
              'type': parts[0],
              'bookingId': parts[1],
            });
          }
        }
      }

      return reminders;
    } catch (e) {
      print('❌ Error getting pending reminders: $e');
      return [];
    }
  }

  /// Test notification (for development)
  Future<void> testNotification() async {
    await _notificationService.showImmediateNotification(
      title: 'Test Notification',
      body: 'This is a test notification from AutoAnywhere App',
      payload: 'test',
    );
  }

  /// Clear all pending reminders from notification list
  Future<void> clearAllPendingReminders() async {
    try {
      print('🧹 Clearing all pending reminders...');
      await _notificationService.cancelScheduledNotifications();
      print('✅ All pending reminders cleared from notification list');
    } catch (e) {
      print('❌ Error clearing pending reminders: $e');
    }
  }

  /// Clear reminders for a specific booking
  Future<void> clearBookingReminders(String bookingId) async {
    try {
      print('🧹 Clearing reminders for booking: $bookingId');
      await _notificationService.cancelBookingNotifications(bookingId);
      print('✅ Reminders cleared for booking: $bookingId');
    } catch (e) {
      print('❌ Error clearing booking reminders: $e');
    }
  }

  /// Clean up expired reminders (reminders that should have already fired)
  Future<void> cleanupExpiredReminders() async {
    try {
      print('🧹 Cleaning up expired reminders...');
      final pending = await _notificationService.getPendingNotifications();
      int cleanedCount = 0;
      
      for (final notification in pending) {
        final payload = notification.payload ?? '';
        if (payload.startsWith('reminder_')) {
          // Extract booking ID and check if the appointment has passed
          final parts = payload.split(':');
          if (parts.length >= 2) {
            // For now, we'll clean up all reminder notifications
            // In a real app, you'd check the actual appointment time
            await _notificationService.cancelNotification(notification.id);
            cleanedCount++;
          }
        }
      }
      
      print('✅ Cleaned up $cleanedCount expired reminders');
    } catch (e) {
      print('❌ Error cleaning up expired reminders: $e');
    }
  }

  /// Check for upcoming appointments and show reminder if within 12 hours
  Future<void> checkUpcomingAppointments() async {
    try {
      print('🔍 Checking for upcoming appointments within 12 hours...');
      
      // Get all pending notifications
      final pending = await _notificationService.getPendingNotifications();
      final scheduled = _notificationService.getScheduledNotifications();
      final now = DateTime.now();
      final twelveHoursFromNow = now.add(Duration(hours: 12));
      
      print('🕐 Current time: $now');
      print('🕐 Checking appointments before: $twelveHoursFromNow');
      print('📋 System pending notifications: ${pending.length}');
      print('📋 Timer-based scheduled notifications: ${scheduled.length}');
      
      // Look for appointment confirmation notifications (these contain appointment info)
      for (final notification in pending) {
        final payload = notification.payload ?? '';
        if (payload.startsWith('booking_confirmation:')) {
          final bookingId = payload.split(':')[1];
          print('📅 Found appointment booking: $bookingId');
          
          // Show immediate reminder for testing
          await _notificationService.showImmediateNotification(
            title: '🔔 Upcoming Appointment Reminder',
            body: 'You have an appointment coming up within 12 hours! Check your bookings.',
            payload: 'upcoming_reminder_$bookingId',
          );
          
          print('✅ Upcoming appointment reminder shown for booking: $bookingId');
        }
      }
      
      // Also show a general reminder if there are any scheduled notifications
      if (scheduled.isNotEmpty) {
        await _notificationService.showImmediateNotification(
          title: '📱 App Notification Test',
          body: 'Notification system is working! You have ${scheduled.length} scheduled reminders.',
          payload: 'app_entry_test',
        );
        print('✅ App entry notification test shown');
      }
      
    } catch (e) {
      print('❌ Error checking upcoming appointments: $e');
    }
  }

  /// Test fake appointment with 1s, 5s, 10s reminders
  Future<void> testFakeAppointment() async {
    try {
      print('🧪 Testing FAKE APPOINTMENT notification system...');

      // First test immediate notification to verify basic functionality
      print('🧪 STEP 1: Testing immediate notification...');
      await _notificationService.showImmediateNotification(
        title: 'Immediate Test',
        body: 'This should appear immediately if notifications work',
        payload: 'immediate_test',
      );
      print('✅ Immediate notification sent - check if it appears!');

      // Check battery optimization
      await _notificationService.checkBatteryOptimization();

      // Wait 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      // Test timer-based notification (more reliable)
      print('🧪 STEP 2: Testing timer-based notification (3 seconds)...');
      await _notificationService.testTimerNotification(
        id: 999999,
        title: 'Timer Test - 3s',
        body: 'This should appear in 3 seconds using timer',
        delay: const Duration(seconds: 3),
      );
      print('✅ Timer-based notification created - wait 3 seconds!');

      // Wait 5 seconds to see if short test works
      await Future.delayed(const Duration(seconds: 5));

      // CRITICAL TEST: Force immediate notification to verify system works
      print('🧪 STEP 3: Testing immediate notification after scheduling...');
      await _notificationService.showImmediateNotification(
        title: 'CRITICAL TEST - Immediate',
        body:
            'If you see this, basic notifications work. The issue is with scheduling.',
        payload: 'critical_test',
      );
      print('✅ CRITICAL TEST: Immediate notification sent after scheduling');

      // Create fake appointment 20 seconds from now
      final appointmentTime = DateTime.now().add(const Duration(seconds: 20));
      print('🧪 FAKE APPOINTMENT: Created for: $appointmentTime');
      print('🧪 FAKE APPOINTMENT: Current time: ${DateTime.now()}');

      // Create fake booking data
      final fakeBooking = Booking(
        id: 'fake_test_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_customer',
        customerName: 'Test Customer',
        customerPhone: '0123456789',
        customerEmail: 'test@example.com',
        shopId: 'test_shop',
        shopName: 'Test Auto Shop',
        shopAddress: '123 Test Street',
        shopPhone: '0123456789',
        date: appointmentTime.toString().split(
          ' ',
        )[0], // Convert to string date
        timeSlot: 'Test Time Slot',
        serviceTypes: ['Test Service'],
        totalDuration: 60, // 60 minutes
        status: BookingStatus.confirmed,
        notes: 'Fake test appointment',
        estimatedCost: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test timer-based reminders (more reliable for testing)
      print('🧪 STEP 4: Testing timer-based appointment reminders...');

      // Schedule timer-based reminders at 1s, 5s, and 10s before appointment
      final reminderDelays = [
        {'interval': '1s', 'seconds': 1, 'delay': const Duration(seconds: 19)},
        {'interval': '5s', 'seconds': 5, 'delay': const Duration(seconds: 15)},
        {
          'interval': '10s',
          'seconds': 10,
          'delay': const Duration(seconds: 10),
        },
      ];

      for (final reminder in reminderDelays) {
        final interval = reminder['interval'] as String;
        final seconds = reminder['seconds'] as int;
        final delay = reminder['delay'] as Duration;

        print(
          '🧪 TIMER: Scheduling $interval reminder with ${delay.inSeconds}s delay',
        );

        await _notificationService.testTimerNotification(
          id: _getNotificationId(fakeBooking.id, interval),
          title: 'Timer Appointment Reminder - $interval',
          body:
              'Your test appointment with ${fakeBooking.shopName} is in $seconds seconds (${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')})',
          delay: delay,
        );

        print('✅ TIMER: $interval reminder scheduled successfully');
      }

      print('✅ Timer-based appointment test completed');
      print('⏰ Timer notifications will appear at:');
      print('   - 10s before: In 10 seconds (Timer Test)');
      print('   - 5s before: In 15 seconds (Timer Test)');
      print('   - 1s before: In 19 seconds (Timer Test)');
      print('   - Appointment time: In 20 seconds');

      // Check pending notifications
      print('🔍 Checking all pending notifications...');
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      print('📋 Total pending notifications: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        print('   - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      print('❌ Error in fake appointment test: $e');
    }
  }

  /// Test REAL appointment scheduling (production-ready)
  Future<void> testRealAppointmentScheduling() async {
    try {
      print('🧪 Testing REAL APPOINTMENT scheduling system...');

      // First test immediate notification to verify basic functionality
      print('🧪 STEP 1: Testing immediate notification...');
      await _notificationService.showImmediateNotification(
        title: 'Immediate Test',
        body: 'This should appear immediately if notifications work',
        payload: 'immediate_test',
      );
      print('✅ Immediate notification sent - check if it appears!');

      // Wait 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      // Test REAL scheduled notification (this is what production apps use)
      print('🧪 STEP 2: Testing REAL scheduled notification (5 seconds)...');
      final realTestTime = DateTime.now().add(const Duration(seconds: 5));
      await _notificationService.scheduleNotification(
        id: 999999,
        title: 'REAL Scheduled Test - 5s',
        body:
            'This uses REAL scheduling (5 seconds) - should work for production',
        scheduledDate: realTestTime,
        payload: 'real_scheduled_test',
      );
      print('✅ REAL scheduled notification created - wait 5 seconds!');

      // Wait 7 seconds to see if real scheduled notification works
      await Future.delayed(const Duration(seconds: 7));

      // Test with longer delay (30 seconds) to simulate real appointment
      print('🧪 STEP 3: Testing REAL scheduled notification (30 seconds)...');
      final longTestTime = DateTime.now().add(const Duration(seconds: 30));
      await _notificationService.scheduleNotification(
        id: 888888,
        title: 'REAL Long Test - 30s',
        body:
            'This tests longer scheduling (30 seconds) - like real appointments',
        scheduledDate: longTestTime,
        payload: 'real_long_test',
      );
      print('✅ REAL long scheduled notification created - wait 30 seconds!');

      // Test with even longer delay (2 minutes) to simulate real appointment
      print('🧪 STEP 4: Testing REAL scheduled notification (2 minutes)...');
      final veryLongTestTime = DateTime.now().add(const Duration(minutes: 2));
      await _notificationService.scheduleNotification(
        id: 777777,
        title: 'REAL Very Long Test - 2min',
        body:
            'This tests very long scheduling (2 minutes) - like real appointments',
        scheduledDate: veryLongTestTime,
        payload: 'real_very_long_test',
      );
      print(
        '✅ REAL very long scheduled notification created - wait 2 minutes!',
      );

      print('✅ REAL appointment scheduling test completed');
      print('⏰ REAL scheduled notifications will appear at:');
      print('   - 5s test: In 5 seconds');
      print('   - 30s test: In 30 seconds');
      print('   - 2min test: In 2 minutes');
      print('   - These use REAL scheduling that works for production apps!');

      // Check pending notifications
      print('🔍 Checking all pending notifications...');
      final pendingNotifications = await _notificationService
          .getPendingNotifications();
      print('📋 Total pending notifications: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        print('   - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      print('❌ Error in real appointment scheduling test: $e');
    }
  }
}
