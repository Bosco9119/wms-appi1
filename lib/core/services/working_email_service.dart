import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/booking_model.dart';
import '../config/email_config.dart';

class WorkingEmailService {
  static final WorkingEmailService _instance = WorkingEmailService._internal();
  factory WorkingEmailService() => _instance;
  WorkingEmailService._internal();

  /// Send appointment confirmation email (ACTUALLY SENDS EMAILS)
  Future<bool> sendAppointmentConfirmation(Booking booking) async {
    try {
      print('📧 Sending REAL appointment confirmation email...');
      print('📧 To: ${EmailConfig.getEmail(booking.customerEmail)}');
      
      // Use a simple email service that works without templates
      final emailData = {
        'service_id': EmailConfig.serviceId,
        'template_id': 'template_confirmation',
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
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('✅ REAL appointment confirmation email sent successfully!');
        print('📧 Customer should receive email at: ${EmailConfig.getEmail(booking.customerEmail)}');
        return true;
      } else {
        print('❌ Failed to send REAL email: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        
        // If EmailJS fails, try alternative approach
        return await _sendEmailAlternative(booking, 'CONFIRMATION');
      }
    } catch (e) {
      print('❌ Error sending REAL appointment confirmation email: $e');
      
      // If EmailJS fails, try alternative approach
      return await _sendEmailAlternative(booking, 'CONFIRMATION');
    }
  }

  /// Alternative email sending method (when EmailJS fails)
  Future<bool> _sendEmailAlternative(Booking booking, String type) async {
    try {
      print('📧 Trying alternative email method...');
      
      // Use a different email service or method
      // For now, we'll use a simple HTTP POST to a generic email service
      final emailContent = _buildEmailContent(booking, type);
      
      // Try using a simple email API
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': EmailConfig.serviceId,
          'template_id': 'template_confirmation',
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
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Alternative email method successful!');
        print('📧 Customer should receive email at: ${EmailConfig.getEmail(booking.customerEmail)}');
        return true;
      } else {
        print('❌ Alternative email method also failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        
        // Final fallback: Show email details
        _showEmailDetails(booking, type);
        return false;
      }
    } catch (e) {
      print('❌ Alternative email method error: $e');
      
      // Final fallback: Show email details
      _showEmailDetails(booking, type);
      return false;
    }
  }

  /// Build email content
  String _buildEmailContent(Booking booking, String type) {
    return '''
Subject: Appointment $type - ${booking.shopName}

Dear ${booking.customerName},

Your appointment has been $type.toLowerCase()!

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
  }

  /// Show email details in console (fallback)
  void _showEmailDetails(Booking booking, String type) {
    print('📧 EMAIL $type (FALLBACK - Email service failed):');
    print('   📧 To: ${EmailConfig.getEmail(booking.customerEmail)}');
    print('   👤 Customer: ${booking.customerName}');
    print('   🏪 Shop: ${booking.shopName}');
    print('   📅 Date: ${_formatDate(booking.date)}');
    print('   ⏰ Time: ${booking.timeSlot}');
    print('   🔧 Services: ${booking.serviceTypes.join(', ')}');
    print('   💰 Cost: \$${booking.estimatedCost}');
    print('   🆔 Booking ID: ${booking.id}');
    print('   📍 Address: ${booking.shopAddress}');
    print('   📞 Phone: ${booking.shopPhone}');
    print('');
    print('⚠️ IMPORTANT: Customer did not receive email!');
    print('⚠️ Please contact customer manually or check email service configuration.');
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
      print('🧪 Testing REAL email service...');
      
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
        print('✅ REAL email service test successful');
        return true;
      } else {
        print('❌ REAL email service test failed');
        return false;
      }
    } catch (e) {
      print('❌ Error testing REAL email service: $e');
      return false;
    }
  }
}
