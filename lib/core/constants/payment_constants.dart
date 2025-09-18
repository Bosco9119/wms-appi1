class PaymentConstants {
  // Billplz Configuration
  static const String billplzSandboxUrl = 'https://www.billplz-sandbox.com/api/v3';
  static const String billplzProductionUrl = 'https://www.billplz.com/api/v3';
  
  // Firebase Cloud Functions URLs
  static const String createBillUrl = 'https://us-central1-wms-appi1.cloudfunctions.net/createBill';
  static const String paymentCallbackUrl = 'https://us-central1-wms-appi1.cloudfunctions.net/paymentCallback';
  static const String getPaymentStatusUrl = 'https://us-central1-wms-appi1.cloudfunctions.net/getPaymentStatus';
  static const String getCustomerPaymentsUrl = 'https://us-central1-wms-appi1.cloudfunctions.net/getCustomerPayments';
  
  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusPaid = 'paid';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusCancelled = 'cancelled';
  
  // Payment Methods
  static const String paymentMethodBillplz = 'billplz';
  static const String paymentMethodEwallet = 'ewallet';
  static const String paymentMethodCash = 'cash';
  
  // Currency
  static const String currencyCode = 'MYR';
  static const String currencySymbol = 'RM';
  
  // Payment Timeout (in minutes)
  static const int paymentTimeoutMinutes = 15;
  
  // Minimum and Maximum Amount
  static const double minimumAmount = 1.00;
  static const double maximumAmount = 10000.00;
  
  // Payment Description Templates
  static const String servicePaymentDescription = 'AutoAnywhere Service Payment';
  static const String repairPaymentDescription = 'Vehcle Repair Seirvice';
  static const String maintenancePaymentDescription = 'Vehicle Maintenance Service';
  static const String inspectionPaymentDescription = 'Vehicle Inspection Service';
  
  // Error Messages
  static const String errorInvalidAmount = 'Invalid payment amount';
  static const String errorMissingCustomerInfo = 'Missing customer information';
  static const String errorPaymentFailed = 'Payment failed. Please try again.';
  static const String errorNetworkError = 'Network error. Please check your connection.';
  static const String errorPaymentTimeout = 'Payment timeout. Please try again.';
  static const String errorInvalidBillId = 'Invalid bill ID';
  static const String errorPaymentNotFound = 'Payment not found';
  
  // Success Messages
  static const String successPaymentCreated = 'Payment bill created successfully';
  static const String successPaymentCompleted = 'Payment completed successfully';
  static const String successPaymentCancelled = 'Payment cancelled successfully';
  
  // UI Constants
  static const double paymentButtonHeight = 50.0;
  static const double paymentButtonBorderRadius = 8.0;
  static const double paymentCardBorderRadius = 12.0;
  static const double paymentCardElevation = 4.0;
  
  // Colors (you can customize these based on your app theme)
  static const int paymentSuccessColor = 0xFF4CAF50;
  static const int paymentPendingColor = 0xFFFF9800;
  static const int paymentFailedColor = 0xFFF44336;
  static const int paymentCancelledColor = 0xFF9E9E9E;
}
