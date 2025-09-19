import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/booking_model.dart';
import '../config/email_config.dart';

class EmailNotificationService {
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  // Email service configuration from config file

  /// Send appointment confirmation email
  Future<bool> sendAppointmentConfirmation(Booking booking) async {
    try {
      print('📧 Sending appointment confirmation email...');
      
      final emailData = {
        'service_id': EmailConfig.serviceId,
        'template_id': EmailConfig.confirmationTemplateId,
        'user_id': EmailConfig.publicKey,
        'accessToken': EmailConfig.privateKey,
        'template_params': {
          'to_email': EmailConfig.getEmail(booking.customerEmail),
          'customer_name': booking.customerName,
          'shop_name': booking.shopName,
          'appointment_date': _formatDate(booking.date),
          'appointment_time': booking.timeSlot,
          'service_types': booking.serviceTypes.join(', '),
          'estimated_cost': booking.estimatedCost.toString(),
          'shop_address': booking.shopAddress,
          'shop_phone': booking.shopPhone,
          'booking_id': booking.id,
        }
      };

      final response = await http.post(
        Uri.parse(EmailConfig.emailApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('✅ Appointment confirmation email sent successfully');
        return true;
      } else {
        print('❌ Failed to send email: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending appointment confirmation email: $e');
      return false;
    }
  }

  /// Send appointment reminder email
  Future<bool> sendAppointmentReminder(Booking booking, String reminderType) async {
    try {
      print('📧 Sending appointment reminder email: $reminderType');
      
      final emailData = {
        'service_id': EmailConfig.serviceId,
        'template_id': EmailConfig.reminderTemplateId,
        'user_id': EmailConfig.publicKey,
        'accessToken': EmailConfig.privateKey,
        'template_params': {
          'to_email': EmailConfig.getEmail(booking.customerEmail),
          'customer_name': booking.customerName,
          'shop_name': booking.shopName,
          'appointment_date': _formatDate(booking.date),
          'appointment_time': booking.timeSlot,
          'reminder_type': reminderType,
          'service_types': booking.serviceTypes.join(', '),
          'estimated_cost': booking.estimatedCost.toString(),
          'shop_address': booking.shopAddress,
          'shop_phone': booking.shopPhone,
          'booking_id': booking.id,
        }
      };

      final response = await http.post(
        Uri.parse(EmailConfig.emailApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('✅ Appointment reminder email sent successfully: $reminderType');
        return true;
      } else {
        print('❌ Failed to send reminder email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending appointment reminder email: $e');
      return false;
    }
  }


  /// Format date for email display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Check if email service is properly configured
  bool get isConfigured => EmailConfig.isConfigured;
  
  /// Get configuration status
  String get configurationStatus => EmailConfig.configurationStatus;

  /// Test email functionality
  Future<bool> testEmailService() async {
    try {
      print('🧪 Testing email service...');
      
      // Check if email service is configured
      if (!isConfigured) {
        print('❌ Email service not configured!');
        print(configurationStatus);
        return false;
      }
      
      // Create a test booking
      final testBooking = Booking(
        id: 'test_email_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        customerName: 'Test Customer',
        customerPhone: '0123456789',
        customerEmail: 'test@example.com',
        shopId: 'test_shop',
        shopName: 'Test Auto Shop',
        shopAddress: '123 Test Street',
        shopPhone: '0123456789',
        date: DateTime.now().add(Duration(days: 1)).toString().split(' ')[0],
        timeSlot: '10:00-11:00',
        serviceTypes: ['Test Service'],
        totalDuration: 60,
        status: BookingStatus.confirmed,
        notes: 'Test email notification',
        estimatedCost: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test sending confirmation email
      final success = await sendAppointmentConfirmation(testBooking);
      
      if (success) {
        print('✅ Email service test successful');
        return true;
      } else {
        print('❌ Email service test failed');
        return false;
      }
    } catch (e) {
      print('❌ Error testing email service: $e');
      return false;
    }
  }
}
