import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static Timer? _locationTimer;
  static StreamSubscription<Position>? _positionStream;
  
  // Start tracking driver location
  static Future<void> startLocationTracking() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Check if user is a driver
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      print('User document not found in Firestore');
      return;
    }
    
    final role = userDoc.data()?['role']?.toString().toLowerCase();
    if (role != 'driver' && role != 'waste collector') {
      print('User is not a driver or waste collector: $role');
      return;
    }
    
    // Check if driver has a schedule today
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final scheduleQuery = await _firestore
        .collection('truck_schedule')
        .where('date', isEqualTo: todayString)
        .where('driver', isEqualTo: userDoc.data()?['name'])
        .get();
    
    if (scheduleQuery.docs.isEmpty) {
      print('No schedule found for driver today');
      return;
    }
    
    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    
    // Get schedule details
    final schedule = scheduleQuery.docs.first.data();
    
    // Start location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      // Update driver location in Firebase
      await _firestore.collection('driver_locations').doc(user.uid).set({
        'driverId': user.uid,
        'driverName': userDoc.data()?['name'],
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed * 3.6, // Convert to km/h
        'accuracy': position.accuracy,
        'isActive': true,
        'lastUpdate': FieldValue.serverTimestamp(),
        'truckId': schedule['truck'],
        'status': 'active',
        'scheduleDetails': {
          'date': schedule['date'],
          'startTime': schedule['startTime'],
          'endTime': schedule['endTime'],
          'streets': schedule['streets'],
        },
      }, SetOptions(merge: true));
    });
    
    // Update online status
    await _firestore.collection('driver_locations').doc(user.uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
  
  // Stop tracking driver location
  static Future<void> stopLocationTracking() async {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('driver_locations').doc(user.uid).update({
        'isActive': false,
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
}
