import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/waste_collection.dart';
import '../models/user.dart';

class RouteOptimizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Route optimization algorithm using nearest neighbor with improvements
  static Future<List<WasteCollection>> optimizeRoute({
    required List<WasteCollection> collections,
    required LatLng startLocation,
  }) async {
    if (collections.isEmpty) return [];

    List<WasteCollection> optimizedRoute = [];
    List<WasteCollection> remainingCollections = List.from(collections);
    LatLng currentLocation = startLocation;

    // Sort by priority (scheduled time, waste type, etc.)
    remainingCollections.sort((a, b) {
      // First priority: scheduled time
      int timeComparison = a.scheduledDate.compareTo(b.scheduledDate);
      if (timeComparison != 0) return timeComparison;

      // Second priority: waste type (hazardous first, then electronic, etc.)
      int typeComparison = _getWasteTypePriority(
        a.wasteType,
      ).compareTo(_getWasteTypePriority(b.wasteType));
      if (typeComparison != 0) return typeComparison;

      // Third priority: quantity (larger quantities first)
      return b.quantity.compareTo(a.quantity);
    });

    // Use nearest neighbor algorithm with improvements
    while (remainingCollections.isNotEmpty) {
      WasteCollection? nearestCollection;
      double shortestDistance = double.infinity;
      int nearestIndex = -1;

      for (int i = 0; i < remainingCollections.length; i++) {
        final collection = remainingCollections[i];
        final distance = await _calculateDistance(
          currentLocation,
          await _getLocationFromAddress(collection.address),
        );

        // Apply time constraints
        if (_isWithinTimeWindow(collection, optimizedRoute.length)) {
          if (distance < shortestDistance) {
            shortestDistance = distance;
            nearestCollection = collection;
            nearestIndex = i;
          }
        }
      }

      if (nearestCollection != null) {
        optimizedRoute.add(nearestCollection);
        remainingCollections.removeAt(nearestIndex);
        currentLocation = await _getLocationFromAddress(
          nearestCollection.address,
        );
      } else {
        // If no collection fits time window, take the first one
        optimizedRoute.add(remainingCollections.first);
        remainingCollections.removeAt(0);
        currentLocation = await _getLocationFromAddress(
          optimizedRoute.last.address,
        );
      }
    }

    return optimizedRoute;
  }

  // Get waste type priority (lower number = higher priority)
  static int _getWasteTypePriority(WasteType wasteType) {
    switch (wasteType) {
      case WasteType.hazardous:
        return 1;
      case WasteType.electronic:
        return 2;
      case WasteType.organic:
        return 3;
      case WasteType.recyclable:
        return 4;
      case WasteType.general:
        return 5;
    }
  }

  // Check if collection is within acceptable time window
  static bool _isWithinTimeWindow(
    WasteCollection collection,
    int routePosition,
  ) {
    final now = DateTime.now();
    final scheduledTime = collection.scheduledDate;
    final timeDifference = scheduledTime.difference(now).inHours;

    // Allow collections within 2 hours of scheduled time
    return timeDifference.abs() <= 2;
  }

  // Calculate distance between two points
  static Future<double> _calculateDistance(LatLng point1, LatLng point2) async {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Get location from address (simplified - in real app, use geocoding service)
  static Future<LatLng> _getLocationFromAddress(String address) async {
    // More accurate coordinate mapping for Valenzuela City areas
    final lowerAddress = address.toLowerCase();

    if (lowerAddress.contains('malanday')) {
      return const LatLng(14.7095, 120.9483); // Malanday, Valenzuela
    } else if (lowerAddress.contains('marulas')) {
      return const LatLng(14.6900, 120.9750); // Marulas, Valenzuela
    } else if (lowerAddress.contains('karuhatan')) {
      return const LatLng(14.7050, 120.9700); // Karuhatan, Valenzuela
    } else if (lowerAddress.contains('dalandanan')) {
      return const LatLng(14.7150, 120.9800); // Dalandanan, Valenzuela
    } else if (lowerAddress.contains('bagbaguin')) {
      return const LatLng(14.7200, 120.9900); // Bagbaguin, Valenzuela
    } else if (lowerAddress.contains('bignay')) {
      return const LatLng(14.6800, 120.9600); // Bignay, Valenzuela
    } else if (lowerAddress.contains('canumay')) {
      return const LatLng(14.7300, 120.9500); // Canumay, Valenzuela
    } else if (lowerAddress.contains('coloong')) {
      return const LatLng(14.7000, 120.9400); // Coloong, Valenzuela
    } else if (lowerAddress.contains('gen. t. de leon')) {
      return const LatLng(14.7100, 120.9600); // Gen. T. de Leon, Valenzuela
    } else if (lowerAddress.contains('isla')) {
      return const LatLng(14.6900, 120.9400); // Isla, Valenzuela
    } else if (lowerAddress.contains('lawang bato')) {
      return const LatLng(14.7400, 120.9800); // Lawang Bato, Valenzuela
    } else if (lowerAddress.contains('lingunan')) {
      return const LatLng(14.7200, 120.9700); // Lingunan, Valenzuela
    } else if (lowerAddress.contains('maehsan')) {
      return const LatLng(14.6800, 120.9800); // Maehsan, Valenzuela
    } else if (lowerAddress.contains('mapulang lupa')) {
      return const LatLng(14.7300, 120.9600); // Mapulang Lupa, Valenzuela
    } else if (lowerAddress.contains('pariancillo villa')) {
      return const LatLng(14.7000, 120.9500); // Pariancillo Villa, Valenzuela
    } else if (lowerAddress.contains('pasolo')) {
      return const LatLng(14.7100, 120.9400); // Pasolo, Valenzuela
    } else if (lowerAddress.contains('poblacion')) {
      return const LatLng(14.7000, 120.9833); // Poblacion, Valenzuela
    } else if (lowerAddress.contains('polo')) {
      return const LatLng(14.6900, 120.9700); // Polo, Valenzuela
    } else if (lowerAddress.contains('rincon')) {
      return const LatLng(14.7200, 120.9400); // Rincon, Valenzuela
    } else if (lowerAddress.contains('tagalag')) {
      return const LatLng(14.6800, 120.9500); // Tagalag, Valenzuela
    } else if (lowerAddress.contains('ugong')) {
      return const LatLng(14.7400, 120.9600); // Ugong, Valenzuela
    } else if (lowerAddress.contains('veinte reales')) {
      return const LatLng(14.7300, 120.9800); // Veinte Reales, Valenzuela
    } else if (lowerAddress.contains('wawang pulo')) {
      return const LatLng(14.7100, 120.9500); // Wawang Pulo, Valenzuela
    } else {
      // Default to Valenzuela City center with slight variation based on address
      final hash = address.hashCode.abs();
      return LatLng(
        14.7000 + (hash % 200 - 100) / 10000, // ±0.01 degree variation
        120.9833 + (hash % 200 - 100) / 10000, // ±0.01 degree variation
      );
    }
  }

  // Get optimized route for a specific driver/collector
  static Future<List<WasteCollection>> getOptimizedRouteForUser({
    required String userId,
    required UserRole userRole,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Simplified query to avoid index requirements
      Query query = _firestore
          .collection('collections')
          .where('status', whereIn: ['scheduled', 'inProgress']);

      // Get user's current location (in real app, get from GPS)
      final userLocation = await _getUserCurrentLocation(userId);

      final querySnapshot = await query.get();
      final allCollections = querySnapshot.docs
          .map(
            (doc) =>
                WasteCollection.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Filter by date range in memory to avoid index requirements
      final collections = allCollections.where((collection) {
        return collection.scheduledDate.isAfter(startOfDay) &&
            collection.scheduledDate.isBefore(endOfDay);
      }).toList();

      // Filter collections based on user role and area
      List<WasteCollection> filteredCollections = _filterCollectionsByRole(
        collections,
        userRole,
        userId,
      );

      // Optimize route
      return await optimizeRoute(
        collections: filteredCollections,
        startLocation: userLocation,
      );
    } catch (e) {
      print('Error getting optimized route: $e');
      return [];
    }
  }

  // Filter collections based on user role
  static List<WasteCollection> _filterCollectionsByRole(
    List<WasteCollection> collections,
    UserRole userRole,
    String userId,
  ) {
    switch (userRole) {
      case UserRole.driver:
      case UserRole.collector:
        // Get collections assigned to this user
        return collections.where((collection) {
          return collection.assignedTo == userId;
        }).toList();
      case UserRole.barangayOfficial:
        // Get collections in their barangay
        return collections.where((collection) {
          // Filter by barangay - get user's barangay first
          return true; // For now, return all collections
        }).toList();
      default:
        return [];
    }
  }

  // Get user's current location
  static Future<LatLng> _getUserCurrentLocation(String userId) async {
    try {
      // In a real app, you would get the user's current GPS location
      // For now, return a default location
      return const LatLng(14.7000, 120.9833);
    } catch (e) {
      print('Error getting user location: $e');
      return const LatLng(14.7000, 120.9833);
    }
  }

  // Calculate route statistics
  static Future<Map<String, dynamic>> calculateRouteStatistics(
    List<WasteCollection> route,
  ) async {
    if (route.isEmpty) {
      return {
        'totalDistance': 0.0,
        'estimatedTime': 0,
        'totalCollections': 0,
        'totalWeight': 0.0,
        'wasteTypeBreakdown': <String, int>{},
      };
    }

    double totalDistance = 0.0;
    double totalWeight = 0.0;
    Map<String, int> wasteTypeBreakdown = {};

    // Calculate total weight and waste type breakdown
    for (final collection in route) {
      totalWeight += collection.quantity;
      final wasteType = collection.wasteTypeText;
      wasteTypeBreakdown[wasteType] = (wasteTypeBreakdown[wasteType] ?? 0) + 1;
    }

    // Calculate total distance (simplified)
    for (int i = 0; i < route.length - 1; i++) {
      final distance = await _calculateDistance(
        await _getLocationFromAddress(route[i].address),
        await _getLocationFromAddress(route[i + 1].address),
      );
      totalDistance += distance;
    }

    // Estimate time (assuming 5 minutes per collection + travel time)
    final estimatedTime =
        (route.length * 5) + (totalDistance / 1000 * 2).round();

    return {
      'totalDistance': totalDistance,
      'estimatedTime': estimatedTime,
      'totalCollections': route.length,
      'totalWeight': totalWeight,
      'wasteTypeBreakdown': wasteTypeBreakdown,
    };
  }

  // Update collection status and assign to user
  static Future<bool> assignCollectionToUser({
    required String collectionId,
    required String userId,
    required UserRole userRole,
  }) async {
    try {
      await _firestore.collection('collections').doc(collectionId).update({
        'assigned_to': userId,
        'assigned_role': userRole.toString().split('.').last,
        'assigned_at': FieldValue.serverTimestamp(),
        'status': 'inProgress',
      });

      return true;
    } catch (e) {
      print('Error assigning collection: $e');
      return false;
    }
  }

  // Get real-time route updates (simplified to avoid index requirements)
  static Stream<List<WasteCollection>> getRouteUpdates({
    required String userId,
    required UserRole userRole,
  }) {
    return _firestore
        .collection('collections')
        .where('assigned_to', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final collections = snapshot.docs
              .map((doc) => WasteCollection.fromJson(doc.data()))
              .toList();

          // Filter by status in memory
          return collections.where((collection) {
            return collection.status.toString().split('.').last ==
                    'scheduled' ||
                collection.status.toString().split('.').last == 'inProgress';
          }).toList();
        });
  }

  // Automatically assign collections to available drivers
  static Future<void> autoAssignCollectionsToDrivers() async {
    try {
      // Get all unassigned collections for today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Simplified query to avoid index requirements
      final allCollections = await _firestore
          .collection('collections')
          .where('status', isEqualTo: 'scheduled')
          .get();

      // Filter in memory to avoid index requirements
      final unassignedCollections = allCollections.docs.where((doc) {
        final data = doc.data();
        final scheduledDate = data['scheduled_date'];
        final assignedTo = data['assigned_to'];

        if (scheduledDate == null || assignedTo != null) return false;

        DateTime collectionDate;
        if (scheduledDate is String) {
          collectionDate = DateTime.parse(scheduledDate);
        } else if (scheduledDate is Timestamp) {
          collectionDate = scheduledDate.toDate();
        } else {
          return false;
        }

        return collectionDate.isAfter(startOfDay) &&
            collectionDate.isBefore(endOfDay);
      }).toList();

      // Get all available drivers
      final availableDrivers = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .get();

      if (availableDrivers.docs.isEmpty) {
        print('No available drivers found');
        return;
      }

      // Group collections by barangay
      final Map<String, List<QueryDocumentSnapshot>> collectionsByBarangay = {};
      for (final doc in unassignedCollections) {
        final data = doc.data();
        final barangay = data['barangay'] ?? 'Unknown';
        collectionsByBarangay.putIfAbsent(barangay, () => []).add(doc);
      }

      // Assign collections to drivers by barangay
      int driverIndex = 0;
      for (final barangay in collectionsByBarangay.keys) {
        final collections = collectionsByBarangay[barangay]!;

        // Get drivers for this barangay (or all drivers if no specific assignment)
        final driversForBarangay = availableDrivers.docs.where((driverDoc) {
          final driverData = driverDoc.data();
          final driverBarangay = driverData['barangay'] ?? 'Valenzuela City';
          return driverBarangay == barangay ||
              driverBarangay == 'Valenzuela City';
        }).toList();

        if (driversForBarangay.isEmpty) {
          // If no drivers for this barangay, use any available driver
          driversForBarangay.addAll(availableDrivers.docs);
        }

        // Assign collections to drivers in round-robin fashion
        for (final collectionDoc in collections) {
          final driverDoc =
              driversForBarangay[driverIndex % driversForBarangay.length];
          final driverId = driverDoc.id;

          await assignCollectionToUser(
            collectionId: collectionDoc.id,
            userId: driverId,
            userRole: UserRole.driver,
          );

          driverIndex++;
        }
      }

      print(
        'Auto-assigned ${unassignedCollections.length} collections to drivers',
      );
    } catch (e) {
      print('Error auto-assigning collections: $e');
    }
  }

  // Get available drivers for assignment
  static Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    try {
      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .get();

      return driversSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting available drivers: $e');
      return [];
    }
  }
}

// Helper class for LatLng
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
