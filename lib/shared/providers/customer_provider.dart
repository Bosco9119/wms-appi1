import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/persistent_auth_service.dart';
import '../models/customer_model.dart';
import '../models/vehicle_model.dart';
import '../models/appointment_model.dart';

class CustomerProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final PersistentAuthService _persistentAuth = PersistentAuthService();

  // State variables
  Customer? _currentCustomer;
  List<Vehicle> _vehicles = [];
  List<Appointment> _appointments = [];
  List<Map<String, dynamic>> _lastVisitedShops = [];
  List<Map<String, dynamic>> _nearbyShops = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  // Getters
  Customer? get currentCustomer => _currentCustomer;
  List<Vehicle> get vehicles => _vehicles;
  List<Appointment> get appointments => _appointments;
  List<Map<String, dynamic>> get lastVisitedShops => _lastVisitedShops;
  List<Map<String, dynamic>> get nearbyShops => _nearbyShops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentCustomer != null;
  bool get disposed => _disposed;

  // Notification count (placeholder)
  int get unreadNotificationsCount {
    // This would be calculated from notifications
    return 1; // Placeholder
  }

  // Initialize provider
  Future<void> initialize() async {
    await loadCustomerData();
  }

  // Load customer data from Firebase with local backup
  Future<void> loadCustomerData() async {
    _setLoading(true);
    try {
      print('🔄 CustomerProvider: Starting loadCustomerData...');

      // Add a small delay to ensure Firebase Auth state is fully established
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to get customer data with retry mechanism
      _currentCustomer = await _loadCustomerWithRetry();

      if (_currentCustomer != null) {
        print('✅ CustomerProvider: Customer data loaded successfully');
        print(
          '📱 CustomerProvider: Customer name: ${_currentCustomer!.fullName}',
        );
        print(
          '📱 CustomerProvider: Customer email: ${_currentCustomer!.email}',
        );
        print(
          '📱 CustomerProvider: Customer phone number: ${_currentCustomer!.phoneNumber}',
        );
        await _loadVehicles();
        await _loadAppointments();
        await _loadLastVisitedShops();
        await _loadNearbyShops();

        // Notify listeners that customer data has been loaded
        print(
          '🔄 CustomerProvider: Notifying listeners of customer data update',
        );
        _safeNotifyListeners();
      } else {
        print('❌ CustomerProvider: No customer data found after retries');
      }
    } catch (e) {
      print('❌ CustomerProvider: Error loading customer data: $e');
      _setError('Failed to load customer data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load customer data with retry mechanism
  Future<Customer?> _loadCustomerWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      print(
        '🔄 CustomerProvider: Attempt $attempt/$maxRetries to load customer data...',
      );

      try {
        final Customer? customer = await _persistentAuth.getCurrentCustomer();
        if (customer != null) {
          print('✅ CustomerProvider: Customer data found on attempt $attempt');
          return customer;
        }

        if (attempt < maxRetries) {
          print(
            '⏳ CustomerProvider: No customer data found, retrying in 1 second...',
          );
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        print('❌ CustomerProvider: Error on attempt $attempt: $e');
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    return null;
  }

  /// Login customer
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔄 CustomerProvider: Starting login process...');

      final Customer? customer = await _authService.loginCustomer(
        email: email,
        password: password,
      );

      if (customer != null) {
        _currentCustomer = customer;
        print('✅ CustomerProvider: Login successful for ${customer.fullName}');

        // Load related data from Firebase
        await _loadVehicles();
        await _loadAppointments();
        await _loadLastVisitedShops();
        await _loadNearbyShops();

        _setLoading(false);
        _safeNotifyListeners();
        return true;
      } else {
        _setError('Login failed - no customer data found');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ CustomerProvider Login Error: $e');
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Register new customer
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔄 CustomerProvider: Starting registration process...');
      print(
        '📱 Registration data - Email: $email, Name: $fullName, Phone: $phoneNumber',
      );

      final Customer customer = await _authService.registerCustomer(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      _currentCustomer = customer;
      print(
        '✅ CustomerProvider: Registration successful for ${customer.fullName}',
      );
      print('📱 Customer phone number: ${customer.phoneNumber}');

      // Load related data
      await _loadVehicles();
      await _loadAppointments();
      await _loadLastVisitedShops();
      await _loadNearbyShops();

      _setLoading(false);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      print('❌ CustomerProvider Registration Error: $e');
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Logout customer
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();

      // Clear persistent auth data
      await _persistentAuth.clearAuthState();

      // Clear all local data
      _currentCustomer = null;
      _vehicles.clear();
      _appointments.clear();
      _lastVisitedShops.clear();
      _nearbyShops.clear();

      _setLoading(false);
      _safeNotifyListeners();
      print('✅ CustomerProvider: Logout successful');
    } catch (e) {
      print('❌ CustomerProvider Logout Error: $e');
      _setError('Logout failed: $e');
      _setLoading(false);
    }
  }

  /// Update customer profile
  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      if (_currentCustomer == null) return false;

      _setLoading(true);
      _clearError();

      final updatedCustomer = Customer(
        id: _currentCustomer!.id,
        email: _currentCustomer!.email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImageUrl: _currentCustomer!.profileImageUrl,
        createdAt: _currentCustomer!.createdAt,
        updatedAt: DateTime.now(),
      );

      await _authService.updateProfile(updatedCustomer);
      _currentCustomer = updatedCustomer;

      _setLoading(false);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      print('❌ CustomerProvider Update Error: $e');
      _setError('Profile update failed: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Load vehicles (placeholder - would load from Firebase)
  Future<void> _loadVehicles() async {
    // TODO: Implement Firebase vehicle loading
    _vehicles = [];
  }

  /// Load appointments (placeholder - would load from Firebase)
  Future<void> _loadAppointments() async {
    // TODO: Implement Firebase appointment loading
    _appointments = [];
  }

  /// Load last visited shops (placeholder - would load from Firebase)
  Future<void> _loadLastVisitedShops() async {
    // TODO: Implement Firebase last visited shops loading
    _lastVisitedShops = [];
  }

  /// Load nearby shops (placeholder - would load from Firebase)
  Future<void> _loadNearbyShops() async {
    // TODO: Implement Firebase nearby shops loading
    _nearbyShops = [];
  }

  /// Add vehicle
  Future<bool> addVehicle(Vehicle vehicle) async {
    try {
      _vehicles.add(vehicle);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add vehicle: $e');
      return false;
    }
  }

  /// Add appointment
  Future<bool> addAppointment(Appointment appointment) async {
    try {
      _appointments.add(appointment);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add appointment: $e');
      return false;
    }
  }

  /// Clear error
  void _clearError() {
    _error = null;
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    if (!disposed) {
      notifyListeners();
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!disposed) {
      notifyListeners();
    }
  }

  /// Safe notify listeners
  void _safeNotifyListeners() {
    if (!disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
