import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sync user data between mobile and admin
  static Future<void> syncUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Check if user exists by email (from PHP admin panel)
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          // User exists from PHP admin, copy data to correct UID
          final existingData = userQuery.docs.first.data();
          
          // Normalize role from PHP admin panel
          String normalizedRole = _normalizeRole(existingData['role']);
          existingData['role'] = normalizedRole;
          
          await _firestore.collection('users').doc(user.uid).set({
            ...existingData,
            'authUserId': user.uid,
            'lastSync': FieldValue.serverTimestamp(),
          });
          
          print('User data synced from PHP admin panel');
        }
      } else {
        // Update last sync time
        await _firestore.collection('users').doc(user.uid).update({
          'lastSync': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing user data: $e');
    }
  }
  
  // Normalize role names from PHP admin panel
  static String _normalizeRole(dynamic role) {
    if (role == null) return 'Resident';
    
    String roleStr = role.toString().toLowerCase().trim();
    
    switch (roleStr) {
      case 'driver':
        return 'Driver';
      case 'waste collector':
      case 'wastecollector':
      case 'waste_collector':
      case 'palero':
        return 'Waste Collector';
      case 'barangay official':
      case 'barangay_official':
      case 'barangayofficial':
        return 'Barangay Official';
      case 'administrator':
      case 'admin':
        return 'Administrator';
      default:
        return 'Resident';
    }
  }
  
  // Sync truck schedules from admin panel
  static Future<void> syncTruckSchedules() async {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Get today's schedules
      final schedulesQuery = await _firestore
          .collection('truck_schedule')
          .where('date', isEqualTo: todayString)
          .get();
      
      print('Found ${schedulesQuery.docs.length} schedules for today');
      
      // Process each schedule
      for (var doc in schedulesQuery.docs) {
        final data = doc.data();
        
        // Ensure schedule has required fields
        if (data['driver'] == null || data['truck'] == null) {
          continue;
        }
        
        // Update schedule with sync info
        await doc.reference.update({
          'lastSyncedToMobile': FieldValue.serverTimestamp(),
          'syncStatus': 'active',
        });
      }
    } catch (e) {
      print('Error syncing truck schedules: $e');
    }
  }
  
  // Sync attendance records
  static Future<void> syncAttendanceRecords() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Get user's attendance records
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('driverId', isEqualTo: user.uid)
          .orderBy('checkInTime', descending: true)
          .limit(10)
          .get();
      
      print('Found ${attendanceQuery.docs.length} attendance records');
      
      // Update sync status for each record
      for (var doc in attendanceQuery.docs) {
        await doc.reference.update({
          'lastSyncedToMobile': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing attendance records: $e');
    }
  }
  
  // Sync collection requests
  static Future<void> syncCollectionRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Get user's collection requests
      final requestsQuery = await _firestore
          .collection('collection_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      print('Found ${requestsQuery.docs.length} collection requests');
      
      // Update sync status
      for (var doc in requestsQuery.docs) {
        await doc.reference.update({
          'lastSyncedToMobile': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing collection requests: $e');
    }
  }
  
  // Full sync - call this on app startup and periodically
  static Future<Map<String, dynamic>> performFullSync() async {
    try {
      print('Starting full sync...');
      
      // Sync user data first
      await syncUserData();
      
      // Then sync other data
      await Future.wait([
        syncTruckSchedules(),
        syncAttendanceRecords(),
        syncCollectionRequests(),
      ]);
      
      print('Full sync completed successfully');
      
      return {
        'success': true,
        'message': 'Data synchronized successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Full sync failed: $e');
      return {
        'success': false,
        'message': 'Sync failed: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  // Monitor real-time changes from admin panel
  static Stream<QuerySnapshot> monitorAdminChanges(String collection) {
    return _firestore
        .collection(collection)
        .where('source', isEqualTo: 'admin_panel')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
  
  // Push mobile changes to admin panel
  static Future<void> pushToAdminPanel(String collection, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).add({
        ...data,
        'source': 'mobile_app',
        'deviceInfo': {
          'platform': 'flutter',
          'userId': _auth.currentUser?.uid,
          'userEmail': _auth.currentUser?.email,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error pushing to admin panel: $e');
      throw e;
    }
  }
}
