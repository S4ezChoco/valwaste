import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_collection.dart';
import '../models/user.dart';
import 'firebase_auth_service.dart';
import 'enhanced_notification_service.dart';

class CollectionApprovalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get pending collection requests for barangay officials
  static Future<List<WasteCollection>> getPendingRequests() async {
    try {
      print('Fetching pending collection requests...');

      // First, let's check all collections to see what statuses exist
      final allCollections = await _firestore.collection('collections').get();
      print('Total collections in database: ${allCollections.docs.length}');

      for (var doc in allCollections.docs) {
        final data = doc.data();
        print('Collection ${doc.id}: status = ${data['status']}');
      }

      final querySnapshot = await _firestore
          .collection('collections')
          .where('status', isEqualTo: 'pending')
          .get();

      print('Found ${querySnapshot.docs.length} pending requests in Firebase');

      // Debug: Print all pending documents
      for (var doc in querySnapshot.docs) {
        print('Pending Document ID: ${doc.id}');
        print('Pending Document Data: ${doc.data()}');
      }

      final results = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // Add document ID to the data
              print(
                'Processing pending request: ${doc.id}, status: ${data['status']}',
              );
              final wasteCollection = WasteCollection.fromJson(data);
              print(
                'Successfully created WasteCollection for pending ${doc.id}',
              );
              return wasteCollection;
            } catch (e) {
              print('Error creating WasteCollection for pending ${doc.id}: $e');
              print('Document data: ${doc.data()}');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<WasteCollection>()
          .toList();

      print('Successfully converted ${results.length} pending requests');
      return results;
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  /// Get approved collection requests waiting for admin scheduling
  static Future<List<WasteCollection>> getApprovedRequests() async {
    try {
      print('Fetching approved collection requests...');

      // First, let's check all collections to see what statuses exist
      final allCollections = await _firestore.collection('collections').get();
      print('Total collections in database: ${allCollections.docs.length}');

      for (var doc in allCollections.docs) {
        final data = doc.data();
        print('Collection ${doc.id}: status = ${data['status']}');
      }

      final querySnapshot = await _firestore
          .collection('collections')
          .where('status', isEqualTo: 'approved')
          .get();

      print('Found ${querySnapshot.docs.length} approved requests in Firebase');

      // Debug: Print all documents
      for (var doc in querySnapshot.docs) {
        print('Document ID: ${doc.id}');
        print('Document Data: ${doc.data()}');
      }

      final results = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // Add document ID to the data
              print(
                'Processing approved request: ${doc.id}, status: ${data['status']}',
              );
              final wasteCollection = WasteCollection.fromJson(data);
              print('Successfully created WasteCollection for ${doc.id}');
              return wasteCollection;
            } catch (e) {
              print('Error creating WasteCollection for ${doc.id}: $e');
              print('Document data: ${doc.data()}');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<WasteCollection>()
          .toList();

      print('Successfully converted ${results.length} approved requests');
      return results;
    } catch (e) {
      print('Error fetching approved requests: $e');
      return [];
    }
  }

  /// Approve a collection request (Barangay Official action)
  static Future<Map<String, dynamic>> approveRequest({
    required String collectionId,
    String? notes,
  }) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final currentUser = FirebaseAuthService.currentUser!;

      // Check if user is a barangay official
      if (currentUser.role != UserRole.barangayOfficial) {
        return {
          'success': false,
          'message': 'Only barangay officials can approve requests',
        };
      }

      // Update the collection request
      await _firestore.collection('collections').doc(collectionId).update({
        'status': 'approved',
        'approved_by': currentUser.id,
        'approved_at': DateTime.now().toIso8601String(),
        'notes': notes,
      });

      // Get the collection details for notification
      final collectionDoc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();
      final collectionData = collectionDoc.data();

      if (collectionData != null) {
        // Notify the resident
        await EnhancedNotificationService.sendNotificationToUser(
          userId: collectionData['user_id'],
          title: 'Collection Request Approved',
          message:
              'Your waste collection request has been approved by the barangay official.',
          type: 'collection_approved',
          data: {'collection_id': collectionId},
        );

        // Notify admins about new approved request
        await _notifyAdminsAboutApprovedRequest(collectionId, collectionData);
      }

      return {
        'success': true,
        'message': 'Collection request approved successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to approve request: $e'};
    }
  }

  /// Reject a collection request (Barangay Official action)
  static Future<Map<String, dynamic>> rejectRequest({
    required String collectionId,
    required String reason,
  }) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final currentUser = FirebaseAuthService.currentUser!;

      // Check if user is a barangay official
      if (currentUser.role != UserRole.barangayOfficial) {
        return {
          'success': false,
          'message': 'Only barangay officials can reject requests',
        };
      }

      // Update the collection request
      await _firestore.collection('collections').doc(collectionId).update({
        'status': 'rejected',
        'approved_by': currentUser.id,
        'approved_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      });

      // Get the collection details for notification
      final collectionDoc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();
      final collectionData = collectionDoc.data();

      if (collectionData != null) {
        // Notify the resident
        await EnhancedNotificationService.sendNotificationToUser(
          userId: collectionData['user_id'],
          title: 'Collection Request Rejected',
          message:
              'Your waste collection request has been rejected. Reason: $reason',
          type: 'collection_rejected',
          data: {'collection_id': collectionId, 'reason': reason},
        );
      }

      return {'success': true, 'message': 'Collection request rejected'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reject request: $e'};
    }
  }

  /// Get collection requests assigned to a driver
  static Future<List<WasteCollection>> getDriverAssignments() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        print('No current user found for driver assignments');
        return [];
      }

      final currentUser = FirebaseAuthService.currentUser!;
      print(
        'Current user for driver assignments: ${currentUser.id}, role: ${currentUser.role}',
      );

      // Check if user is a driver
      if (currentUser.role != UserRole.driver) {
        print('User is not a driver, returning empty list');
        return [];
      }

      print('Fetching driver assignments for driver: ${currentUser.id}');

      // First, let's check what collections exist in the database
      final allCollectionsSnapshot = await _firestore
          .collection('collections')
          .get();
      print(
        'Total collections in database: ${allCollectionsSnapshot.docs.length}',
      );

      for (var doc in allCollectionsSnapshot.docs) {
        final data = doc.data();
        print(
          'Collection ${doc.id}: status=${data['status']}, assigned_to=${data['assigned_to']}, user_id=${data['user_id']}',
        );
      }

      // Check for approved collections that might need scheduling
      final approvedCollectionsSnapshot = await _firestore
          .collection('collections')
          .where('status', isEqualTo: 'approved')
          .get();
      print(
        'Approved collections (need scheduling): ${approvedCollectionsSnapshot.docs.length}',
      );

      for (var doc in approvedCollectionsSnapshot.docs) {
        final data = doc.data();
        print(
          'Approved collection ${doc.id}: user_id=${data['user_id']}, address=${data['address']}',
        );
      }

      final querySnapshot = await _firestore
          .collection('collections')
          .where('assigned_to', isEqualTo: currentUser.id)
          .where('status', whereIn: ['scheduled', 'inProgress'])
          .get();

      print('Found ${querySnapshot.docs.length} driver assignments');

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        print(
          'Driver assignment: ${doc.id}, status: ${data['status']}, scheduled_date: ${data['scheduled_date']}',
        );
        return WasteCollection.fromJson(data);
      }).toList();

      print('Successfully converted ${results.length} driver assignments');
      return results;
    } catch (e) {
      print('Error fetching driver assignments: $e');
      return [];
    }
  }

  /// Mark collection as in progress (Driver action)
  static Future<Map<String, dynamic>> startCollection(
    String collectionId,
  ) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final currentUser = FirebaseAuthService.currentUser!;

      // Check if user is a driver
      if (currentUser.role != UserRole.driver) {
        return {
          'success': false,
          'message': 'Only drivers can start collections',
        };
      }

      // Update the collection status
      print('Starting collection $collectionId - setting status to inProgress');
      await _firestore.collection('collections').doc(collectionId).update({
        'status': 'inProgress',
        'assigned_at': DateTime.now().toIso8601String(),
      });
      print('Collection $collectionId status updated to inProgress');

      // Get the collection details for notification
      final collectionDoc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();
      final collectionData = collectionDoc.data();

      if (collectionData != null) {
        // Notify the resident
        await EnhancedNotificationService.sendNotificationToUser(
          userId: collectionData['user_id'],
          title: 'Collection Started',
          message:
              'Your waste collection has started. The driver is on the way.',
          type: 'collection_started',
          data: {'collection_id': collectionId},
        );
      }

      return {'success': true, 'message': 'Collection started successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to start collection: $e'};
    }
  }

  /// Mark collection as completed (Driver action)
  static Future<Map<String, dynamic>> completeCollection(
    String collectionId,
  ) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final currentUser = FirebaseAuthService.currentUser!;

      // Check if user is a driver
      if (currentUser.role != UserRole.driver) {
        return {
          'success': false,
          'message': 'Only drivers can complete collections',
        };
      }

      // Update the collection status
      await _firestore.collection('collections').doc(collectionId).update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Get the collection details for notification
      final collectionDoc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();
      final collectionData = collectionDoc.data();

      if (collectionData != null) {
        // Notify the resident
        await EnhancedNotificationService.sendNotificationToUser(
          userId: collectionData['user_id'],
          title: 'Collection Completed',
          message: 'Your waste collection has been completed successfully.',
          type: 'collection_completed',
          data: {'collection_id': collectionId},
        );
      }

      return {'success': true, 'message': 'Collection completed successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to complete collection: $e'};
    }
  }

  /// Notify admins about new approved request
  static Future<void> _notifyAdminsAboutApprovedRequest(
    String collectionId,
    Map<String, dynamic> collectionData,
  ) async {
    try {
      // Get all administrators
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Administrator')
          .get();

      for (final adminDoc in adminsSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: adminDoc.id,
          title: 'New Approved Collection Request',
          message:
              'A collection request has been approved and needs scheduling.',
          type: 'admin_approval_needed',
          data: {'collection_id': collectionId},
        );
      }
    } catch (e) {
      print('Error notifying admins: $e');
    }
  }
}
