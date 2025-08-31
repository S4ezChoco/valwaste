import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_collection.dart';
import 'firebase_auth_service.dart';

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
        return [];
      }

      final querySnapshot = await _firestore
          .collection('collections')
          .where('user_id', isEqualTo: FirebaseAuthService.currentUser!.id)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WasteCollection.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching user collections: $e');
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
        await _createNotification(
          userId: collection.userId,
          title: 'Collection Status Updated',
          message:
              'Your ${collection.wasteTypeText} collection status has been updated to ${collection.statusText}.',
          type: 'collection',
        );
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
        return {
          'totalCollections': 0,
          'completedCollections': 0,
          'pendingCollections': 0,
          'totalWeight': 0.0,
        };
      }

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

      return {
        'totalCollections': totalCollections,
        'completedCollections': completedCollections,
        'pendingCollections': pendingCollections,
        'totalWeight': totalWeight,
      };
    } catch (e) {
      print('Error fetching collection stats: $e');
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
}
