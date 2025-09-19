import 'dart:async';
import 'emailjs_service.dart';
import '../../shared/models/booking_model.dart';

class EmailReminderScheduler {
  static final EmailReminderScheduler _instance = EmailReminderScheduler._internal();
  factory EmailReminderScheduler() => _instance;
  EmailReminderScheduler._internal();

  final EmailJSService _emailService = EmailJSService();
  
  // Store scheduled email reminders
  final Map<String, Timer> _emailReminders = {};

  /// Schedule email reminders for a booking
  Future<void> scheduleEmailReminders(Booking booking) async {
    try {
      print('📧 Scheduling email reminders for booking: ${booking.id}');
      
      // Parse booking date and time
      final bookingDate = DateTime.parse(booking.date);
      final timeParts = booking.timeSlot.split('-')[0].split(':');
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      print('📧 Booking time: $bookingDateTime');
      print('📧 Current time: ${DateTime.now()}');

      // Schedule reminder email 2 minutes after booking
      // Note: Confirmation email is already sent by BookingService
      await _scheduleEmailReminder(booking, DateTime.now(), Duration(minutes: 2), '2 Minutes After Booking');

      print('✅ All email reminders scheduled for booking: ${booking.id}');
    } catch (e) {
      print('❌ Error scheduling email reminders: $e');
    }
  }


  /// Schedule an email reminder
  Future<void> _scheduleEmailReminder(
    Booking booking,
    DateTime startTime,
    Duration reminderTime,
    String reminderType,
  ) async {
    try {
      final reminderDateTime = startTime.add(reminderTime);
      final delay = reminderDateTime.difference(DateTime.now());
      
      print('📧 Scheduling $reminderType email reminder for: $reminderDateTime');
      print('📧 Delay: ${delay.inMinutes}m ${delay.inSeconds % 60}s');

      // Only schedule if the reminder time is in the future
      if (delay.inMilliseconds > 0) {
        final reminderKey = '${booking.id}_$reminderType';
        
        // Cancel existing reminder if any
        _emailReminders[reminderKey]?.cancel();
        
        // Schedule new reminder
        _emailReminders[reminderKey] = Timer(delay, () async {
          print('📧 Timer fired for $reminderType email reminder');
          await _emailService.sendAppointmentReminder(booking, reminderType);
          _emailReminders.remove(reminderKey);
        });
        
        print('✅ $reminderType email reminder scheduled successfully');
      } else {
        print('⏭️ $reminderType email reminder skipped (time in past)');
      }
    } catch (e) {
      print('❌ Error scheduling $reminderType email reminder: $e');
    }
  }

  /// Cancel email reminders for a booking
  Future<void> cancelEmailReminders(String bookingId) async {
    try {
      print('📧 Cancelling email reminders for booking: $bookingId');
      
      // Cancel all reminders for this booking
      final keysToRemove = <String>[];
      for (final key in _emailReminders.keys) {
        if (key.startsWith('${bookingId}_')) {
          _emailReminders[key]?.cancel();
          keysToRemove.add(key);
        }
      }
      
      for (final key in keysToRemove) {
        _emailReminders.remove(key);
      }
      
      print('✅ Cancelled ${keysToRemove.length} email reminders for booking: $bookingId');
    } catch (e) {
      print('❌ Error cancelling email reminders: $e');
    }
  }

  // Cancellation and reschedule functions removed - only confirmation and reminder emails

  /// Get scheduled email reminders count
  int getScheduledEmailRemindersCount() {
    return _emailReminders.length;
  }

  /// Get scheduled email reminders info
  Map<String, String> getScheduledEmailReminders() {
    final reminders = <String, String>{};
    for (final entry in _emailReminders.entries) {
      reminders[entry.key] = 'Scheduled';
    }
    return reminders;
  }

  /// Test email reminder system
  Future<void> testEmailReminderSystem() async {
    try {
      print('🧪 Testing email reminder system...');
      
      // Test email service first
      final emailTest = await _emailService.testEmailJSService();
      if (!emailTest) {
        print('❌ Email service test failed, cannot test reminders');
        return;
      }
      
      // Create test booking for tomorrow
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final testBooking = Booking(
        id: 'test_email_reminder_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        customerName: 'Test Customer',
        customerPhone: '0123456789',
        customerEmail: 'test@example.com',
        shopId: 'test_shop',
        shopName: 'Test Auto Shop',
        shopAddress: '123 Test Street',
        shopPhone: '0123456789',
        date: tomorrow.toString().split(' ')[0],
        timeSlot: '14:00-15:00',
        serviceTypes: ['Test Service'],
        totalDuration: 60,
        status: BookingStatus.confirmed,
        notes: 'Test email reminder',
        estimatedCost: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Schedule email reminders (will send reminder 2 minutes after booking)
      await scheduleEmailReminders(testBooking);
      
      print('✅ Email reminder system test completed');
      print('📧 Scheduled reminders: ${getScheduledEmailRemindersCount()}');
      print('📧 Reminder will be sent 2 minutes after booking');
      print('📧 Note: Confirmation email is sent separately by BookingService');
    } catch (e) {
      print('❌ Error testing email reminder system: $e');
    }
  }
}
