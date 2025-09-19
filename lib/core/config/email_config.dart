class EmailConfig {
  // EmailJS Configuration
  // Get these from https://www.emailjs.com
  static const String emailApiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  
  // Replace these with your actual EmailJS credentials
  static const String serviceId = 'service_x0c0czj'; // Your EmailJS service ID
  static const String publicKey = 'p6lbV0gWay6FOnK8Z'; // Your EmailJS public key
  static const String privateKey = 'r7Z0K-_qI_cDpqjOLIaYH'; // Your EmailJS private key (for strict mode)
  
  // Email template IDs (create these in EmailJS dashboard)
  static const String confirmationTemplateId = 'template_confirmation';
  static const String reminderTemplateId = 'template_reminder';
  
  // Email settings
  static const String fromName = 'AutoAnywhere App';
  static const String fromEmail = 'noreply@autoanywhere.com';
  
  // Test mode - set to false for production (uses real customer emails)
  static const bool isTestMode = false;
  static const String testEmail = 'your-email@gmail.com'; // Only used when isTestMode = true
  
  /// Get the appropriate email based on test mode
  static String getEmail(String userEmail) {
    return isTestMode ? testEmail : userEmail;
  }
  
  /// Check if email service is configured
  static bool get isConfigured {
    return serviceId != 'service_xxxxxxxxx' && 
           publicKey != 'xxxxxxxxxxxxxxxx' &&
           privateKey != 'xxxxxxxxxxxxxxxx' &&
           confirmationTemplateId != 'template_confirmation' &&
           reminderTemplateId != 'template_reminder';
  }
  
  /// Get configuration status message
  static String get configurationStatus {
    if (!isConfigured) {
      return '''
❌ Email service not configured!

To set up email notifications:

1. Go to https://www.emailjs.com
2. Create a free account
3. Create an email service (Gmail, Outlook, etc.)
4. Create email templates
5. Update the configuration in lib/core/config/email_config.dart

Required configuration:
- serviceId: Your EmailJS service ID
- publicKey: Your EmailJS public key
- Template IDs for confirmation and reminder
''';
    }
    return '✅ Email service configured and ready!';
  }
}
