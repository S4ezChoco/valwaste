import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get schedules for current driver
  static Future<List<Map<String, dynamic>>> getDriverSchedules() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get user document to get driver name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final driverName = userDoc.data()?['name'] ?? '';
      final driverEmail = user.email ?? '';

      // Query schedules by driver name or email
      final byNameQuery = await _firestore
          .collection('truck_schedule')
          .where('driver', isEqualTo: driverName)
          .orderBy('date', descending: true)
          .get();

      final byEmailQuery = await _firestore
          .collection('truck_schedule')
          .where('driverEmail', isEqualTo: driverEmail)
          .orderBy('date', descending: true)
          .get();

      final byIdQuery = await _firestore
          .collection('truck_schedule')
          .where('driverId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      // Combine results and remove duplicates
      final Map<String, Map<String, dynamic>> scheduleMap = {};
      
      for (var doc in byNameQuery.docs) {
        scheduleMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }
      
      for (var doc in byEmailQuery.docs) {
        scheduleMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }
      
      for (var doc in byIdQuery.docs) {
        scheduleMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }

      return scheduleMap.values.toList();
    } catch (e) {
      print('Error fetching driver schedules: $e');
      return [];
    }
  }

  // Get today's schedule for driver
  static Future<Map<String, dynamic>?> getTodaySchedule() async {
    final schedules = await getDriverSchedules();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      return schedules.firstWhere(
        (schedule) => schedule['date'] == todayString,
      );
    } catch (e) {
      return null;
    }
  }

  // Get past schedules (history)
  static Future<List<Map<String, dynamic>>> getPastSchedules() async {
    final schedules = await getDriverSchedules();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return schedules.where((schedule) {
      final scheduleDate = schedule['date'] as String? ?? '';
      return scheduleDate.compareTo(todayString) < 0;
    }).toList();
  }

  // Get upcoming schedules
  static Future<List<Map<String, dynamic>>> getUpcomingSchedules() async {
    final schedules = await getDriverSchedules();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return schedules.where((schedule) {
      final scheduleDate = schedule['date'] as String? ?? '';
      return scheduleDate.compareTo(todayString) >= 0;
    }).toList();
  }

  // Get schedule by ID
  static Future<Map<String, dynamic>?> getScheduleById(String scheduleId) async {
    try {
      final doc = await _firestore
          .collection('truck_schedule')
          .doc(scheduleId)
          .get();
      
      if (doc.exists) {
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching schedule by ID: $e');
      return null;
    }
  }

  // Stream of driver schedules for real-time updates
  static Stream<List<Map<String, dynamic>>> streamDriverSchedules() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final driverName = userDoc.data()?['name'] ?? '';
      final driverEmail = user.email ?? '';

      final byNameQuery = await _firestore
          .collection('truck_schedule')
          .where('driver', isEqualTo: driverName)
          .orderBy('date', descending: true)
          .get();

      final byEmailQuery = await _firestore
          .collection('truck_schedule')
          .where('driverEmail', isEqualTo: driverEmail)
          .orderBy('date', descending: true)
          .get();

      final byIdQuery = await _firestore
          .collection('truck_schedule')
          .where('driverId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      // Combine results and remove duplicates
      final Map<String, Map<String, dynamic>> scheduleMap = {};
      
      for (var doc in byNameQuery.docs) {
        scheduleMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }
      
      for (var doc in byEmailQuery.docs) {
        scheduleMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }
      
      for (var doc in byIdQuery.docs) {
        scheduleMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }

      return scheduleMap.values.toList();
    });
  }
}
