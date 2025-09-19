# 📧 Email Notification Setup Guide

This guide will help you set up email notifications for the AutoAnywhere app to replace or supplement push notifications.

## 🚀 Quick Start

### 1. Configure Email Service (EmailJS)

1. **Create EmailJS Account**
   - Go to [https://www.emailjs.com](https://www.emailjs.com)
   - Sign up for a free account
   - Verify your email address

2. **Create Email Service**
   - In EmailJS dashboard, go to "Email Services"
   - Click "Add New Service"
   - Choose your email provider (Gmail, Outlook, etc.)
   - Follow the setup instructions
   - Note down your **Service ID**

3. **Create Email Templates**
   - Go to "Email Templates" in EmailJS dashboard
   - Create these 2 templates using the provided HTML files:
     - `confirmation_template.html` → Template ID: `template_confirmation`
     - `reminder_template.html` → Template ID: `template_reminder`

4. **Get Public Key**
   - Go to "Account" in EmailJS dashboard
   - Copy your **Public Key**

5. **Update Configuration**
   - Open `lib/core/config/email_config.dart`
   - Replace the placeholder values:
     ```dart
     static const String serviceId = 'your_actual_service_id';
     static const String publicKey = 'your_actual_public_key';
     ```

### 2. Configure Notification Preferences

Open `lib/core/config/notification_preferences.dart` and set your preferences:

```dart
class NotificationPreferences {
  // Choose notification method
  static const bool useEmailNotifications = true;  // Enable email notifications
  static const bool usePushNotifications = false;  // Disable push notifications
  
  // Email notification settings
  static const bool sendConfirmationEmails = true;
  static const bool sendReminderEmails = true;
  static const bool sendCancellationEmails = true;
  static const bool sendRescheduleEmails = true;
}
```

### 3. Test the System

Run the test script to verify everything works:

```bash
cd wms-appi1
dart test_email_system.dart
```

## 📧 Email Templates

The app includes 2 professional email templates:

### 1. **Confirmation Email**
- Sent immediately when appointment is booked
- Includes all appointment details
- Professional styling with shop information

### 2. **Reminder Email**
- Sent 12 hours before appointment
- Friendly reminder with important notes
- Clear appointment details

## 🔧 Configuration Options

### Email Service Configuration (`email_config.dart`)

```dart
class EmailConfig {
  // EmailJS settings
  static const String serviceId = 'your_service_id';
  static const String publicKey = 'your_public_key';
  
  // Template IDs
  static const String confirmationTemplateId = 'template_confirmation';
  static const String reminderTemplateId = 'template_reminder';
  static const String cancellationTemplateId = 'template_cancellation';
  static const String rescheduleTemplateId = 'template_reschedule';
  
  // Test mode
  static const bool isTestMode = true;  // Set to false for production
  static const String testEmail = 'test@example.com';
}
```

### Notification Preferences (`notification_preferences.dart`)

```dart
class NotificationPreferences {
  // Notification methods
  static const bool useEmailNotifications = true;
  static const bool usePushNotifications = false;
  
  // Individual email types
  static const bool sendConfirmationEmails = true;
  static const bool sendReminderEmails = true;
  static const bool sendCancellationEmails = true;
  static const bool sendRescheduleEmails = true;
}
```

## 🧪 Testing

### Test Email Service
```dart
final emailService = EmailNotificationService();
await emailService.testEmailService();
```

### Test Email Reminders
```dart
final emailScheduler = EmailReminderScheduler();
await emailScheduler.testEmailReminderSystem();
```

### Test Complete Flow
```bash
dart test_email_system.dart
```

## 📱 App Integration

The email system is automatically integrated with:

- **Booking Confirmation**: Emails sent when appointments are booked
- **Reminder Scheduling**: 12-hour and 3-hour email reminders
- **Cancellation Notifications**: Emails sent when appointments are cancelled
- **Reschedule Notifications**: Emails sent when appointments are rescheduled

## 🔍 Troubleshooting

### Common Issues

1. **"Email service not configured"**
   - Check your EmailJS credentials in `email_config.dart`
   - Ensure all template IDs match your EmailJS templates

2. **"Failed to send email"**
   - Check your EmailJS service is active
   - Verify template IDs are correct
   - Check email addresses are valid

3. **"No emails received"**
   - Check spam folder
   - Verify test mode settings
   - Check EmailJS dashboard for delivery status

### Debug Information

The app provides detailed logging:
- Email service initialization
- Template configuration status
- Email sending attempts
- Error messages and solutions

## 🚀 Production Deployment

1. **Set Production Mode**
   ```dart
   static const bool isTestMode = false;
   ```

2. **Use Real Email Addresses**
   - Remove test email overrides
   - Use actual customer email addresses

3. **Monitor Email Delivery**
   - Check EmailJS dashboard
   - Monitor bounce rates
   - Set up email analytics

## 📊 Benefits of Email Notifications

- ✅ **More Reliable**: Emails don't depend on device being active
- ✅ **Better Delivery**: Emails are less likely to be blocked
- ✅ **Rich Content**: Can include detailed appointment information
- ✅ **Professional**: Looks more professional than push notifications
- ✅ **Accessible**: Can be read on any device with email access
- ✅ **Persistent**: Emails remain in inbox for reference

## 🎯 Next Steps

1. Configure EmailJS account and templates
2. Update configuration files with your credentials
3. Test the system with test emails
4. Deploy to production
5. Monitor email delivery and customer feedback

---

**Need Help?** Check the console output for detailed error messages and configuration status.
