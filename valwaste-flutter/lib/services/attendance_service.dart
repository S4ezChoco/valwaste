import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firebase Firestore collection (creates collection if it doesn't exist)
  static Future<void> initializeAttendanceCollection() async {
    try {
      print('🔧 Initializing attendance collection in Firebase Firestore...');

      // Test if collection exists by trying to read from it
      await _firestore.collection('attendance').limit(1).get();

      print('✅ Attendance collection is ready in Firebase Firestore');
    } catch (e) {
      print('⚠️ Attendance collection initialization: $e');
      // Collection will be created automatically when first document is added
    }
  }

  /// Upload attendance record when driver checks in
  static Future<Map<String, dynamic>> recordCheckIn({
    required String driverId,
    required String driverName,
    required String truckInfo,
    required String plateNumber,
    File? checkInSelfie,
  }) async {
    try {
      // Skip Firebase Storage completely - just use placeholder
      print('🔄 Skipping Firebase Storage upload, using placeholder');
      final selfieUrl = 'no_selfie_provided';

      // Create attendance record
      final attendanceData = {
        'driverId': driverId,
        'driverName': driverName,
        'truckInfo': truckInfo,
        'plateNumber': plateNumber,
        'checkInTime': DateTime.now().toIso8601String(),
        'checkOutTime': null,
        'checkInSelfieUrl': selfieUrl,
        'checkOutSelfieUrl': null,
        'status': 'active', // active, completed, abandoned
        'collectionsCompleted': 0,
        'totalHours': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore - This will automatically create the collection if it doesn't exist
      print('Creating attendance record in Firebase Firestore...');
      final docRef = await _firestore
          .collection('attendance')
          .add(attendanceData);

      print(
        '✅ Attendance record created successfully in Firebase: ${docRef.id}',
      );
      print('📊 Attendance data saved: ${attendanceData.toString()}');

      return {
        'success': true,
        'message': 'Check-in recorded successfully',
        'attendanceId': docRef.id,
      };
    } catch (e) {
      print('Error recording check-in: $e');
      return {'success': false, 'message': 'Failed to record check-in: $e'};
    }
  }

  /// Update attendance record when driver checks out
  static Future<Map<String, dynamic>> recordCheckOut({
    required String attendanceId,
    File? checkOutSelfie,
    required int collectionsCompleted,
  }) async {
    try {
      // Skip Firebase Storage completely - just use placeholder
      print(
        '🔄 Skipping Firebase Storage upload for check-out, using placeholder',
      );
      final checkOutSelfieUrl = 'no_selfie_provided';

      // Get the attendance record to calculate total hours
      final attendanceDoc = await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .get();
      if (!attendanceDoc.exists) {
        return {'success': false, 'message': 'Attendance record not found'};
      }

      final attendanceData = attendanceDoc.data()!;
      final checkInTime = DateTime.parse(attendanceData['checkInTime']);
      final checkOutTime = DateTime.now();
      final totalHours =
          checkOutTime.difference(checkInTime).inHours +
          (checkOutTime.difference(checkInTime).inMinutes % 60) / 60.0;

      // Update attendance record in Firebase
      print('Updating attendance record in Firebase Firestore...');
      await _firestore.collection('attendance').doc(attendanceId).update({
        'checkOutTime': checkOutTime.toIso8601String(),
        'checkOutSelfieUrl': checkOutSelfieUrl,
        'status': 'completed',
        'collectionsCompleted': collectionsCompleted,
        'totalHours': totalHours,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print(
        '✅ Attendance record updated successfully in Firebase: $attendanceId',
      );
      print(
        '📊 Check-out data: Collections completed: $collectionsCompleted, Total hours: $totalHours',
      );

      return {'success': true, 'message': 'Check-out recorded successfully'};
    } catch (e) {
      print('Error recording check-out: $e');
      return {'success': false, 'message': 'Failed to record check-out: $e'};
    }
  }

  /// Upload selfie to Firebase Storage
  // Firebase Storage upload method removed - using placeholders instead

  /// Get attendance records for admin
  static Future<List<Map<String, dynamic>>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? driverId,
  }) async {
    try {
      Query query = _firestore.collection('attendance');

      // Apply filters
      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }
      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }
      if (driverId != null) {
        query = query.where('driverId', isEqualTo: driverId);
      }

      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching attendance records: $e');
      return [];
    }
  }

  /// Get active attendance record for a driver
  static Future<Map<String, dynamic>?> getActiveAttendance(
    String driverId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['id'] = querySnapshot.docs.first.id;
        return data;
      }

      return null;
    } catch (e) {
      print('Error fetching active attendance: $e');
      return null;
    }
  }

  /// Update collections completed count
  static Future<void> updateCollectionsCompleted(
    String attendanceId,
    int count,
  ) async {
    try {
      await _firestore.collection('attendance').doc(attendanceId).update({
        'collectionsCompleted': count,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating collections completed: $e');
    }
  }
}
