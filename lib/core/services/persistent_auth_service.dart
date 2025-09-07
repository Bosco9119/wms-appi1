import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/customer_model.dart';

class PersistentAuthService {
  static final PersistentAuthService _instance =
      PersistentAuthService._internal();
  factory PersistentAuthService() => _instance;
  PersistentAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys for SharedPreferences
  static const String _authStateKey = 'auth_state';
  static const String _userUidKey = 'user_uid';
  static const String _lastLoginKey = 'last_login';
  static const String _customerDataKey = 'customer_data';

  /// Check if user is authenticated (with local backup)
  Future<bool> isUserAuthenticated() async {
    try {
      // First check Firebase Auth
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('✅ PersistentAuth: Firebase user found: ${firebaseUser.uid}');
        await _saveAuthState(firebaseUser.uid);
        return true;
      }

      // If no Firebase user, check local storage
      final String? localUid = await _getLocalUserUid();
      if (localUid != null) {
        print(
          '🔄 PersistentAuth: Local user found, verifying with Firebase...',
        );
        // Try to verify with Firebase (this might fail if user was deleted)
        try {
          final DocumentSnapshot doc = await _firestore
              .collection('customers')
              .doc(localUid)
              .get();

          if (doc.exists) {
            print('✅ PersistentAuth: Local user verified with Firebase');
            return true;
          } else {
            print(
              '❌ PersistentAuth: Local user not found in Firebase, clearing local data',
            );
            await _clearAuthState();
            return false;
          }
        } catch (e) {
          print('⚠️ PersistentAuth: Error verifying local user: $e');
          // If verification fails, clear local data
          await _clearAuthState();
          return false;
        }
      }

      print('❌ PersistentAuth: No authenticated user found');
      return false;
    } catch (e) {
      print('❌ PersistentAuth: Error checking authentication: $e');
      return false;
    }
  }

  /// Get current user with local backup
  Future<User?> getCurrentUser() async {
    try {
      // First try Firebase Auth
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _saveAuthState(firebaseUser.uid);
        return firebaseUser;
      }

      // If no Firebase user, check if we have local data
      final String? localUid = await _getLocalUserUid();
      if (localUid != null) {
        print(
          '🔄 PersistentAuth: Attempting to restore user from local data...',
        );
        // Note: We can't restore the actual User object from local storage
        // This is a limitation - we can only check if user exists
        return null;
      }

      return null;
    } catch (e) {
      print('❌ PersistentAuth: Error getting current user: $e');
      return null;
    }
  }

  /// Get customer data with local backup
  Future<Customer?> getCurrentCustomer() async {
    try {
      print('🔄 PersistentAuth: Getting current customer...');

      // First try Firebase
      final User? user = _auth.currentUser;
      print('📱 PersistentAuth: Firebase user: ${user?.uid}');

      if (user != null) {
        final Customer? customer = await _getCustomerFromFirebase(user.uid);
        if (customer != null) {
          print('✅ PersistentAuth: Customer found in Firebase, saving locally');
          await _saveCustomerData(customer);
          return customer;
        } else {
          print(
            '❌ PersistentAuth: No customer found in Firebase for UID: ${user.uid}',
          );
        }
      } else {
        print('❌ PersistentAuth: No Firebase user found');
      }

      // If no Firebase user or customer, try local storage
      print('🔄 PersistentAuth: Trying local storage...');
      final Customer? localCustomer = await _getCustomerFromLocal();
      if (localCustomer != null) {
        print('✅ PersistentAuth: Customer data restored from local storage');
        print(
          '📱 PersistentAuth: Local customer name: ${localCustomer.fullName}',
        );
        print(
          '📱 PersistentAuth: Local customer email: ${localCustomer.email}',
        );
        return localCustomer;
      } else {
        print('❌ PersistentAuth: No customer data found in local storage');
      }

      return null;
    } catch (e) {
      print('❌ PersistentAuth: Error getting current customer: $e');
      return null;
    }
  }

  /// Save authentication state locally
  Future<void> _saveAuthState(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authStateKey, 'authenticated');
      await prefs.setString(_userUidKey, uid);
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
      print('✅ PersistentAuth: Auth state saved locally');
    } catch (e) {
      print('❌ PersistentAuth: Error saving auth state: $e');
    }
  }

  /// Get local user UID
  Future<String?> _getLocalUserUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? authState = prefs.getString(_authStateKey);
      if (authState == 'authenticated') {
        return prefs.getString(_userUidKey);
      }
      return null;
    } catch (e) {
      print('❌ PersistentAuth: Error getting local user UID: $e');
      return null;
    }
  }

  /// Save customer data locally
  Future<void> _saveCustomerData(Customer customer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customerDataKey, customer.toJson());
      print('✅ PersistentAuth: Customer data saved locally');
    } catch (e) {
      print('❌ PersistentAuth: Error saving customer data: $e');
    }
  }

  /// Get customer data from local storage
  Future<Customer?> _getCustomerFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customerJson = prefs.getString(_customerDataKey);
      if (customerJson != null) {
        return Customer.fromJson(customerJson);
      }
      return null;
    } catch (e) {
      print('❌ PersistentAuth: Error getting customer from local: $e');
      return null;
    }
  }

  /// Get customer data from Firebase
  Future<Customer?> _getCustomerFromFirebase(String uid) async {
    try {
      print(
        '🔥 PersistentAuth: Fetching customer data from Firebase for UID: $uid',
      );
      final DocumentSnapshot doc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();

      if (!doc.exists) {
        print('❌ PersistentAuth: Customer document not found in Firestore');
        return null;
      }

      final customerData = doc.data() as Map<String, dynamic>;
      print(
        '✅ PersistentAuth: Customer data found in Firestore: $customerData',
      );
      final customer = Customer.fromMap(customerData);
      print(
        '📱 PersistentAuth: Customer phone number: ${customer.phoneNumber}',
      );
      return customer;
    } catch (e) {
      print('❌ PersistentAuth: Error getting customer from Firebase: $e');
      return null;
    }
  }

  /// Clear all authentication data
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authStateKey);
      await prefs.remove(_userUidKey);
      await prefs.remove(_lastLoginKey);
      await prefs.remove(_customerDataKey);
      print('✅ PersistentAuth: Auth state cleared');
    } catch (e) {
      print('❌ PersistentAuth: Error clearing auth state: $e');
    }
  }

  /// Clear all authentication data (public method)
  Future<void> clearAuthState() async {
    await _clearAuthState();
  }

  /// Check if local data is stale (older than 7 days)
  Future<bool> isLocalDataStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastLoginStr = prefs.getString(_lastLoginKey);
      if (lastLoginStr == null) return true;

      final DateTime lastLogin = DateTime.parse(lastLoginStr);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(lastLogin);

      return difference.inDays > 7; // Consider stale after 7 days
    } catch (e) {
      print('❌ PersistentAuth: Error checking data staleness: $e');
      return true; // If error, consider stale
    }
  }

  /// Force refresh from Firebase
  Future<Customer?> refreshCustomerData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final Customer? customer = await _getCustomerFromFirebase(user.uid);
      if (customer != null) {
        await _saveCustomerData(customer);
        print('✅ PersistentAuth: Customer data refreshed from Firebase');
      }
      return customer;
    } catch (e) {
      print('❌ PersistentAuth: Error refreshing customer data: $e');
      return null;
    }
  }
}
