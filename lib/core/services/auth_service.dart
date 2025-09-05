import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/customer_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Register new customer
  Future<Customer> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      print('🔥 Firebase Auth: Creating new user...');
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user == null) throw Exception('User creation failed');

      print('✅ Firebase Auth: User created successfully: ${user.uid}');

      // Create customer object
      final Customer customer = Customer(
        id: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      print('🔥 Firestore: Saving customer to Firestore...');
      await _firestore
          .collection('customers')
          .doc(user.uid)
          .set(customer.toMap());
      print('✅ Firestore: Customer saved successfully');

      return customer;
    } catch (e) {
      print('❌ AuthService Registration Error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  /// Login customer
  Future<Customer?> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      print('🔥 Firebase Auth: Signing in user...');

      // Use a try-catch to handle the PigeonUserDetails casting error
      User? user;
      try {
        final UserCredential userCredential = await _auth
            .signInWithEmailAndPassword(email: email, password: password);
        user = userCredential.user;
      } catch (authError) {
        print('⚠️ Auth Error (handling gracefully): $authError');

        // If it's the PigeonUserDetails casting error, check if user is actually authenticated
        if (authError.toString().contains('PigeonUserDetails') ||
            authError.toString().contains('List<Object?>')) {
          print(
            '🔄 Handling PigeonUserDetails error, checking current user...',
          );
          user = _auth.currentUser;
          if (user != null) {
            print('✅ User is actually authenticated: ${user.uid}');
          } else {
            throw authError;
          }
        } else {
          throw authError;
        }
      }

      if (user == null) throw Exception('Login failed - no user found');

      print('✅ Firebase Auth: User signed in successfully: ${user.uid}');

      // Get customer data from Firestore
      print('🔥 Firestore: Fetching customer data from Firestore...');
      final DocumentSnapshot doc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      Customer customer;
      if (!doc.exists) {
        print(
          '⚠️ Firestore: Customer data not found, creating basic customer...',
        );
        // Create a basic customer record if not found in Firestore
        customer = Customer(
          id: user.uid,
          email: email,
          fullName: user.displayName ?? 'User',
          phoneNumber: user.phoneNumber ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        await _firestore
            .collection('customers')
            .doc(user.uid)
            .set(customer.toMap());
        print('✅ Firestore: Basic customer created');
      } else {
        customer = Customer.fromMap(doc.data() as Map<String, dynamic>);
        print('✅ Firestore: Customer found: ${customer.fullName}');
      }

      // Customer data is now stored in Firebase only
      print('✅ Firebase: Customer data stored in Firestore');
      return customer;
    } catch (e) {
      print('❌ AuthService Login Error: $e');
      throw Exception('Login failed: $e');
    }
  }

  /// Logout customer
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('✅ AuthService: User logged out successfully');
    } catch (e) {
      print('❌ AuthService: Error during logout: $e');
      throw Exception('Logout failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ AuthService: Password reset email sent');
    } catch (e) {
      print('❌ AuthService: Error sending password reset: $e');
      throw Exception('Password reset failed: $e');
    }
  }

  /// Get current customer from Firebase
  Future<Customer?> getCurrentCustomer() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      // Get customer data from Firestore
      final DocumentSnapshot doc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return Customer.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ AuthService: Error getting current customer: $e');
      return null;
    }
  }

  /// Update customer profile
  Future<void> updateProfile(Customer customer) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Update in Firestore
      await _firestore
          .collection('customers')
          .doc(user.uid)
          .update(customer.toMap());

      print('✅ AuthService: Profile updated successfully');
    } catch (e) {
      print('❌ AuthService: Error updating profile: $e');
      throw Exception('Profile update failed: $e');
    }
  }

  /// Delete customer account
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Delete from Firestore
      await _firestore.collection('customers').doc(user.uid).delete();

      // Delete Firebase user
      await user.delete();

      print('✅ AuthService: Account deleted successfully');
    } catch (e) {
      print('❌ AuthService: Error deleting account: $e');
      throw Exception('Account deletion failed: $e');
    }
  }
}
