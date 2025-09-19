class NotificationPreferences {
  // Choose notification method
  static const bool useEmailNotifications = true;  // Set to true for email-only
  static const bool usePushNotifications = false;  // Set to false to disable push
  
  // Email notification settings
  static const bool sendConfirmationEmails = true;
  static const bool sendReminderEmails = true;
  static const bool sendCancellationEmails = true;
  static const bool sendRescheduleEmails = true;
  
  // Push notification settings (only used if usePushNotifications = true)
  static const bool sendPushConfirmations = false;
  static const bool sendPushReminders = false;
  static const bool sendPushCancellations = false;
  static const bool sendPushReschedules = false;
  
  /// Get notification method description
  static String get notificationMethod {
    if (useEmailNotifications && !usePushNotifications) {
      return 'Email Only';
    } else if (!useEmailNotifications && usePushNotifications) {
      return 'Push Only';
    } else if (useEmailNotifications && usePushNotifications) {
      return 'Email + Push';
    } else {
      return 'Disabled';
    }
  }
  
  /// Check if any notifications are enabled
  static bool get hasNotificationsEnabled {
    return useEmailNotifications || usePushNotifications;
  }
}
