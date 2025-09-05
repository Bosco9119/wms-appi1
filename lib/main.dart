import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/login_router.dart';
import 'core/services/persistent_auth_service.dart';
import 'shared/providers/customer_provider.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('🔥 Firebase initialized successfully!');
  print('📱 Project ID: ${Firebase.app().options.projectId}');

  runApp(const AuthWrapper());
}

class WMSApp extends StatelessWidget {
  const WMSApp({super.key});

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
          // User is logged in, load their data and show main app
          print('✅ AuthWrapper: User is authenticated: ${snapshot.data!.uid}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CustomerProvider>().loadCustomerData();
          });
          return const WMSApp();
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
              child: const Icon(
                Icons.build_circle,
                color: const Color(0xFFCF2049),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            const Text(
              'WMS App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Workshop Management System',
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
