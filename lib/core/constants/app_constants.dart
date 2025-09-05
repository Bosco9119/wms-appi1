class AppConstants {
  // App Information
  static const String appName = 'WMS Customer App';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.wms.greenstem.com.my';
  static const int apiTimeout = 30000; // 30 seconds
  
  // Database Configuration
  static const String databaseName = 'wms_customer.db';
  static const int databaseVersion = 1;
  
  // Firebase Configuration
  static const String firebaseProjectId = 'wms-customer-app';
  
  // Service Types
  static const List<String> serviceTypes = [
    'All',
    'Oil Change',
    'Tyres',
    'Aircond',
    'Engine Service',
    'Transmission',
    'Suspension',
    'Brake Service',
    'Battery Service',
    'General Repair'
  ];
  
  // Service Status
  static const List<String> serviceStatuses = [
    'Scheduled',
    'In Inspection',
    'Parts Awaiting',
    'In Repair',
    'Ready for Collection',
    'Completed',
    'Cancelled'
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Credit Card',
    'Debit Card',
    'E-Wallet',
    'Bank Transfer',
    'Cash'
  ];
  
  // Notification Types
  static const String reminderNotification = 'reminder';
  static const String statusUpdateNotification = 'status_update';
  static const String paymentNotification = 'payment';
  static const String feedbackNotification = 'feedback';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
