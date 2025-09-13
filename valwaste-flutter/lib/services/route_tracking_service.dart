import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/waste_collection.dart';
import 'location_service.dart';

class RouteTrackingService extends ChangeNotifier {
  static final RouteTrackingService _instance =
      RouteTrackingService._internal();
  factory RouteTrackingService() => _instance;
  RouteTrackingService._internal();

  bool _isRouteActive = false;
  WasteCollection? _activeRequest;
  Position? _currentLocation;
  Timer? _distanceUpdateTimer;
  double _currentDistance = 0.0;
  Map<String, dynamic> _routeStats = {};

  // Getters
  bool get isRouteActive => _isRouteActive;
  WasteCollection? get activeRequest => _activeRequest;
  Position? get currentLocation => _currentLocation;
  double get currentDistance => _currentDistance;
  Map<String, dynamic> get routeStats => _routeStats;

  // Initialize location tracking
  Future<void> initializeLocation() async {
    try {
      final position = await LocationService.getCurrentLocationIfEnabled();
      if (position != null) {
        _currentLocation = position;
        notifyListeners();
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Start route tracking
  void startRoute(WasteCollection request) {
    print('RouteTrackingService: Starting route for ${request.wasteTypeText}');
    _isRouteActive = true;
    _activeRequest = request;
    _routeStats = _calculateRouteStats([request]);
    print('RouteTrackingService: Calculated stats: $_routeStats');
    _startDistanceTracking();
    print('RouteTrackingService: Notifying listeners');
    notifyListeners();
  }

  // Stop route tracking
  void stopRoute() {
    _isRouteActive = false;
    _activeRequest = null;
    _distanceUpdateTimer?.cancel();
    _currentDistance = 0.0;
    _routeStats = {};
    notifyListeners();
  }

  // Start distance tracking
  void _startDistanceTracking() {
    _distanceUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isRouteActive && _activeRequest != null) {
        _updateCurrentLocation();
      } else {
        timer.cancel();
      }
    });
  }

  // Update current location
  Future<void> _updateCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocationIfEnabled();
      if (position != null) {
        _currentLocation = position;
        _updateDistance();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Update distance to active request
  void _updateDistance() {
    if (_activeRequest == null || _currentLocation == null) {
      _currentDistance = 0.0;
      return;
    }

    _currentDistance =
        Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          _activeRequest!.latitude ?? 0,
          _activeRequest!.longitude ?? 0,
        ) /
        1000; // Convert to kilometers
  }

  // Get formatted distance string
  String getFormattedDistance() {
    return _currentDistance.toStringAsFixed(1);
  }

  // Calculate route statistics
  Map<String, dynamic> _calculateRouteStats(List<WasteCollection> requests) {
    double totalWeight = 0;
    double totalDistance = 0;
    int estimatedTime = 0;

    for (var request in requests) {
      // Calculate weight (assuming average weight per unit)
      double weightPerUnit = 1.0; // kg per unit
      if (request.unit.toLowerCase().contains('kg')) {
        weightPerUnit = 1.0;
      } else if (request.unit.toLowerCase().contains('bag')) {
        weightPerUnit = 5.0; // 5kg per bag
      } else if (request.unit.toLowerCase().contains('box')) {
        weightPerUnit = 3.0; // 3kg per box
      }
      totalWeight += request.quantity * weightPerUnit;

      // Estimate distance (simplified calculation)
      totalDistance += 2.0; // Assume 2km average distance per stop

      // Estimate time (5 minutes per stop + travel time)
      estimatedTime += 5 + (2 * 2); // 5 min per stop + 2 min per km
    }

    return {
      'totalWeight': totalWeight,
      'totalDistance': totalDistance.toStringAsFixed(1),
      'estimatedTime': estimatedTime,
    };
  }

  // Dispose resources
  @override
  void dispose() {
    _distanceUpdateTimer?.cancel();
    super.dispose();
  }
}
