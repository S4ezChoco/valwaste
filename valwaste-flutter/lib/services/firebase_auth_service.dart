import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static UserModel? _currentUser;

  // Get current user
  static UserModel? get currentUser => _currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize the service
  static Future<void> initialize() async {
    try {
      // Listen to auth state changes and update current user
      _auth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          // User is signed in, fetch user data from Firestore
          await _fetchUserFromFirestore(firebaseUser.uid);
        } else {
          // User is signed out
          _currentUser = null;
        }
      });

      print('Firebase Auth Service initialized successfully');
    } catch (e) {
      print('Error initializing Firebase Auth Service: $e');
    }
  }

  // Fetch user data from Firestore
  static Future<void> _fetchUserFromFirestore(String uid) async {
    try {
      print('Fetching user data from Firestore for UID: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        print('User data fetched from Firestore: ${_currentUser!.name}');
      } else {
        print('User document does not exist in Firestore for UID: $uid');
      }
    } catch (e) {
      print('Error fetching user from Firestore: $e');
      print('Error type: ${e.runtimeType}');
      rethrow; // Re-throw to be caught by the calling method
    }
  }

  // Register new user with Firebase Auth and Firestore (Simplified)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    String? barangay = 'Valenzuela City',
  }) async {
    try {
      print('Starting registration for: $email');

      // Check if email already exists in Firestore
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {
          'success': false,
          'message':
              'An account already exists for that email. Please login instead.',
        };
      }

      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'message': 'Failed to create user account.'};
      }

      print('Firebase Auth user created with UID: ${firebaseUser.uid}');

      // Create user data for Firestore
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'barangay': barangay ?? 'Valenzuela City',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      print('User data prepared for Firestore: $userData');

      // Save to Firestore
      try {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData);

        print('User data saved to Firestore successfully');
      } catch (firestoreError) {
        print('Error saving to Firestore: $firestoreError');
        // If Firestore save fails, delete the Firebase Auth user
        try {
          await firebaseUser.delete();
          print('Firebase Auth user deleted due to Firestore save failure');
        } catch (deleteError) {
          print('Error deleting Firebase Auth user: $deleteError');
        }
        return {
          'success': false,
          'message': 'Failed to save user data. Please try again.',
        };
      }

      // Create user model for current user
      final userModel = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
        phone: phone,
        address: address,
        barangay: barangay ?? 'Valenzuela City',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set current user
      _currentUser = userModel;

      print('Registration completed successfully');
      return {
        'success': true,
        'message': 'Account created successfully! Welcome to ValWaste!',
        'user': userModel,
      };
    } on FirebaseAuthException catch (e) {
      print(
        'Firebase Auth Exception during registration: ${e.code} - ${e.message}',
      );
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'Please provide a valid email address.';
          break;
        default:
          message = 'An error occurred during registration: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Unexpected error during registration: $e');
      print('Error type: ${e.runtimeType}');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Login existing user with Firebase Auth
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      print('Login attempt for: $email');

      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('Firebase Auth returned null user');
        return {'success': false, 'message': 'Login failed. Please try again.'};
      }

      print('Firebase Auth successful, fetching user data from Firestore...');

      // Fetch user data from Firestore
      try {
        await _fetchUserFromFirestore(firebaseUser.uid);
      } catch (e) {
        print('Error fetching user from Firestore: $e');
        // If user doesn't exist in Firestore, sign them out
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User data not found. Please register again.',
        };
      }

      if (_currentUser == null) {
        print('User data not found in Firestore for UID: ${firebaseUser.uid}');
        // Sign out the user since they don't have complete data
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User data not found. Please register again.',
        };
      }

      print('Login successful for user: ${_currentUser!.name}');
      return {
        'success': true,
        'message': 'Login successful!',
        'user': _currentUser,
      };
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for that email. Please register first.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Please provide a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = 'Authentication error: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Unexpected error during login: $e');
      print('Error type: ${e.runtimeType}');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Simple login method for backward compatibility
  static Future<Map<String, dynamic>> simpleLogin(
    String email,
    String password,
  ) async {
    return await login(email, password);
  }

  // Logout user
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      print('Logout successful');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Clear cached user data
  static void clearCachedUser() {
    _currentUser = null;
    print('Cached user data cleared');
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? barangay,
  }) async {
    try {
      if (_currentUser == null || _auth.currentUser == null) {
        return {'success': false, 'message': 'No user logged in.'};
      }

      // Update current user model using copyWith
      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        address: address,
        barangay: barangay,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(_currentUser!.toFirestore());

      return {
        'success': true,
        'message': 'Profile updated successfully!',
        'user': _currentUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile. Please try again.',
      };
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email address.';
          break;
        case 'invalid-email':
          message = 'Please provide a valid email address.';
          break;
        default:
          message = 'An error occurred while sending reset email.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Manually create user in Firestore for existing Auth user
  static Future<Map<String, dynamic>> createUserInFirestore({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? barangay = 'Valenzuela City',
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'No user logged in. Please login first.',
        };
      }

      print('Creating user in Firestore for UID: ${currentUser.uid}');

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'barangay': barangay ?? 'Valenzuela City',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('users').doc(currentUser.uid).set(userData);

      // Update current user
      _currentUser = UserModel(
        id: currentUser.uid,
        name: name,
        email: email,
        phone: phone,
        address: address,
        barangay: barangay ?? 'Valenzuela City',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('User created in Firestore successfully');
      return {
        'success': true,
        'message': 'User data created successfully!',
        'user': _currentUser,
      };
    } catch (e) {
      print('Error creating user in Firestore: $e');
      return {'success': false, 'message': 'Failed to create user data: $e'};
    }
  }

  // Manually create a test user in Firestore (for debugging)
  static Future<Map<String, dynamic>> createTestUserInFirestore() async {
    try {
      print('Creating test user in Firestore...');

      final testUserData = {
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'barangay': 'Valenzuela City',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore
          .collection('users')
          .doc('test_user_123')
          .set(testUserData);

      print('Test user created successfully in Firestore');
      return {'success': true, 'message': 'Test user created in Firestore'};
    } catch (e) {
      print('Error creating test user in Firestore: $e');
      return {'success': false, 'message': 'Failed to create test user: $e'};
    }
  }

  // Check if user exists in Firestore
  static Future<Map<String, dynamic>> checkUserExists(String email) async {
    try {
      print('Checking if user exists in Firestore: $email');

      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isNotEmpty) {
        final userData = query.docs.first.data();
        print('User found in Firestore: ${userData['name']}');
        return {'success': true, 'exists': true, 'userData': userData};
      } else {
        print('User not found in Firestore: $email');
        return {'success': true, 'exists': false};
      }
    } catch (e) {
      print('Error checking user existence: $e');
      return {'success': false, 'message': 'Error checking user: $e'};
    }
  }

  // Test Firebase connectivity
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      print('Testing Firebase connection...');

      // Test Firestore connection
      await _firestore.collection('test').doc('test').get();
      print('Firestore connection successful');

      // Test Auth connection
      final currentUser = _auth.currentUser;
      print(
        'Firebase Auth connection successful. Current user: ${currentUser?.email ?? 'none'}',
      );

      return {'success': true, 'message': 'Firebase connection successful'};
    } catch (e) {
      print('Firebase connection test failed: $e');
      return {'success': false, 'message': 'Firebase connection failed: $e'};
    }
  }

  // Get current Firebase user
  static User? get firebaseUser => _auth.currentUser;
}
