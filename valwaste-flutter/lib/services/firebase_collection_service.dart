import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_collection.dart';
import '../models/user.dart';
import 'firebase_auth_service.dart';
import 'enhanced_notification_service.dart';
import 'route_optimization_service.dart';

class FirebaseCollectionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new collection request
  static Future<Map<String, dynamic>> createCollectionRequest({
    required WasteType wasteType,
    required double quantity,
    required String unit,
    required String description,
    required DateTime scheduledDate,
    required String address,
    String? notes,
  }) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please login first.',
        };
      }

      final collection = WasteCollection(
        id: 'collection_${DateTime.now().millisecondsSinceEpoch}',
        userId: FirebaseAuthService.currentUser!.id,
        wasteType: wasteType,
        quantity: quantity,
        unit: unit,
        description: description,
        scheduledDate: scheduledDate,
        address: address,
        status: CollectionStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
        barangay: FirebaseAuthService.currentUser!.barangay,
      );

      await _firestore
          .collection('collections')
          .doc(collection.id)
          .set(collection.toJson());

      // Create notification for the user
      await _createNotification(
        userId: FirebaseAuthService.currentUser!.id,
        title: 'Collection Request Submitted',
        message:
            'Your ${collection.wasteTypeText} collection request has been submitted successfully.',
        type: 'collection',
      );

      // Notify drivers and barangay officials about the new request
      await _notifyRelevantUsers(collection);

      // Auto-assign collections to drivers if they are scheduled for today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      if (collection.scheduledDate.isAfter(startOfDay) &&
          collection.scheduledDate.isBefore(endOfDay)) {
        // Import and call auto-assignment
        try {
          // This will be called asynchronously to avoid blocking the main flow
          Future.delayed(const Duration(seconds: 2), () async {
            await RouteOptimizationService.autoAssignCollectionsToDrivers();
          });
        } catch (e) {
          print('Error in auto-assignment: $e');
        }
      }

      return {
        'success': true,
        'message': 'Collection request submitted successfully!',
        'collection': collection,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit collection request. Please try again.',
      };
    }
  }

  // Get user's collection history
  static Future<List<WasteCollection>> getUserCollections() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        print('❌ No current user for getUserCollections');
        return [];
      }

      final userId = FirebaseAuthService.currentUser!.id;
      print('🔍 Fetching collections for user: $userId');
      print('🔍 User ID type: ${userId.runtimeType}');
      print('🔍 User ID length: ${userId.length}');

      // First, let's check all collections to see what's in the database
      final allCollectionsSnapshot = await _firestore
          .collection('collections')
          .get();

      print(
        '📄 Total collections in database: ${allCollectionsSnapshot.docs.length}',
      );

      for (var doc in allCollectionsSnapshot.docs) {
        final data = doc.data();
        print(
          '📋 Collection ${doc.id}: user_id = "${data['user_id']}" (type: ${data['user_id'].runtimeType})',
        );
      }

      final querySnapshot = await _firestore
          .collection('collections')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      print(
        '📄 Found ${querySnapshot.docs.length} collection documents for this user',
      );

      final collections = querySnapshot.docs.map((doc) {
        print('📋 Collection: ${doc.id} - ${doc.data()}');
        return WasteCollection.fromJson(doc.data());
      }).toList();

      print('✅ Successfully loaded ${collections.length} collections');
      return collections;
    } catch (e) {
      print('❌ Error fetching user collections: $e');
      return [];
    }
  }

  // Get all collection requests (for drivers and administrators)
  static Future<List<WasteCollection>> getAllCollectionRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection('collections')
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WasteCollection.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching all collection requests: $e');
      return [];
    }
  }

  // Get collection by ID
  static Future<WasteCollection?> getCollectionById(String collectionId) async {
    try {
      final doc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();

      if (doc.exists) {
        return WasteCollection.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching collection: $e');
      return null;
    }
  }

  // Update collection status
  static Future<Map<String, dynamic>> updateCollectionStatus({
    required String collectionId,
    required CollectionStatus status,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == CollectionStatus.completed) {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _firestore
          .collection('collections')
          .doc(collectionId)
          .update(updates);

      // Get the collection to create notification
      final collection = await getCollectionById(collectionId);
      if (collection != null) {
        // Notify the resident about status change
        await _createNotification(
          userId: collection.userId,
          title: 'Collection Status Updated',
          message:
              'Your ${collection.wasteTypeText} collection status has been updated to ${collection.statusText}.',
          type: 'collection',
        );

        // Notify relevant users about status change
        await _notifyStatusChange(collection, status);
      }

      return {
        'success': true,
        'message': 'Collection status updated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update collection status. Please try again.',
      };
    }
  }

  // Cancel collection request
  static Future<Map<String, dynamic>> cancelCollection(
    String collectionId,
  ) async {
    try {
      final collection = await getCollectionById(collectionId);
      if (collection == null) {
        return {'success': false, 'message': 'Collection not found.'};
      }

      if (collection.userId != FirebaseAuthService.currentUser!.id) {
        return {
          'success': false,
          'message': 'You can only cancel your own collection requests.',
        };
      }

      await _firestore.collection('collections').doc(collectionId).update({
        'status': CollectionStatus.cancelled.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Collection request cancelled successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel collection request. Please try again.',
      };
    }
  }

  // Get collection statistics for user
  static Future<Map<String, dynamic>> getUserCollectionStats() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        print('❌ No current user for getUserCollectionStats');
        return {
          'totalCollections': 0,
          'completedCollections': 0,
          'pendingCollections': 0,
          'totalWeight': 0.0,
        };
      }

      print(
        '📊 Calculating stats for user: ${FirebaseAuthService.currentUser!.id}',
      );
      final collections = await getUserCollections();

      int totalCollections = collections.length;
      int completedCollections = collections
          .where((c) => c.status == CollectionStatus.completed)
          .length;
      int pendingCollections = collections
          .where(
            (c) =>
                c.status == CollectionStatus.pending ||
                c.status == CollectionStatus.scheduled,
          )
          .length;
      double totalWeight = collections
          .where((c) => c.status == CollectionStatus.completed)
          .fold(0.0, (sum, c) => sum + c.quantity);

      final stats = {
        'totalCollections': totalCollections,
        'completedCollections': completedCollections,
        'pendingCollections': pendingCollections,
        'totalWeight': totalWeight,
      };

      print('📈 Calculated stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Error fetching collection stats: $e');
      return {
        'totalCollections': 0,
        'completedCollections': 0,
        'pendingCollections': 0,
        'totalWeight': 0.0,
      };
    }
  }

  // Helper method to create notifications
  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Notify relevant users (drivers and barangay officials) about new collection requests
  static Future<void> _notifyRelevantUsers(WasteCollection collection) async {
    try {
      // Get all drivers
      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .get();

      // Get all barangay officials
      final barangayOfficialsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.barangayOfficial.toString())
          .get();

      // Notify drivers
      for (final doc in driversSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Collection Request',
          message:
              'New ${collection.wasteTypeText} collection request from ${collection.address}',
          type: 'new_request',
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'scheduled_date': collection.scheduledDate.toIso8601String(),
            'quantity': collection.quantity,
            'unit': collection.unit,
          },
        );
      }

      // Notify barangay officials
      for (final doc in barangayOfficialsSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Collection Request',
          message:
              'New ${collection.wasteTypeText} collection request from ${collection.address}',
          type: 'new_request',
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'scheduled_date': collection.scheduledDate.toIso8601String(),
            'quantity': collection.quantity,
            'unit': collection.unit,
          },
        );
      }

      print(
        'Notified ${driversSnapshot.docs.length} drivers and ${barangayOfficialsSnapshot.docs.length} barangay officials about new collection request',
      );
    } catch (e) {
      print('Error notifying relevant users: $e');
    }
  }

  // Notify relevant users about collection status changes
  static Future<void> _notifyStatusChange(
    WasteCollection collection,
    CollectionStatus newStatus,
  ) async {
    try {
      // Get all drivers
      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .get();

      // Get all barangay officials
      final barangayOfficialsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.barangayOfficial.toString())
          .get();

      String statusMessage = '';
      String notificationType = '';

      switch (newStatus) {
        case CollectionStatus.approved:
          statusMessage = 'Collection request approved';
          notificationType = 'collection_approved';
          break;
        case CollectionStatus.inProgress:
          statusMessage = 'Collection in progress';
          notificationType = 'collection_started';
          break;
        case CollectionStatus.completed:
          statusMessage = 'Collection completed';
          notificationType = 'collection_completed';
          break;
        case CollectionStatus.cancelled:
          statusMessage = 'Collection cancelled';
          notificationType = 'collection_cancelled';
          break;
        default:
          statusMessage = 'Collection status updated';
          notificationType = 'status_update';
      }

      // Notify drivers
      for (final doc in driversSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: statusMessage,
          message:
              '${collection.wasteTypeText} collection at ${collection.address} - ${statusMessage.toLowerCase()}',
          type: notificationType,
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'status': newStatus.toString(),
            'scheduled_date': collection.scheduledDate.toIso8601String(),
          },
        );
      }

      // Notify barangay officials
      for (final doc in barangayOfficialsSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: statusMessage,
          message:
              '${collection.wasteTypeText} collection at ${collection.address} - ${statusMessage.toLowerCase()}',
          type: notificationType,
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'status': newStatus.toString(),
            'scheduled_date': collection.scheduledDate.toIso8601String(),
          },
        );
      }

      print(
        'Notified ${driversSnapshot.docs.length} drivers and ${barangayOfficialsSnapshot.docs.length} barangay officials about status change',
      );
    } catch (e) {
      print('Error notifying about status change: $e');
    }
  }

  // Get real-time stream of collection requests for map display
  static Stream<List<WasteCollection>> getCollectionRequestsStream() {
    return _firestore
        .collection('collections')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WasteCollection.fromJson(doc.data()))
              .toList();
        });
  }

  // Get approved collection requests for driver dashboard
  static Future<List<WasteCollection>> getApprovedCollectionRequests() async {
    try {
      final snapshot = await _firestore
          .collection('collections')
          .where('status', isEqualTo: 'approved')
          .get();

      final requests = snapshot.docs
          .map((doc) => WasteCollection.fromJson(doc.data()))
          .toList();

      // Sort by created_at in descending order (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return requests;
    } catch (e) {
      throw Exception('Failed to fetch approved collection requests: $e');
    }
  }
}
