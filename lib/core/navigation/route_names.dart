class RouteNames {
  // Authentication Routes
  static const String login = '/login';
  static const String register = '/register';

  // Main App Routes
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String billing = '/billing';
  static const String wallet = '/wallet';
  static const String feedback = '/feedback';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String notifications = '/notifications';

  // Service Booking Routes
  static const String searchShops = '/search-shops';
  static const String shopDetails = '/shop-details';

  // Helper methods for route generation
  static String bookingRoute(String shopId, String shopName) =>
      '/booking/$shopId/${Uri.encodeComponent(shopName)}';

  // Appointment Routes
  static const String appointmentDetails = '/appointment';
  static const String serviceProgress = '/service-progress';

  // Billing Routes
  static const String invoiceDetails = '/invoice';
  static const String payment = '/payment';

  // Helper methods for route generation
  static String shopDetailsRoute(String shopId) => '/shop-details/$shopId';
  static String appointmentDetailsRoute(String appointmentId) =>
      '/appointment/$appointmentId';
  static String serviceProgressRoute(String appointmentId) =>
      '/service-progress/$appointmentId';
  static String invoiceDetailsRoute(String invoiceId) => '/invoice/$invoiceId';
  static String paymentRoute(String invoiceId) => '/payment/$invoiceId';
}
