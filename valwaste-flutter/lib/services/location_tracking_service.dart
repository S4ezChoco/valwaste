import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_auth_service.dart';
import '../models/user.dart';

class LocationTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _locationTimer;
  static StreamSubscription<Position>? _positionStream;
  static bool _isTracking = false;

  /// Start real-time location tracking for the current user
  static Future<void> startLocationTracking() async {
    if (_isTracking) return;

    try {
      // Check location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        print('Location permission denied');
        return;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) {
        print('No current user found');
        return;
      }

      _isTracking = true;
      print('Starting location tracking for user: ${currentUser.email}');

      // Start position stream with 10-second interval
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Update when user moves 10 meters
            ),
          ).listen(
            (Position position) {
              _updateUserLocation(currentUser, position);
            },
            onError: (error) {
              print('Location tracking error: $error');
            },
          );
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  /// Stop location tracking
  static Future<void> stopLocationTracking() async {
    if (!_isTracking) return;

    try {
      _positionStream?.cancel();
      _locationTimer?.cancel();
      _isTracking = false;
      print('Location tracking stopped');
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  /// Update user location in Firebase
  static Future<void> _updateUserLocation(
    UserModel currentUser,
    Position position,
  ) async {
    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Update user document with location
      await _firestore.collection('users').doc(currentUser.id).update({
        'location': locationData,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      // Also store in a separate locations collection for real-time tracking
      await _firestore.collection('user_locations').doc(currentUser.id).set({
        'userId': currentUser.id,
        'userEmail': currentUser.email,
        'userName': currentUser.name,
        'userRole': currentUser.roleString,
        'barangay': currentUser.barangay,
        'address': currentUser.address, // Add address field
        'location': locationData,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
        'Location updated for ${currentUser.email}: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  /// Get real-time stream of all user locations (only Residents, Drivers, and Barangay Officials)
  static Stream<List<Map<String, dynamic>>> getUserLocationsStream() {
    return _firestore
        .collection('user_locations')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'userId': data['userId'],
                  'userEmail': data['userEmail'],
                  'userName': data['userName'],
                  'userRole': data['userRole'],
                  'barangay': data['barangay'],
                  'address': data['address'], // Add address field
                  'location': data['location'],
                  'isOnline': data['isOnline'],
                  'lastSeen': data['lastSeen'],
                };
              })
              .where((user) {
                // Only show Residents, Drivers, and Barangay Officials
                final role = user['userRole'] as String?;
                return role == 'Resident' ||
                    role == 'Driver' ||
                    role == 'Barangay Official';
              })
              .toList();
        });
  }

  /// Get user locations for a specific role (only Residents, Drivers, and Barangay Officials)
  static Stream<List<Map<String, dynamic>>> getUserLocationsByRole(
    String role,
  ) {
    // Only allow Residents, Drivers, and Barangay Officials
    if (role != 'Resident' && role != 'Driver' && role != 'Barangay Official') {
      return Stream.value([]);
    }

    return _firestore
        .collection('user_locations')
        .where('userRole', isEqualTo: role)
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'userId': data['userId'],
              'userEmail': data['userEmail'],
              'userName': data['userName'],
              'userRole': data['userRole'],
              'barangay': data['barangay'],
              'location': data['location'],
              'isOnline': data['isOnline'],
              'lastSeen': data['lastSeen'],
            };
          }).toList();
        });
  }

  /// Get user locations for a specific barangay (only Residents, Drivers, and Barangay Officials)
  static Stream<List<Map<String, dynamic>>> getUserLocationsByBarangay(
    String barangay,
  ) {
    return _firestore
        .collection('user_locations')
        .where('barangay', isEqualTo: barangay)
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'userId': data['userId'],
                  'userEmail': data['userEmail'],
                  'userName': data['userName'],
                  'userRole': data['userRole'],
                  'barangay': data['barangay'],
                  'address': data['address'], // Add address field
                  'location': data['location'],
                  'isOnline': data['isOnline'],
                  'lastSeen': data['lastSeen'],
                };
              })
              .where((user) {
                // Only show Residents, Drivers, and Barangay Officials
                final role = user['userRole'] as String?;
                return role == 'Resident' ||
                    role == 'Driver' ||
                    role == 'Barangay Official';
              })
              .toList();
        });
  }

  /// Mark user as offline when app is closed
  static Future<void> markUserOffline() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('user_locations').doc(currentUser.id).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      print('User marked as offline: ${currentUser.email}');
    } catch (e) {
      print('Error marking user offline: $e');
    }
  }

  /// Check if location tracking is active
  static bool get isTracking => _isTracking;

  /// Get current user's location
  static Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) return null;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Add a small delay to ensure geolocator is properly initialized
      await Future.delayed(const Duration(milliseconds: 100));

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      // Handle specific error types
      if (e.toString().contains('LateInitializationError')) {
        print('Geolocator internal controller not initialized, retrying...');
        // Retry after a longer delay
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (retryError) {
          print('Retry failed: $retryError');
          return null;
        }
      }
      return null;
    }
  }

  /// Set user as offline
  static Future<void> setUserOffline(String userId) async {
    try {
      await _firestore.collection('user_locations').doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      print('User $userId set as offline');
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }
}
