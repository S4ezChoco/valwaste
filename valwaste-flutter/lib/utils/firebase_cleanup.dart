import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// List all users in Firestore
  static Future<void> listAllUsers() async {
    try {
      print('Listing all users in Firestore...');

      final usersSnapshot = await _firestore.collection('users').get();

      print('Found ${usersSnapshot.docs.length} users:');

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        print('User ID: ${doc.id}');
        print('  Name: ${userData['name'] ?? 'N/A'}');
        print('  Email: ${userData['email'] ?? 'N/A'}');
        print('  Role: ${userData['role'] ?? 'N/A'}');
        print('  Created: ${userData['createdAt'] ?? 'N/A'}');
        print('---');
      }
    } catch (e) {
      print('Error listing users: $e');
      rethrow;
    }
  }

  /// Clean up corrupted user data
  static Future<void> cleanupAllUserData() async {
    try {
      print('Starting cleanup of all user data...');

      final usersSnapshot = await _firestore.collection('users').get();

      print('Found ${usersSnapshot.docs.length} users to process');

      int cleanedCount = 0;

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();

        // Check if user data is corrupted (missing required fields)
        if (userData['name'] == null ||
            userData['email'] == null ||
            userData['role'] == null) {
          print('Found corrupted user data for ID: ${doc.id}');
          print('  Current data: $userData');

          // Delete the corrupted document
          await doc.reference.delete();
          cleanedCount++;

          print('  Deleted corrupted user data');
        }
      }

      print('Cleanup completed. Removed $cleanedCount corrupted user records.');
    } catch (e) {
      print('Error during cleanup: $e');
      rethrow;
    }
  }

  /// Clean up specific user by email
  static Future<void> cleanupUserByEmail(String email) async {
    try {
      print('Looking for user with email: $email');

      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No user found with email: $email');
        return;
      }

      for (final doc in userQuery.docs) {
        print('Found user: ${doc.id}');
        print('  Data: ${doc.data()}');

        // Delete the user document
        await doc.reference.delete();
        print('  Deleted user data');
      }
    } catch (e) {
      print('Error cleaning up user by email: $e');
      rethrow;
    }
  }

  /// Reset all user data (DANGEROUS - use with caution)
  static Future<void> resetAllUserData() async {
    try {
      print('WARNING: This will delete ALL user data!');

      final usersSnapshot = await _firestore.collection('users').get();

      print('Found ${usersSnapshot.docs.length} users to delete');

      for (final doc in usersSnapshot.docs) {
        await doc.reference.delete();
      }

      print('All user data has been reset.');
    } catch (e) {
      print('Error resetting user data: $e');
      rethrow;
    }
  }

  /// Check for orphaned Firebase Auth users
  static Future<void> checkOrphanedAuthUsers() async {
    try {
      print('Checking for orphaned Firebase Auth users...');

      // Get all Firestore users
      final firestoreUsers = await _firestore.collection('users').get();
      final firestoreUserIds = firestoreUsers.docs.map((doc) => doc.id).toSet();

      print('Found ${firestoreUserIds.length} users in Firestore');

      // Note: Firebase Admin SDK would be needed to list all Auth users
      // For now, we can only check the current user
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (!firestoreUserIds.contains(currentUser.uid)) {
          print('Current user (${currentUser.uid}) has no Firestore document');
        } else {
          print('Current user has valid Firestore document');
        }
      }

      print('Orphaned user check completed');
    } catch (e) {
      print('Error checking orphaned users: $e');
      rethrow;
    }
  }
}

