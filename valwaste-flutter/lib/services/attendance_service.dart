import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Check in (Driver only)
  static Future<void> checkIn({
    required String location,
    String? notes,
    required List<Map<String, String>> teamMembers,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Get user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    
    // Verify user is a driver
    if (userData?['role'] != 'Driver') {
      throw Exception('Only drivers can check in');
    }
    
    // Create attendance record
    await _firestore.collection('attendance').add({
      'driver': userData?['name'] ?? 'Unknown Driver',
      'driverId': user.uid,
      'role': 'Driver',
      'teamCount': teamMembers.length,
      'checkInTime': FieldValue.serverTimestamp(),
      'checkIn': DateTime.now().toIso8601String(),
      'checkOut': null,
      'checkOutTime': null,
      'status': 'pending',
      'members': teamMembers,
      'location': location,
      'notes': notes ?? '',
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Check out (Driver only)
  static Future<void> checkOut({
    required String attendanceId,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Update attendance record
    await _firestore.collection('attendance').doc(attendanceId).update({
      'checkOut': DateTime.now().toIso8601String(),
      'checkOutTime': FieldValue.serverTimestamp(),
      'status': 'completed',
      'checkOutPhotoUrl': null,
      'checkOutNotes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Get attendance records for driver
  static Stream<QuerySnapshot> getDriverAttendance(String driverId) {
    return _firestore
        .collection('attendance')
        .where('driverId', isEqualTo: driverId)
        .orderBy('checkInTime', descending: true)
        .snapshots();
  }
  
  // Get today's attendance for driver
  static Future<DocumentSnapshot?> getTodayAttendance(String driverId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final query = await _firestore
        .collection('attendance')
        .where('driverId', isEqualTo: driverId)
        .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkInTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }
  
  // Get active attendance (checked in but not checked out)
  static Future<DocumentSnapshot?> getActiveAttendance(String driverId) async {
    final query = await _firestore
        .collection('attendance')
        .where('driverId', isEqualTo: driverId)
        .where('checkOut', isNull: true)
        .orderBy('checkInTime', descending: true)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }
}
