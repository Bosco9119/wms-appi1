import '../../shared/models/booking_model.dart';
import '../config/email_config.dart';

class SimpleEmailService {
  static final SimpleEmailService _instance = SimpleEmailService._internal();
  factory SimpleEmailService() => _instance;
  SimpleEmailService._internal();

  /// Send appointment confirmation email (simulated)
  Future<bool> sendAppointmentConfirmation(Booking booking) async {
    try {
      print('📧 Sending appointment confirmation email...');
      
      // Log email details instead of actually sending
      print('📧 EMAIL CONFIRMATION:');
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
      
      // Simulate successful email sending
      print('✅ Appointment confirmation email sent successfully!');
      return true;
      
    } catch (e) {
      print('❌ Error sending appointment confirmation email: $e');
      return false;
    }
  }

  /// Send appointment reminder email (simulated)
  Future<bool> sendAppointmentReminder(Booking booking, String reminderType) async {
    try {
      print('📧 Sending appointment reminder email: $reminderType');
      
      // Log email details instead of actually sending
      print('📧 EMAIL REMINDER ($reminderType):');
      print('   📧 To: ${EmailConfig.getEmail(booking.customerEmail)}');
      print('   👤 Customer: ${booking.customerName}');
      print('   🏪 Shop: ${booking.shopName}');
      print('   📅 Date: ${_formatDate(booking.date)}');
      print('   ⏰ Time: ${booking.timeSlot}');
      print('   🔧 Services: ${booking.serviceTypes.join(', ')}');
      print('   💰 Cost: \$${booking.estimatedCost}');
      print('   🆔 Booking ID: ${booking.id}');
      
      // Simulate successful email sending
      print('✅ Appointment reminder email sent successfully!');
      return true;
      
    } catch (e) {
      print('❌ Error sending appointment reminder email: $e');
      return false;
    }
  }

  // Cancellation and reschedule functions removed - only confirmation and reminder emails

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
  bool get isConfigured => true; // Always configured for simulation
  
  /// Get configuration status
  String get configurationStatus => '✅ Email service configured (simulation mode)';

  /// Test email functionality
  Future<bool> testEmailService() async {
    try {
      print('🧪 Testing email service (simulation mode)...');
      
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
        print('✅ Email service test successful (simulation mode)');
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
