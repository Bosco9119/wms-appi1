import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../modules/customer/screens/customer_home_screen.dart';
import '../../modules/schedule/screens/schedule_screen.dart';
import '../../modules/billing/screens/billing_screen.dart';
import '../../modules/e_wallet/screens/wallet_screen.dart';
import '../../modules/feedback/screens/feedback_screen.dart';
import '../../modules/customer/screens/service_booking_screen.dart';
import '../../modules/customer/screens/shop_search_screen.dart';
import '../../modules/customer/screens/shop_details_screen.dart';
import '../../modules/schedule/screens/appointment_details_screen.dart';
import '../../modules/schedule/screens/service_progress_screen.dart';
import '../../modules/billing/screens/invoice_details_screen.dart';
import '../../modules/billing/screens/payment_screen.dart';
import '../../shared/widgets/persistent_layout.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/home',
    routes: [
      // Main App Routes with Shell
      ShellRoute(
        builder: (context, state, child) {
          return WillPopScope(
            onWillPop: () async {
              // If we're on the home page, show exit confirmation
              if (state.uri.path == '/home') {
                final bool? shouldExit = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Exit App'),
                      content: const Text(
                        'Are you sure you want to exit the app?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Exit'),
                        ),
                      ],
                    );
                  },
                );
                return shouldExit ?? false;
              }
              // For other pages, go back to home
              context.go('/home');
              return false;
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const PersistentPage(
              title: 'Home',
              child: CustomerHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/schedule',
            name: 'schedule',
            builder: (context, state) => const PersistentPage(
              title: 'Service Schedule',
              child: ScheduleScreen(),
            ),
          ),
          GoRoute(
            path: '/billing',
            name: 'billing',
            builder: (context, state) => const PersistentPage(
              title: 'Billing & Invoices',
              child: BillingScreen(),
            ),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) =>
                const PersistentPage(title: 'E-Wallet', child: WalletScreen()),
          ),
          GoRoute(
            path: '/feedback',
            name: 'feedback',
            builder: (context, state) => const PersistentPage(
              title: 'Feedback',
              child: FeedbackScreen(),
            ),
          ),

          // Service Booking Routes
          GoRoute(
            path: '/booking',
            name: 'booking',
            builder: (context, state) => const PersistentPage(
              title: 'Book Service',
              child: ServiceBookingScreen(),
            ),
          ),
          GoRoute(
            path: '/search-shops',
            name: 'search-shops',
            builder: (context, state) => const PersistentPage(
              title: 'Search Shops',
              child: ShopSearchScreen(),
            ),
          ),
          GoRoute(
            path: '/shop-details/:shopId',
            name: 'shop-details',
            builder: (context, state) {
              final shopId = state.pathParameters['shopId']!;
              return PersistentPage(
                title: 'Shop Details',
                child: ShopDetailsScreen(shopId: shopId),
              );
            },
          ),

          // Appointment Routes
          GoRoute(
            path: '/appointment/:appointmentId',
            name: 'appointment-details',
            builder: (context, state) {
              final appointmentId = state.pathParameters['appointmentId']!;
              return PersistentPage(
                title: 'Appointment Details',
                child: AppointmentDetailsScreen(appointmentId: appointmentId),
              );
            },
          ),
          GoRoute(
            path: '/service-progress/:appointmentId',
            name: 'service-progress',
            builder: (context, state) {
              final appointmentId = state.pathParameters['appointmentId']!;
              return PersistentPage(
                title: 'Service Progress',
                child: ServiceProgressScreen(appointmentId: appointmentId),
              );
            },
          ),

          // Billing Routes
          GoRoute(
            path: '/invoice/:invoiceId',
            name: 'invoice-details',
            builder: (context, state) {
              final invoiceId = state.pathParameters['invoiceId']!;
              return PersistentPage(
                title: 'Invoice Details',
                child: InvoiceDetailsScreen(invoiceId: invoiceId),
              );
            },
          ),
          GoRoute(
            path: '/payment/:invoiceId',
            name: 'payment',
            builder: (context, state) {
              final invoiceId = state.pathParameters['invoiceId']!;
              return PersistentPage(
                title: 'Payment',
                child: PaymentScreen(invoiceId: invoiceId),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: const Color(0xFFCF2049),
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;
}
