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
  static void initialize() {
    print('Firebase Auth Service initialized');
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null && _currentUser == null) {
        // Only fetch if we don't already have user data (avoids registration interference)
        try {
          await _fetchUserFromFirestore(firebaseUser.uid);
        } catch (e) {
          print('Auth state listener - error fetching user data: $e');
          // Don't set _currentUser to null here, keep any existing user data
        }
      } else if (firebaseUser == null) {
        // User is signed out
        _currentUser = null;
        print('User signed out, cleared current user data');
      }
    });
  }

  // Fetch user data from Firestore
  static Future<void> _fetchUserFromFirestore(String uid) async {
    try {
      print('Fetching user data from Firestore for UID: $uid');

      // Get current Firebase user to get email
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current Firebase user found');
        _currentUser = null;
        return;
      }

      final email = currentUser.email;
      if (email == null) {
        print('No email found for current user');
        _currentUser = null;
        return;
      }

      print('Searching for user with email: $email');

      // Search by email instead of UID with error handling
      late QuerySnapshot userQuery;
      try {
        userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
      } catch (queryError) {
        print('Error during Firestore query: $queryError');
        print('Query error type: ${queryError.runtimeType}');
        
        // Handle PigeonUserDetails error in query
        if (queryError.toString().contains('PigeonUserDetails') || 
            queryError.toString().contains('pigeonUser') ||
            queryError.toString().contains('List<Object?>')) {
          print('PigeonUserDetails error in query - attempting fallback');
          
          // Try alternative query approach
          try {
            userQuery = await _firestore
                .collection('users')
                .get();
            
            // Filter manually by email
            final matchingDocs = userQuery.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null && data['email'] == email;
            }).toList();
            
            // Create a mock QuerySnapshot with filtered results
            if (matchingDocs.isNotEmpty) {
              print('Found user via fallback method');
              final doc = matchingDocs.first;
              final data = doc.data() as Map<String, dynamic>;
              
              if (data.containsKey('email')) {
                try {
                  _currentUser = UserModel.fromFirestore(doc);
                  print('User data fetched via fallback: ${_currentUser!.name}');
                  return;
                } catch (parseError) {
                  print('Error parsing user data in fallback: $parseError');
                }
              }
            }
          } catch (fallbackError) {
            print('Fallback query also failed: $fallbackError');
          }
          
          _currentUser = null;
          return;
        }
        
        // Re-throw non-PigeonUserDetails errors
        rethrow;
      }

      print('Query result: ${userQuery.docs.length} documents found');

      if (userQuery.docs.isEmpty) {
        print('No user document found for email: $email');
        _currentUser = null;
        return;
      }

      final doc = userQuery.docs.first;
      final data = doc.data() as Map<String, dynamic>?;
      print('Raw Firestore data: $data');
      print('Document ID: ${doc.id}');

      // Handle different data structures
      if (data != null) {
        // Check if this is a valid user document (has email)
        final hasEmail = data.containsKey('email');
        final hasName = data.containsKey('name');
        final hasFirstName = data.containsKey('firstName');
        final hasLastName = data.containsKey('lastName');

        print(
          'Field check - Email: $hasEmail, Name: $hasName, FirstName: $hasFirstName, LastName: $hasLastName',
        );

        // Accept any document with email
        if (hasEmail) {
          try {
            _currentUser = UserModel.fromFirestore(doc);
            print(
              'User data fetched successfully: ${_currentUser!.name} (${_currentUser!.roleString})',
            );
          } catch (parseError) {
            print('Error parsing user data: $parseError');
            print('Raw data that failed to parse: $data');
            _currentUser = null;
          }
        } else {
          print('Invalid user document structure: missing email field');
          _currentUser = null;
        }
      } else {
        print('User document exists but has no data');
        _currentUser = null;
      }
    } catch (e) {
      print('Error fetching user from Firestore: $e');
      print('Error type: ${e.runtimeType}');
      
      // Handle PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('pigeonUser') ||
          e.toString().contains('List<Object?>')) {
        print('Detected PigeonUserDetails casting error - continuing without re-throwing');
        _currentUser = null;
        return; // Don't re-throw this specific error
      }
      
      _currentUser = null;
      rethrow; // Re-throw other errors to be caught by the calling method
    }
  }

  // Register new user with Firebase Auth and Firestore (with role support)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    String? barangay = 'Valenzuela City',
    UserRole role = UserRole.resident, // Default to resident
  }) async {
    try {
      print('Starting registration for: $email with role: ${role.name}');

      // Skip existing user check to avoid PigeonUserDetails error
      // Create user with Firebase Auth directly
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
        'role': role.name,
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
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set current user directly - avoid any Firestore queries during registration
      _currentUser = userModel;
      print('Registration completed with local user model');

      return {
        'success': true,
        'message': 'Account created successfully! Welcome to ValWaste!',
        'user': _currentUser,
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

  // Login existing user with Firebase Auth (with role validation)
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      print('Login attempt for: $email');

      // First, try to find user in Firestore by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No account found for that email. Please register first.',
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      // Check if user has authUserId (Firebase Auth account exists)
      final authUserId = userData['authUserId'];

      if (authUserId == null) {
        // User exists in Firestore but no Firebase Auth account
        print(
          'User found in Firestore but no Firebase Auth account. Attempting to link or create...',
        );

        try {
          // First, try to sign in with the password to see if Auth account exists
          try {
            final UserCredential signInCredential = await _auth
                .signInWithEmailAndPassword(email: email, password: password);

            final User? firebaseUser = signInCredential.user;
            if (firebaseUser != null) {
              // Auth account exists and password matches! Link it
              await userDoc.reference.update({
                'authUserId': firebaseUser.uid,
                'updatedAt': Timestamp.fromDate(DateTime.now()),
              });

              print('Linked existing Firebase Auth account for: $email');

              // Now fetch the updated user data
              await _fetchUserFromFirestore(firebaseUser.uid);
            }
          } catch (signInError) {
            // Auth account doesn't exist or password doesn't match
            if (signInError is FirebaseAuthException) {
              if (signInError.code == 'user-not-found' ||
                  signInError.code == 'wrong-password') {
                // Try to create new Firebase Auth account
                try {
                  final UserCredential userCredential = await _auth
                      .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                  final User? firebaseUser = userCredential.user;
                  if (firebaseUser == null) {
                    return {
                      'success': false,
                      'message': 'Failed to create authentication account.',
                    };
                  }

                  // Update Firestore document with authUserId
                  await userDoc.reference.update({
                    'authUserId': firebaseUser.uid,
                    'updatedAt': Timestamp.fromDate(DateTime.now()),
                  });

                  print('Created new Firebase Auth account for: $email');

                  // Now fetch the updated user data
                  await _fetchUserFromFirestore(firebaseUser.uid);
                } catch (createError) {
                  print('Failed to create Firebase Auth account: $createError');
                  if (createError is FirebaseAuthException) {
                    switch (createError.code) {
                      case 'email-already-in-use':
                        return {
                          'success': false,
                          'message':
                              'An authentication account already exists for this email. Please use the correct password.',
                        };
                      case 'weak-password':
                        return {
                          'success': false,
                          'message':
                              'Password is too weak. Please contact admin for assistance.',
                        };
                      default:
                        return {
                          'success': false,
                          'message':
                              'Failed to create authentication account: ${createError.message}',
                        };
                    }
                  }
                  return {
                    'success': false,
                    'message':
                        'Failed to create authentication account. Please contact admin.',
                  };
                }
              } else {
                // Other sign-in errors
                return {
                  'success': false,
                  'message': 'Authentication error: ${signInError.message}',
                };
              }
            } else {
              return {
                'success': false,
                'message': 'Authentication error: $signInError',
              };
            }
          }
        } catch (e) {
          print('Unexpected error during Auth linking: $e');
          return {
            'success': false,
            'message': 'Unexpected error during authentication: $e',
          };
        }
      } else {
        // User has Firebase Auth account, try normal login
        try {
          final UserCredential userCredential = await _auth
              .signInWithEmailAndPassword(email: email, password: password);

          final User? firebaseUser = userCredential.user;
          if (firebaseUser == null) {
            print('Firebase Auth returned null user');
            return {
              'success': false,
              'message': 'Login failed. Please try again.',
            };
          }

          print(
            'Firebase Auth successful, fetching user data from Firestore...',
          );

          // Fetch user data from Firestore
          await _fetchUserFromFirestore(firebaseUser.uid);
        } catch (authError) {
          print('Firebase Auth login failed: $authError');
          print('Error type: ${authError.runtimeType}');

          // Handle the specific error we're seeing
          if (authError.toString().contains('PigeonUserDetails') || 
              authError.toString().contains('pigeonUser')) {
            print(
              'Detected PigeonUserDetails error, attempting to continue...',
            );
            // Wait a moment for auth state to settle
            await Future.delayed(const Duration(milliseconds: 1000));
            
            // Try to continue with login despite this error
            try {
              // Get current Firebase user
              final currentUser = _auth.currentUser;
              if (currentUser != null && currentUser.email != null) {
                print('Firebase user found after PigeonUser error: ${currentUser.email}');
                // Force fetch user data after successful auth
                await _fetchUserFromFirestore(currentUser.uid);
                
                if (_currentUser != null) {
                  return {
                    'success': true,
                    'message': 'Login successful! Welcome back, ${_currentUser!.name}!',
                    'user': _currentUser,
                  };
                } else {
                  return {
                    'success': false,
                    'message': 'Authentication successful but user data not found. Please contact admin.',
                  };
                }
              } else {
                return {
                  'success': false,
                  'message': 'Authentication failed. Please try again.',
                };
              }
            } catch (fetchError) {
              print('Error fetching user data after PigeonUser error: $fetchError');
              return {
                'success': false,
                'message': 'Authentication successful but unable to load user data. Please restart the app.',
              };
            }
          }

          if (authError is FirebaseAuthException) {
            switch (authError.code) {
              case 'user-not-found':
                return {
                  'success': false,
                  'message':
                      'No authentication account found. Please contact admin.',
                };
              case 'wrong-password':
                return {
                  'success': false,
                  'message': 'Wrong password provided.',
                };
              case 'invalid-email':
                return {
                  'success': false,
                  'message': 'Please provide a valid email address.',
                };
              case 'user-disabled':
                return {
                  'success': false,
                  'message': 'This account has been disabled.',
                };
              case 'too-many-requests':
                return {
                  'success': false,
                  'message':
                      'Too many failed attempts. Please try again later.',
                };
              case 'network-request-failed':
                return {
                  'success': false,
                  'message':
                      'Network error. Please check your internet connection.',
                };
              case 'invalid-credential':
                return {
                  'success': false,
                  'message':
                      'Invalid email or password. Please check your credentials.',
                };
              default:
                return {
                  'success': false,
                  'message': 'Authentication error: ${authError.message}',
                };
            }
          }
          return {
            'success': false,
            'message': 'Login failed. Please try again.',
          };
        }
      }

      if (_currentUser == null) {
        print('User data not found in Firestore');
        // Sign out the user since they don't have complete data
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User data not found. Please contact admin.',
        };
      }

      print(
        'Login successful for user: ${_currentUser!.name} (${_currentUser!.roleString})',
      );
      return {
        'success': true,
        'message': 'Login successful! Welcome back, ${_currentUser!.name}!',
        'user': _currentUser,
      };
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

  // Force refresh current user data
  static Future<void> refreshCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('Force refreshing user data for: ${currentUser.email}');
        await _fetchUserFromFirestore(currentUser.uid);
        print(
          'User data refreshed: ${_currentUser?.name} (${_currentUser?.roleString})',
        );
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  // Force refresh current user data from Firestore
  static Future<void> forceRefreshUserData() async {
    try {
      print('Force refreshing user data...');
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Clear current user data
        _currentUser = null;
        print('Cleared cached user data');

        // Fetch fresh data
        await _fetchUserFromFirestore(currentUser.uid);
        print('Fresh user data fetched: ${_currentUser?.name ?? 'null'}');
      } else {
        print('No current Firebase user to refresh');
      }
    } catch (e) {
      print('Error force refreshing user data: $e');
    }
  }

  // Get current user with refresh
  static Future<UserModel?> getCurrentUserWithRefresh() async {
    if (_currentUser == null) {
      await refreshCurrentUser();
    }
    return _currentUser;
  }

  // Get current user with force refresh
  static Future<UserModel?> getCurrentUserWithForceRefresh() async {
    await forceRefreshUserData();
    return _currentUser;
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? barangay,
    UserRole? role,
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
        role: role,
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

  // Create Firebase Auth account for existing Firestore user
  static Future<Map<String, dynamic>> createAuthForExistingUser({
    required String email,
    required String password,
  }) async {
    try {
      print('Creating Firebase Auth account for existing user: $email');

      // Check if user exists in Firestore first
      final userCheck = await checkUserExists(email);
      if (!userCheck['exists']) {
        return {
          'success': false,
          'message': 'User not found in Firestore. Please register first.',
        };
      }

      // Create Firebase Auth account
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'message': 'Failed to create auth account.'};
      }

      // Get the existing user data from Firestore
      final existingUserData = userCheck['userData'];

      // Update Firestore document with authUserId and move to correct UID
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        ...existingUserData,
        'authUserId': firebaseUser.uid,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Firebase Auth account created successfully for: $email');
      return {
        'success': true,
        'message':
            'Auth account created! You can now login with $email / $password',
      };
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Auth account already exists for this email.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Auth creation failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Error creating auth account: $e');
      return {'success': false, 'message': 'Failed to create auth account: $e'};
    }
  }

  // Create Auth accounts for ALL existing users from PHP admin
  static Future<Map<String, dynamic>> createAuthForAllExistingUsers() async {
    try {
      print('Creating Firebase Auth accounts for all existing users...');

      // Get all users from Firestore
      final querySnapshot = await _firestore.collection('users').get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'No users found in Firestore.'};
      }

      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        final email = userData['email'];

        if (email == null) continue;

        try {
          // Create auth account for each user
          final result = await createAuthForExistingUser(
            email: email,
            password: '123456', // Default password for all users
          );

          if (result['success']) {
            successCount++;
            print('Created auth for: $email');
          } else {
            errorCount++;
            errors.add('$email: ${result['message']}');
          }
        } catch (e) {
          errorCount++;
          errors.add('$email: $e');
        }
      }

      final message =
          'Created auth for $successCount users. Errors: $errorCount';
      print(message);

      return {
        'success': successCount > 0,
        'message': message,
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
      };
    } catch (e) {
      print('Error creating auth for all users: $e');
      return {
        'success': false,
        'message': 'Failed to create auth accounts: $e',
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
    UserRole role = UserRole.resident,
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
        'role': role.name,
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
        role: role,
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
        'role': 'Resident',
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

  // Debug function to create a test user with proper structure
  static Future<void> createTestUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('Creating test user data for: ${currentUser.email}');

        final testUserData = {
          'name': 'Test Resident User',
          'email': currentUser.email,
          'phone': '+639123456789',
          'address': '123 Test Street',
          'barangay': 'Valenzuela City',
          'role': 'Resident', // Make sure this matches the expected role
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(testUserData);
        print(
          'Test user data created successfully with role: ${testUserData['role']}',
        );

        // Refresh current user
        await _fetchUserFromFirestore(currentUser.uid);
      }
    } catch (e) {
      print('Error creating test user: $e');
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
        print(
          'User found in Firestore: ${userData['name']} (${userData['role']})',
        );
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
