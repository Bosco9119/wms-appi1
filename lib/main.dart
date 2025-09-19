import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/login_router.dart';
import 'core/services/persistent_auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_settings_service.dart';
import 'core/services/reminder_scheduler.dart';
import 'core/services/emailjs_service.dart';
import 'core/config/email_config.dart';
import 'shared/providers/customer_provider.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notification Service
  print('🔔 Initializing notification service...');
  final notificationService = NotificationService();
  await notificationService.initialize();

  print('🔔 Requesting notification permissions...');
  final permissionGranted = await notificationService.requestPermissions();

  print('🔔 Checking exact alarm permissions...');
  final exactAlarmGranted = await notificationService
      .requestExactAlarmPermission();

  // Initialize EmailJS Service
  print('📧 Initializing EmailJS service...');
  final emailService = EmailJSService();
  
  // Test email service
  print('📧 Testing EmailJS service...');
  await emailService.testEmailJSService();

  // Reset notification preferences to remove testing intervals
  print('🔔 Resetting notification preferences to production defaults...');
  final settingsService = NotificationSettingsService();
  await settingsService.resetToProductionDefaults();

  // Clean up any expired reminders from previous sessions
  print('🧹 Cleaning up expired reminders...');
  final reminderScheduler = ReminderScheduler();
  await reminderScheduler.cleanupExpiredReminders();

  // Check for upcoming appointments and show reminder if within 12 hours
  print('🔍 Checking for upcoming appointments...');
  await reminderScheduler.checkUpcomingAppointments();

  notificationService.setupNotificationListeners();

  print('🔥 Firebase initialized successfully!');
  print('📱 Project ID: ${Firebase.app().options.projectId}');
  print('🔔 Notification service initialized!');
  print('🔔 Notification permissions granted: $permissionGranted');
  print('⏰ Exact alarm permissions granted: $exactAlarmGranted');

  // Test notification to verify it's working
  if (permissionGranted) {
    print('🔔 Testing immediate notification...');
    await notificationService.showImmediateNotification(
      title: 'AutoAnywhere App Started',
      body: 'Notification system is working!',
      payload: 'app_start',
    );
    print('✅ Test notification sent - check your device!');
  } else {
    print('❌ Cannot send test notification - permission denied');
  }

  runApp(const AuthWrapper());
}

class AutoAnywhereApp extends StatelessWidget {
  const AutoAnywhereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CustomerProvider()..loadCustomerData(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCF2049),
            primary: const Color(0xFFCF2049),
            secondary: Colors.blue,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: const Color(0xFFCF2049),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF2049),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final PersistentAuthService _persistentAuth = PersistentAuthService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  /// Check for upcoming appointments and show reminder
  Future<void> _checkUpcomingAppointments() async {
    try {
      final reminderScheduler = ReminderScheduler();
      await reminderScheduler.checkUpcomingAppointments();
    } catch (e) {
      print('❌ Error checking upcoming appointments in AuthWrapper: $e');
    }
  }

  Future<void> _checkAuthState() async {
    try {
      print('🔄 AuthWrapper: Checking persistent auth state...');
      final bool isAuth = await _persistentAuth.isUserAuthenticated();

      setState(() {
        _isInitializing = false;
      });

      print('✅ AuthWrapper: Auth check complete - isAuthenticated: $isAuth');
    } catch (e) {
      print('❌ AuthWrapper: Error checking auth state: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing - wrapped in MaterialApp
    if (_isInitializing) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCF2049),
            primary: const Color(0xFFCF2049),
            secondary: Colors.blue,
          ),
          useMaterial3: true,
        ),
      );
    }

    // Listen to Firebase auth state changes for real-time updates
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print(
          '🔄 AuthWrapper: StreamBuilder - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data?.uid}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFCF2049),
                primary: const Color(0xFFCF2049),
                secondary: Colors.blue,
              ),
              useMaterial3: true,
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, show main app
          print('✅ AuthWrapper: User is authenticated: ${snapshot.data!.uid}');
          print('📱 User email: ${snapshot.data!.email}');
          print('📱 User display name: ${snapshot.data!.displayName}');
          print('📱 User phone: ${snapshot.data!.phoneNumber}');
          
          // Check for upcoming appointments when user logs in
          _checkUpcomingAppointments();
          
          return const AutoAnywhereApp();
        } else {
          // User is not logged in, show login app
          print('❌ AuthWrapper: User is not logged in, redirecting to login');
          return const LoginApp();
        }
      },
    );
  }
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CustomerProvider())],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCF2049),
            primary: const Color(0xFFCF2049),
            secondary: Colors.blue,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: const Color(0xFFCF2049),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF2049),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        routerConfig: LoginRouter.router,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add any initialization logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCF2049),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/AutoAnywhere@logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            const Text(
              'AutoAnywhere',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automotive Service Management',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
