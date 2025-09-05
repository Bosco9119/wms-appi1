class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.wms.greenstem.com.my/v1';
  static const String imageBaseUrl = 'https://images.wms.greenstem.com.my';
  
  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  
  // Customer Endpoints
  static const String customerProfile = '/customer/profile';
  static const String updateProfile = '/customer/profile/update';
  static const String customerVehicles = '/customer/vehicles';
  static const String addVehicle = '/customer/vehicles/add';
  static const String updateVehicle = '/customer/vehicles/update';
  static const String deleteVehicle = '/customer/vehicles/delete';
  
  // Workshop Endpoints
  static const String workshops = '/workshops';
  static const String workshopDetails = '/workshops/{id}';
  static const String workshopServices = '/workshops/{id}/services';
  static const String searchWorkshops = '/workshops/search';
  static const String nearbyWorkshops = '/workshops/nearby';
  
  // Appointment Endpoints
  static const String appointments = '/appointments';
  static const String appointmentDetails = '/appointments/{id}';
  static const String bookAppointment = '/appointments/book';
  static const String cancelAppointment = '/appointments/{id}/cancel';
  static const String rescheduleAppointment = '/appointments/{id}/reschedule';
  static const String appointmentHistory = '/appointments/history';
  
  // Service Progress Endpoints
  static const String serviceProgress = '/appointments/{id}/progress';
  static const String updateProgress = '/appointments/{id}/progress/update';
  
  // Billing Endpoints
  static const String invoices = '/invoices';
  static const String invoiceDetails = '/invoices/{id}';
  static const String paymentHistory = '/payments/history';
  static const String processPayment = '/payments/process';
  
  // Feedback Endpoints
  static const String feedback = '/feedback';
  static const String feedbackHistory = '/feedback/history';
  static const String submitFeedback = '/feedback/submit';
  
  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String markAsRead = '/notifications/{id}/read';
  static const String notificationSettings = '/notifications/settings';
  
  // E-Wallet Endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String addFunds = '/wallet/add-funds';
  static const String withdrawFunds = '/wallet/withdraw-funds';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Timeout Settings
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
}
