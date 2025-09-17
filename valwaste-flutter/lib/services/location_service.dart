import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/barangay_data.dart';

class LocationService {
  static const String _gpsTrackingKey = 'gps_tracking_enabled';
  static const String _realtimeLocationSharingKey = 'realtime_location_sharing';

  /// Check if GPS tracking is enabled in user settings
  static Future<bool> isGpsTrackingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_gpsTrackingKey) ?? true; // Default to enabled
    } catch (e) {
      print('Error checking GPS tracking setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Get current location only if GPS tracking is enabled
  static Future<Position?> getCurrentLocationIfEnabled() async {
    try {
      // Check if GPS tracking is enabled
      final isEnabled = await isGpsTrackingEnabled();
      if (!isEnabled) {
        print('GPS tracking is disabled. Location will not be accessed.');
        return null;
      }

      // Check location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        print('Location permission not granted');
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Get current position with more lenient settings
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium
        timeLimit: const Duration(seconds: 15), // Increased timeout
        forceAndroidLocationManager: false, // Use FusedLocationProviderClient
      );

      print('Location obtained: ${position.latitude}, ${position.longitude}');

      // Validate coordinates are reasonable (not 0,0 or extreme values)
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        print('WARNING: GPS returned 0,0 coordinates - this is likely invalid');
        return null;
      }

      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get current location coordinates only if GPS tracking is enabled
  static Future<Map<String, double>?> getCurrentCoordinatesIfEnabled() async {
    try {
      final position = await getCurrentLocationIfEnabled();
      if (position == null) {
        return null;
      }

      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  /// Check if location can be accessed (GPS tracking enabled + permissions)
  static Future<bool> canAccessLocation() async {
    try {
      // Check if GPS tracking is enabled
      final isEnabled = await isGpsTrackingEnabled();
      if (!isEnabled) {
        return false;
      }

      // Check location permission
      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking location access: $e');
      return false;
    }
  }

  /// Request location permission only if GPS tracking is enabled
  static Future<bool> requestLocationPermissionIfEnabled() async {
    try {
      // Check if GPS tracking is enabled
      final isEnabled = await isGpsTrackingEnabled();
      if (!isEnabled) {
        print('GPS tracking is disabled. Permission request skipped.');
        return false;
      }

      // Request location permission
      final permission = await Permission.location.request();
      return permission.isGranted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get location status message
  static Future<String> getLocationStatusMessage() async {
    try {
      final isEnabled = await isGpsTrackingEnabled();
      if (!isEnabled) {
        return 'GPS tracking is disabled in settings';
      }

      final permission = await Permission.location.status;
      if (!permission.isGranted) {
        return 'Location permission not granted';
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services are disabled';
      }

      return 'Location access is available';
    } catch (e) {
      return 'Error checking location status: $e';
    }
  }

  /// Enable GPS tracking in settings
  static Future<void> enableGpsTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_gpsTrackingKey, true);
      print('GPS tracking enabled');
    } catch (e) {
      print('Error enabling GPS tracking: $e');
    }
  }

  /// Disable GPS tracking in settings
  static Future<void> disableGpsTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_gpsTrackingKey, false);
      print('GPS tracking disabled');
    } catch (e) {
      print('Error disabling GPS tracking: $e');
    }
  }

  /// Check if real-time location sharing is enabled
  static Future<bool> isRealtimeLocationSharingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_realtimeLocationSharingKey) ??
          true; // Default to enabled
    } catch (e) {
      print('Error checking real-time location sharing setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Enable real-time location sharing
  static Future<void> enableRealtimeLocationSharing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_realtimeLocationSharingKey, true);
      print('Real-time location sharing enabled');
    } catch (e) {
      print('Error enabling real-time location sharing: $e');
    }
  }

  /// Disable real-time location sharing
  static Future<void> disableRealtimeLocationSharing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_realtimeLocationSharingKey, false);
      print('Real-time location sharing disabled');
    } catch (e) {
      print('Error disabling real-time location sharing: $e');
    }
  }

  /// Get formatted location string for display
  static Future<String> getFormattedLocationString() async {
    try {
      final coordinates = await getCurrentCoordinatesIfEnabled();
      if (coordinates == null) {
        return 'Location not available (GPS tracking may be disabled)';
      }

      return BarangayData.getNearestBarangay(
        coordinates['latitude']!,
        coordinates['longitude']!,
      );
    } catch (e) {
      return 'Error getting location: $e';
    }
  }
}
