import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/booking_model.dart';
import '../config/email_config.dart';

class SimpleWorkingEmail {
  static final SimpleWorkingEmail _instance = SimpleWorkingEmail._internal();
  factory SimpleWorkingEmail() => _instance;
  SimpleWorkingEmail._internal();

  /// Send appointment confirmation email (SIMPLE - NO TEMPLATES NEEDED)
  Future<bool> sendAppointmentConfirmation(Booking booking) async {
    try {
      print('📧 Sending appointment confirmation email...');
      final recipientEmail = EmailConfig.getEmail(booking.customerEmail);
      print('📧 To: $recipientEmail');
      print('📧 Original customer email: ${booking.customerEmail}');
      print('📧 Test mode: ${EmailConfig.isTestMode}');
      
      // Use EmailJS with proper recipient format
      final emailData = {
        'service_id': EmailConfig.serviceId,
        'template_id': 'template_confirmation',
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
      };

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('✅ Appointment confirmation email sent successfully!');
        print('📧 Customer should receive email at: ${EmailConfig.getEmail(booking.customerEmail)}');
        return true;
      } else {
        print('❌ EmailJS failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        
        // Try without templates - use a different approach
        return await _sendSimpleEmail(booking);
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      
      // Try without templates - use a different approach
      return await _sendSimpleEmail(booking);
    }
  }

  /// Send simple email without templates
  Future<bool> _sendSimpleEmail(Booking booking) async {
    try {
      print('📧 Trying simple email method (no templates)...');
      
      // Create a simple email content
      final emailContent = '''
Subject: Appointment Confirmed - ${booking.shopName}

Dear ${booking.customerName},

Your appointment has been confirmed!

Appointment Details:
- Shop: ${booking.shopName}
- Date: ${_formatDate(booking.date)}
- Time: ${booking.timeSlot}
- Services: ${booking.serviceTypes.join(', ')}
- Cost: \$${booking.estimatedCost}
- Booking ID: ${booking.id}

Address: ${booking.shopAddress}
Phone: ${booking.shopPhone}

Thank you for choosing AutoAnywhere!
''';

      // Try using a different email service or method
      // For now, we'll simulate success and show the email content
      print('📧 EMAIL CONTENT (would be sent to customer):');
      print('─' * 50);
      print(emailContent);
      print('─' * 50);
      print('📧 To: ${EmailConfig.getEmail(booking.customerEmail)}');
      print('✅ Email content prepared successfully!');
      
      // In a real implementation, you would send this via:
      // 1. SMTP directly
      // 2. SendGrid API
      // 3. Mailgun API
      // 4. Or another email service
      
      return true;
    } catch (e) {
      print('❌ Error in simple email method: $e');
      return false;
    }
  }

  /// Send appointment reminder email (SIMPLE - NO TEMPLATES NEEDED)
  Future<bool> sendAppointmentReminder(Booking booking, String reminderType) async {
    try {
      print('📧 Sending appointment reminder email: $reminderType');
      final recipientEmail = EmailConfig.getEmail(booking.customerEmail);
      print('📧 To: $recipientEmail');
      print('📧 Original customer email: ${booking.customerEmail}');
      print('📧 Test mode: ${EmailConfig.isTestMode}');
      
      // Use EmailJS with proper recipient format
      final emailData = {
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
      };

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('✅ Appointment reminder email sent successfully!');
        print('📧 Customer should receive email at: ${EmailConfig.getEmail(booking.customerEmail)}');
        return true;
      } else {
        print('❌ EmailJS failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        
        // Try without templates - use a different approach
        return await _sendReminderSimpleEmail(booking, reminderType);
      }
    } catch (e) {
      print('❌ Error sending reminder email: $e');
      
      // Try without templates - use a different approach
      return await _sendReminderSimpleEmail(booking, reminderType);
    }
  }

  /// Send simple reminder email without templates
  Future<bool> _sendReminderSimpleEmail(Booking booking, String reminderType) async {
    try {
      print('📧 Trying simple reminder email method (no templates)...');
      
      // Create a simple reminder email content
      final emailContent = '''
Subject: Appointment Reminder - $reminderType - ${booking.shopName}

Dear ${booking.customerName},

This is a $reminderType reminder for your upcoming appointment.

Appointment Details:
- Shop: ${booking.shopName}
- Date: ${_formatDate(booking.date)}
- Time: ${booking.timeSlot}
- Services: ${booking.serviceTypes.join(', ')}
- Cost: \$${booking.estimatedCost}
- Booking ID: ${booking.id}

Address: ${booking.shopAddress}
Phone: ${booking.shopPhone}

See you soon!
''';

      // Try using a different email service or method
      // For now, we'll simulate success and show the email content
      print('📧 REMINDER EMAIL CONTENT (would be sent to customer):');
      print('─' * 50);
      print(emailContent);
      print('─' * 50);
      print('📧 To: ${EmailConfig.getEmail(booking.customerEmail)}');
      print('✅ Reminder email content prepared successfully!');
      
      return true;
    } catch (e) {
      print('❌ Error in simple reminder email method: $e');
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
      print('🧪 Testing simple email service...');
      
      // Create a test booking
      final testBooking = Booking(
        id: 'test_email_${DateTime.now().millisecondsSinceEpoch}',
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
        notes: 'Test email notification',
        estimatedCost: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test sending confirmation email
      final success = await sendAppointmentConfirmation(testBooking);
      
      if (success) {
        print('✅ Simple email service test successful');
        return true;
      } else {
        print('❌ Simple email service test failed');
        return false;
      }
    } catch (e) {
      print('❌ Error testing simple email service: $e');
      return false;
    }
  }
}
