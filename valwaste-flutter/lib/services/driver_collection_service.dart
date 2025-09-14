import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_collection.dart';
import '../models/user.dart';
import 'firebase_auth_service.dart';

class DriverCollectionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Assign a collection to a driver
  static Future<Map<String, dynamic>> assignCollectionToDriver({
    required String collectionId,
    required String driverId,
  }) async {
    try {
      await _firestore.collection('collections').doc(collectionId).update({
        'driver_id': driverId,
        'status': CollectionStatus.scheduled.toString().split('.').last,
        'assigned_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create notification for the driver
      await _createNotification(
        userId: driverId,
        title: 'New Collection Assignment',
        message: 'You have been assigned a new waste collection.',
        type: 'collection_assignment',
        data: {'collection_id': collectionId},
      );

      return {
        'success': true,
        'message': 'Collection assigned to driver successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to assign collection to driver: $e',
      };
    }
  }

  // Get collections assigned to a specific driver
  static Future<List<WasteCollection>> getDriverCollections({
    String? driverId,
    DateTime? startDate,
    DateTime? endDate,
    CollectionStatus? status,
  }) async {
    try {
      final currentDriverId = driverId ?? FirebaseAuthService.currentUser?.id;
      if (currentDriverId == null) return [];

      // Get all collections for the driver first (avoiding complex index requirements)
      Query query = _firestore
          .collection('collections')
          .where('assigned_to', isEqualTo: currentDriverId);

      final querySnapshot = await query.get();

      final allCollections = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return WasteCollection.fromJson(data);
      }).toList();

      // Apply filters in the app to avoid Firebase index requirements
      var filteredCollections = allCollections;

      if (status != null) {
        filteredCollections = filteredCollections.where((collection) {
          return collection.status == status;
        }).toList();
      }

      if (startDate != null) {
        filteredCollections = filteredCollections.where((collection) {
          return collection.scheduledDate.isAfter(startDate) ||
              collection.scheduledDate.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        filteredCollections = filteredCollections.where((collection) {
          return collection.scheduledDate.isBefore(endDate);
        }).toList();
      }

      // Sort by scheduled date
      filteredCollections.sort(
        (a, b) => a.scheduledDate.compareTo(b.scheduledDate),
      );

      return filteredCollections;
    } catch (e) {
      print('Error getting driver collections: $e');
      return [];
    }
  }

  // Get driver's today collections
  static Future<List<WasteCollection>> getDriverTodayCollections({
    String? driverId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await getDriverCollections(
        driverId: driverId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      print('Error getting driver today collections: $e');
      return [];
    }
  }

  // Get driver's weekly collections
  static Future<List<WasteCollection>> getDriverWeeklyCollections({
    String? driverId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return await getDriverCollections(
        driverId: driverId,
        startDate: startOfWeek,
        endDate: endOfWeek,
      );
    } catch (e) {
      print('Error getting driver weekly collections: $e');
      return [];
    }
  }

  // Update collection status (for drivers)
  static Future<Map<String, dynamic>> updateCollectionStatus({
    required String collectionId,
    required CollectionStatus status,
    String? notes,
    String? location,
    List<String>? images,
  }) async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      switch (status) {
        case CollectionStatus.inProgress:
          updates['started_at'] = DateTime.now().toIso8601String();
          break;
        case CollectionStatus.completed:
          updates['completed_at'] = DateTime.now().toIso8601String();
          updates['completed_by'] = currentUser.id;
          break;
        default:
          break;
      }

      if (notes != null) {
        updates['driver_notes'] = notes;
      }

      if (location != null) {
        updates['completion_location'] = location;
      }

      if (images != null) {
        updates['completion_images'] = images;
      }

      await _firestore
          .collection('collections')
          .doc(collectionId)
          .update(updates);

      // Create notification for the resident
      final collection = await _getCollectionById(collectionId);
      if (collection != null) {
        await _createNotification(
          userId: collection.userId,
          title: 'Collection Status Updated',
          message:
              'Your ${collection.wasteTypeText} collection status has been updated to ${_getStatusText(status)}.',
          type: 'collection_update',
          data: {'collection_id': collectionId, 'status': status.toString()},
        );
      }

      return {
        'success': true,
        'message': 'Collection status updated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update collection status: $e',
      };
    }
  }

  // Get driver collection statistics
  static Future<Map<String, dynamic>> getDriverCollectionStats({
    String? driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final collections = await getDriverCollections(
        driverId: driverId,
        startDate: startDate,
        endDate: endDate,
      );

      int totalCollections = collections.length;
      int completedCollections = collections
          .where((c) => c.status == CollectionStatus.completed)
          .length;
      int inProgressCollections = collections
          .where((c) => c.status == CollectionStatus.inProgress)
          .length;
      int pendingCollections = collections
          .where(
            (c) =>
                c.status == CollectionStatus.scheduled ||
                c.status == CollectionStatus.approved,
          )
          .length;

      double totalWeight = collections
          .where((c) => c.status == CollectionStatus.completed)
          .fold(0.0, (sum, c) => sum + c.quantity);

      // Calculate completion rate
      double completionRate = totalCollections > 0
          ? (completedCollections / totalCollections) * 100
          : 0.0;

      // Get waste type breakdown
      Map<String, int> wasteTypeBreakdown = {};
      for (final collection in collections) {
        final wasteType = collection.wasteTypeText;
        wasteTypeBreakdown[wasteType] =
            (wasteTypeBreakdown[wasteType] ?? 0) + 1;
      }

      return {
        'total_collections': totalCollections,
        'completed_collections': completedCollections,
        'in_progress_collections': inProgressCollections,
        'pending_collections': pendingCollections,
        'total_weight': totalWeight,
        'completion_rate': completionRate,
        'waste_type_breakdown': wasteTypeBreakdown,
      };
    } catch (e) {
      print('Error getting driver collection stats: $e');
      return {
        'total_collections': 0,
        'completed_collections': 0,
        'in_progress_collections': 0,
        'pending_collections': 0,
        'total_weight': 0.0,
        'completion_rate': 0.0,
        'waste_type_breakdown': {},
      };
    }
  }

  // Get available drivers for assignment
  static Future<List<UserModel>> getAvailableDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting available drivers: $e');
      return [];
    }
  }

  // Auto-assign collections to drivers based on location and availability
  static Future<Map<String, dynamic>> autoAssignCollections({
    required DateTime date,
    String? barangay,
  }) async {
    try {
      // Get unassigned collections for the date
      Query query = _firestore
          .collection('collections')
          .where(
            'status',
            isEqualTo: CollectionStatus.approved.toString().split('.').last,
          )
          .where('scheduled_date', isGreaterThanOrEqualTo: date)
          .where(
            'scheduled_date',
            isLessThan: date.add(const Duration(days: 1)),
          );

      if (barangay != null) {
        query = query.where('barangay', isEqualTo: barangay);
      }

      final collectionsSnapshot = await query.get();
      final collections = collectionsSnapshot.docs
          .map(
            (doc) =>
                WasteCollection.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      if (collections.isEmpty) {
        return {
          'success': true,
          'message': 'No collections to assign',
          'assigned_count': 0,
        };
      }

      // Get available drivers
      final drivers = await getAvailableDrivers();
      if (drivers.isEmpty) {
        return {
          'success': false,
          'message': 'No available drivers found',
          'assigned_count': 0,
        };
      }

      int assignedCount = 0;
      int driverIndex = 0;

      // Assign collections to drivers in round-robin fashion
      for (final collection in collections) {
        if (driverIndex >= drivers.length) {
          driverIndex = 0;
        }

        final driver = drivers[driverIndex];
        final result = await assignCollectionToDriver(
          collectionId: collection.id,
          driverId: driver.id,
        );

        if (result['success']) {
          assignedCount++;
        }

        driverIndex++;
      }

      return {
        'success': true,
        'message': 'Auto-assignment completed',
        'assigned_count': assignedCount,
        'total_collections': collections.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to auto-assign collections: $e',
        'assigned_count': 0,
      };
    }
  }

  // Helper method to get collection by ID
  static Future<WasteCollection?> _getCollectionById(
    String collectionId,
  ) async {
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
      print('Error getting collection by ID: $e');
      return null;
    }
  }

  // Helper method to create notifications
  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Helper method to get status text
  static String _getStatusText(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return 'Pending';
      case CollectionStatus.approved:
        return 'Approved';
      case CollectionStatus.scheduled:
        return 'Scheduled';
      case CollectionStatus.inProgress:
        return 'In Progress';
      case CollectionStatus.completed:
        return 'Completed';
      case CollectionStatus.cancelled:
        return 'Cancelled';
      case CollectionStatus.rejected:
        return 'Rejected';
    }
  }
}
