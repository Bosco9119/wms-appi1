import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/customer_model.dart';
import '../database/database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

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
      print(
        '📱 Registration details - Email: $email, Name: $fullName, Phone: $phoneNumber',
      );

      // Use a try-catch to handle the PigeonUserDetails casting error
      User? user;
      try {
        final UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);
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

      if (user == null) throw Exception('User creation failed');

      print('✅ Firebase Auth: User created successfully: ${user.uid}');
      print('📱 Firebase User email: ${user.email}');
      print('📱 Firebase User displayName: ${user.displayName}');
      print('📱 Firebase User phoneNumber: ${user.phoneNumber}');

      // Create customer object
      final Customer customer = Customer(
        id: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📝 Customer object created: ${customer.toString()}');

      // Test Firestore connectivity first
      print('🔥 Firestore: Testing Firestore connectivity...');
      try {
        await _firestore.collection('test').doc('connectivity').set({
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
        print('✅ Firestore: Connectivity test successful');

        // Clean up test document
        await _firestore.collection('test').doc('connectivity').delete();
        print('✅ Firestore: Test document cleaned up');
      } catch (testError) {
        print('❌ Firestore Connectivity Test Error: $testError');
        throw Exception('Firestore connectivity test failed: $testError');
      }

      // Check if customer already exists
      print('🔥 Firestore: Checking if customer already exists...');
      final DocumentSnapshot existingDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      if (existingDoc.exists) {
        print(
          '⚠️ Firestore: Customer already exists, updating instead of creating',
        );
        try {
          await _firestore
              .collection('customers')
              .doc(user.uid)
              .update(customer.toMap());
          print('✅ Firestore: Customer updated successfully');
        } catch (updateError) {
          print('❌ Firestore Update Error: $updateError');
          throw Exception(
            'Failed to update customer data in Firestore: $updateError',
          );
        }
      } else {
        // Save to Firestore
        print('🔥 Firestore: Saving new customer to Firestore...');
        print('📱 Customer data to save: ${customer.toMap()}');

        try {
          await _firestore
              .collection('customers')
              .doc(user.uid)
              .set(customer.toMap());
          print('✅ Firestore: Customer saved successfully');
        } catch (firestoreError) {
          print('❌ Firestore Save Error: $firestoreError');
          throw Exception(
            'Failed to save customer data to Firestore: $firestoreError',
          );
        }
      }

      // Verify the data was saved correctly
      print('🔄 AuthService: Verifying customer data was saved...');
      try {
        final DocumentSnapshot verifyDoc = await _firestore
            .collection('customers')
            .doc(user.uid)
            .get();

        print('📱 Verification: Document exists: ${verifyDoc.exists}');
        print('📱 Verification: Document ID: ${verifyDoc.id}');
        print('📱 Verification: Document path: ${verifyDoc.reference.path}');

        if (verifyDoc.exists) {
          final savedData = verifyDoc.data() as Map<String, dynamic>;
          print('✅ Verification: Customer data saved correctly');
          print('📱 Full saved data: $savedData');
          print('📱 Phone number in DB: ${savedData['phone_number']}');
          print('📱 Full name in DB: ${savedData['full_name']}');
          print('📱 Email in DB: ${savedData['email']}');
          print('📱 Created at in DB: ${savedData['created_at']}');
          print('📱 Updated at in DB: ${savedData['updated_at']}');
        } else {
          print('❌ Verification: Customer data not found in Firestore');
          print('❌ This means the data was not saved properly!');
          print('❌ Document path: customers/${user.uid}');
        }
      } catch (verifyError) {
        print('❌ Verification Error: $verifyError');
        print('❌ This means we cannot read the data back from Firestore!');
      }

      // Save customer data locally for faster access
      print('💾 Local DB: Saving customer to local database...');
      try {
        await _databaseService.insertCustomer(customer);
        print('✅ Local DB: Customer data saved locally');
      } catch (e) {
        print('⚠️ Local DB: Error saving customer locally: $e');
        // Don't throw error, just log it
      }

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
        final customerData = doc.data() as Map<String, dynamic>;
        print('📱 Customer data from Firestore: $customerData');
        customer = Customer.fromMap(customerData);
        print('✅ Firestore: Customer found: ${customer.fullName}');
        print('📱 Phone number: ${customer.phoneNumber}');
      }

      // Save customer data locally for faster access
      print('💾 Local DB: Saving customer to local database...');
      try {
        await _databaseService.insertCustomer(customer);
        print('✅ Local DB: Customer data saved locally');
      } catch (e) {
        print('⚠️ Local DB: Error saving customer locally: $e');
        // Don't throw error, just log it
      }

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

  /// Test Firestore write permissions
  Future<bool> testFirestoreWrite() async {
    try {
      print('🧪 Testing Firestore write permissions...');

      // Try to write a test document
      await _firestore.collection('test').doc('write_test').set({
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'This is a test write operation',
      });

      print('✅ Firestore write test successful');

      // Clean up test document
      await _firestore.collection('test').doc('write_test').delete();
      print('✅ Test document cleaned up');

      return true;
    } catch (e) {
      print('❌ Firestore write test failed: $e');
      return false;
    }
  }
}
