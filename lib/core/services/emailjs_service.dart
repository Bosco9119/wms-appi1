import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/booking_model.dart';
import '../config/email_config.dart';

class EmailJSService {
  static final EmailJSService _instance = EmailJSService._internal();
  factory EmailJSService() => _instance;
  EmailJSService._internal();

  /// Send appointment confirmation email using EmailJS
  Future<bool> sendAppointmentConfirmation(Booking booking) async {
    try {
      print('📧 Sending appointment confirmation email via EmailJS...');
      final recipientEmail = EmailConfig.getEmail(booking.customerEmail);
      print('📧 To: $recipientEmail');
      print('📧 Original customer email: ${booking.customerEmail}');
      print('📧 Test mode: ${EmailConfig.isTestMode}');
      
      // EmailJS API call with proper format
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailConfig.serviceId,
          'template_id': EmailConfig.confirmationTemplateId,
          'user_id': EmailConfig.publicKey,
          'accessToken': EmailConfig.privateKey,
          'template_params': {
            'to_email': recipientEmail,
            'to_name': booking.customerName,
            'from_name': 'AutoAnywhere App',
            'reply_to': 'noreply@autoanywhere.com',
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
        }),
      );

      print('📧 EmailJS Response Status: ${response.statusCode}');
      print('📧 EmailJS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Appointment confirmation email sent successfully via EmailJS!');
        print('📧 Customer should receive email at: $recipientEmail');
        return true;
      } else {
        print('❌ EmailJS failed with status: ${response.statusCode}');
        print('❌ Error details: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending confirmation email via EmailJS: $e');
      return false;
    }
  }

  /// Send appointment reminder email using EmailJS
  Future<bool> sendAppointmentReminder(Booking booking, String reminderType) async {
    try {
      print('📧 Sending appointment reminder email via EmailJS: $reminderType');
      final recipientEmail = EmailConfig.getEmail(booking.customerEmail);
      print('📧 To: $recipientEmail');
      print('📧 Original customer email: ${booking.customerEmail}');
      print('📧 Test mode: ${EmailConfig.isTestMode}');
      
      // EmailJS API call with proper format
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailConfig.serviceId,
          'template_id': EmailConfig.reminderTemplateId,
          'user_id': EmailConfig.publicKey,
          'accessToken': EmailConfig.privateKey,
          'template_params': {
            'to_email': recipientEmail,
            'to_name': booking.customerName,
            'from_name': 'AutoAnywhere App',
            'reply_to': 'noreply@autoanywhere.com',
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
        }),
      );

      print('📧 EmailJS Response Status: ${response.statusCode}');
      print('📧 EmailJS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Appointment reminder email sent successfully via EmailJS!');
        print('📧 Customer should receive email at: $recipientEmail');
        return true;
      } else {
        print('❌ EmailJS failed with status: ${response.statusCode}');
        print('❌ Error details: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending reminder email via EmailJS: $e');
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

  /// Test EmailJS service
  Future<bool> testEmailJSService() async {
    try {
      print('🧪 Testing EmailJS service...');
      
      // Check configuration
      if (!isConfigured) {
        print('❌ EmailJS not configured!');
        print(configurationStatus);
        return false;
      }
      
      // Create a test booking
      final testBooking = Booking(
        id: 'test_emailjs_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        customerName: 'Test Customer',
        customerPhone: '0123456789',
        customerEmail: EmailConfig.testEmail,
        shopId: 'test_shop',
        shopName: 'Test Auto Shop',
        shopAddress: '123 Test Street',
        shopPhone: '0123456789',
        date: DateTime.now().add(Duration(days: 1)).toString().split(' ')[0],
        timeSlot: '10:00-11:00',
        serviceTypes: ['Test Service'],
        totalDuration: 60,
        status: BookingStatus.confirmed,
        notes: 'Test EmailJS notification',
        estimatedCost: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test sending confirmation email
      final success = await sendAppointmentConfirmation(testBooking);
      
      if (success) {
        print('✅ EmailJS service test successful');
        return true;
      } else {
        print('❌ EmailJS service test failed');
        return false;
      }
    } catch (e) {
      print('❌ Error testing EmailJS service: $e');
      return false;
    }
  }
}
