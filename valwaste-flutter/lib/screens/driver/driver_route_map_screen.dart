import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/constants.dart';
import '../../services/route_optimization_service.dart' hide LatLng;
import '../../services/firebase_auth_service.dart';
import '../../services/location_service.dart';
import '../../models/waste_collection.dart';
import 'dart:math';

class DriverRouteMapScreen extends StatefulWidget {
  const DriverRouteMapScreen({super.key});

  @override
  State<DriverRouteMapScreen> createState() => _DriverRouteMapScreenState();
}

class _DriverRouteMapScreenState extends State<DriverRouteMapScreen> {
  late MapController _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  List<Marker> _routeMarkers = [];
  List<LatLng> _routePoints = [];
  List<WasteCollection> _optimizedRoute = [];
  Map<String, dynamic> _routeStats = {};
  LatLng? _highlightedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _requestLocationPermission();
      await _getCurrentLocation();
      await _loadOptimizedRoute();
      _createRouteMarkers();
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOptimizedRoute() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        final route = await RouteOptimizationService.getOptimizedRouteForUser(
          userId: currentUser.id,
          userRole: currentUser.role,
        );

        final stats = await RouteOptimizationService.calculateRouteStatistics(
          route,
        );

        setState(() {
          _optimizedRoute = route;
          _routeStats = stats;
        });
      }
    } catch (e) {
      print('Error loading optimized route: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Check if GPS tracking is enabled
      final canAccess = await LocationService.canAccessLocation();
      if (!canAccess) {
        final isEnabled = await LocationService.isGpsTrackingEnabled();
        if (!isEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'GPS tracking is disabled in settings. Please enable it to use location features.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission is required to show your position on the map',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        return;
      }

      final status = await Permission.location.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to show your position on the map',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Use the location service that respects GPS tracking setting
      final position = await LocationService.getCurrentLocationIfEnabled();
      if (position == null) {
        print('Location not available - GPS tracking may be disabled');
        // Set fallback location immediately
        if (mounted) {
          setState(() {
            _currentLocation = const LatLng(
              14.7000,
              120.9833,
            ); // Valenzuela City center
          });
          _mapController.move(_currentLocation!, 15.0);
        }
        return;
      }

      print('Raw GPS coordinates: ${position.latitude}, ${position.longitude}');

      // Check if coordinates are within Philippines bounds
      if (position.latitude < 4.0 ||
          position.latitude > 22.0 ||
          position.longitude < 116.0 ||
          position.longitude > 127.0) {
        print('WARNING: GPS coordinates are outside Philippines bounds!');
        print('This might be a mock location or GPS error.');
        print('Using Valenzuela City center as fallback location');

        // Use fallback location instead of invalid GPS
        if (mounted) {
          setState(() {
            _currentLocation = const LatLng(
              14.7000,
              120.9833,
            ); // Valenzuela City center
          });
          _mapController.move(_currentLocation!, 15.0);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        // Move map to current location
        _mapController.move(_currentLocation!, 15.0);
      }
    } catch (e) {
      print('Error getting current location: $e');
      // Set fallback location on error
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(
            14.7000,
            120.9833,
          ); // Valenzuela City center
        });
        _mapController.move(_currentLocation!, 15.0);
      }
    }
  }

  void _createRouteMarkers() {
    _routeMarkers.clear();
    _routePoints.clear();

    // Add current location marker
    if (_currentLocation != null) {
      _routeMarkers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    // Add route stop markers from optimized route
    for (int i = 0; i < _optimizedRoute.length; i++) {
      final collection = _optimizedRoute[i];
      final coordinates = _getCoordinatesFromAddress(collection.address);
      _routePoints.add(coordinates);

      _routeMarkers.add(
        Marker(
          point: coordinates,
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => _showStopDetails(collection, i + 1),
            child: Container(
              decoration: BoxDecoration(
                color: _getStatusColor(collection.statusText),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  LatLng _getCoordinatesFromAddress(String address) {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showStopDetails(WasteCollection collection, int stopNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(collection.statusText),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stopNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'Stop $stopNumber',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Address',
              value: collection.address,
            ),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Scheduled Time',
              value:
                  '${collection.scheduledDate.hour.toString().padLeft(2, '0')}:${collection.scheduledDate.minute.toString().padLeft(2, '0')}',
            ),
            _DetailRow(
              icon: Icons.delete,
              label: 'Waste Type',
              value: collection.wasteTypeText,
            ),
            _DetailRow(
              icon: Icons.scale,
              label: 'Quantity',
              value: '${collection.quantity} ${collection.unit}',
            ),
            _DetailRow(
              icon: Icons.info,
              label: 'Status',
              value: collection.statusText,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openGoogleMapsRoute(
                      _getCoordinatesFromAddress(collection.address),
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMapsInWebView(
                      _getCoordinatesFromAddress(collection.address),
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('View in Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openGoogleMapsRoute(LatLng destination) {
    final destLat = destination.latitude;
    final destLng = destination.longitude;

    // Validate destination coordinates are within reasonable bounds for Philippines
    if (destLat < 4.0 || destLat > 22.0 || destLng < 116.0 || destLng > 127.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid destination coordinates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if current location is valid (within Philippines bounds)
    double currentLat, currentLng;
    if (_currentLocation != null &&
        _currentLocation!.latitude >= 4.0 &&
        _currentLocation!.latitude <= 22.0 &&
        _currentLocation!.longitude >= 116.0 &&
        _currentLocation!.longitude <= 127.0) {
      // Use actual current location if it's within Philippines
      currentLat = _currentLocation!.latitude;
      currentLng = _currentLocation!.longitude;
    } else {
      // Use Valenzuela City center as fallback if current location is invalid or outside Philippines
      currentLat = 14.7000;
      currentLng = 120.9833;
      print(
        'Using fallback location (Valenzuela City) instead of invalid current location',
      );
    }

    // Create Google Maps URL for directions
    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$currentLat,$currentLng&destination=$destLat,$destLng&travelmode=driving';

    // Show Google Maps directly in webview
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GoogleMapsModal(
          url: googleMapsUrl,
          title: 'Directions to Collection Stop',
        );
      },
    );
  }

  void _showCollectionRequestsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CollectionRequestsModal(
          collectionRequests: _optimizedRoute,
          onLocationTap: (WasteCollection collection) {
            // Navigate to the location on the map
            if (collection.latitude != null && collection.longitude != null) {
              final location = LatLng(
                collection.latitude!,
                collection.longitude!,
              );
              _mapController.move(location, 16.0);
              Navigator.of(context).pop(); // Close modal

              // Highlight the location temporarily
              setState(() {
                _highlightedLocation = location;
              });

              // Remove highlight after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _highlightedLocation = null;
                  });
                }
              });

              // Show a brief highlight of the location
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigated to ${collection.address}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _openGoogleMapsInWebView(LatLng destination) {
    final destLat = destination.latitude;
    final destLng = destination.longitude;

    // Create Google Maps URL for location view
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng';

    // Show Google Maps directly in webview
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GoogleMapsModal(
          url: googleMapsUrl,
          title: 'Collection Stop Location',
        );
      },
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _getCurrentLocation();
    }
  }

  void _showFullRoute() {
    if (_routePoints.isNotEmpty) {
      // Calculate bounds to fit all route points
      double minLat = _routePoints.first.latitude;
      double maxLat = _routePoints.first.latitude;
      double minLng = _routePoints.first.longitude;
      double maxLng = _routePoints.first.longitude;

      for (final point in _routePoints) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }

      // Add current location to bounds if available
      if (_currentLocation != null) {
        minLat = minLat < _currentLocation!.latitude
            ? minLat
            : _currentLocation!.latitude;
        maxLat = maxLat > _currentLocation!.latitude
            ? maxLat
            : _currentLocation!.latitude;
        minLng = minLng < _currentLocation!.longitude
            ? minLng
            : _currentLocation!.longitude;
        maxLng = maxLng > _currentLocation!.longitude
            ? maxLng
            : _currentLocation!.longitude;
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Route Map'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Route Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.list_alt),
                onPressed: _showCollectionRequestsModal,
                tooltip: 'Show Collection Requests',
              ),
              if (_optimizedRoute.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_optimizedRoute.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnCurrentLocation,
            tooltip: 'My Location',
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _showFullRoute,
            tooltip: 'Show Full Route',
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route A - Morning Shift',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_optimizedRoute.length} stops • Tap markers for directions',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    _currentLocation ?? const LatLng(14.7000, 120.9833),
                initialZoom: 12.0,
                onMapReady: () {
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15.0);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.valwaste',
                  maxZoom: 19,
                ),
                // Current location marker
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Route markers
                MarkerLayer(markers: _routeMarkers),
                // Highlighted location marker
                if (_highlightedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _highlightedLocation!,
                        width: 80,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Route line (optional - you can draw lines between points)
                if (_routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 3.0,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Route Statistics Overlay
          if (_routeStats.isNotEmpty)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Statistics',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.location_on,
                            label: 'Stops',
                            value: '${_routeStats['totalCollections'] ?? 0}',
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value:
                                '${(_routeStats['totalDistance'] ?? 0.0).toStringAsFixed(1)}km',
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.access_time,
                            label: 'Est. Time',
                            value: '${_routeStats['estimatedTime'] ?? 0}m',
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.scale,
                            label: 'Weight',
                            value:
                                '${(_routeStats['totalWeight'] ?? 0.0).toStringAsFixed(1)}kg',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleMapsModal extends StatefulWidget {
  final String url;
  final String title;

  const GoogleMapsModal({super.key, required this.url, required this.title});

  @override
  State<GoogleMapsModal> createState() => _GoogleMapsModalState();
}

class _GoogleMapsModalState extends State<GoogleMapsModal> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1',
      )
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading map: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');

            // Block Apple App Store URLs on Android
            if (request.url.startsWith('itms-appss://') ||
                request.url.startsWith('itms://') ||
                request.url.contains('apps.apple.com')) {
              print('Blocking Apple App Store URL: ${request.url}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature requires Google Maps app'),
                  backgroundColor: Colors.orange,
                ),
              );
              return NavigationDecision.prevent;
            }

            // Allow Google Maps URLs to load in webview
            if (request.url.contains('google.com/maps') ||
                request.url.contains('maps.google.com') ||
                request.url.contains('googleapis.com') ||
                request.url.contains('gstatic.com')) {
              return NavigationDecision.navigate;
            }

            // Allow Google Maps app launch for Start button functionality
            if (request.url.startsWith('comgooglemaps://') ||
                request.url.startsWith('googlemaps://') ||
                request.url.startsWith('https://www.google.com/maps/dir/') ||
                request.url.startsWith('https://maps.google.com/dir/') ||
                request.url.startsWith('https://www.google.com/maps/') ||
                request.url.startsWith('https://maps.google.com/')) {
              // Try to launch external Google Maps app
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              ).catchError((error) {
                print('Error launching Google Maps: $error');
                // If external app fails, show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please install Google Maps app for navigation',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return false;
              });
              return NavigationDecision.prevent;
            }

            // Block other external URLs to prevent errors
            if (request.url.startsWith('http://') ||
                request.url.startsWith('https://')) {
              // Allow only Google-related domains
              if (request.url.contains('google.com') ||
                  request.url.contains('googleapis.com') ||
                  request.url.contains('gstatic.com')) {
                return NavigationDecision.navigate;
              } else {
                print('Blocking external URL: ${request.url}');
                return NavigationDecision.prevent;
              }
            }

            // Block other app schemes
            if (request.url.contains('://')) {
              print('Blocking app scheme: ${request.url}');
              return NavigationDecision.prevent;
            }

            // Allow relative URLs and data URLs
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _controller.reload(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // WebView Content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading Google Maps...'),
                              SizedBox(height: 8),
                              Text(
                                'This may take a moment',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationModal extends StatefulWidget {
  final String htmlContent;

  const LocationModal({super.key, required this.htmlContent});

  @override
  State<LocationModal> createState() => _LocationModalState();
}

class _LocationModalState extends State<LocationModal> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Open external links in system browser and close modal
            if (request.url.startsWith('https://www.google.com/maps') ||
                request.url.startsWith('https://www.waze.com')) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              Navigator.of(context).pop(); // Close modal
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Location Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // WebView Content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DirectionsModal extends StatefulWidget {
  final String htmlContent;

  const DirectionsModal({super.key, required this.htmlContent});

  @override
  State<DirectionsModal> createState() => _DirectionsModalState();
}

class _DirectionsModalState extends State<DirectionsModal> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Open external links in system browser and close modal
            if (request.url.startsWith('https://www.google.com/maps') ||
                request.url.startsWith('https://www.waze.com') ||
                request.url.startsWith('https://maps.apple.com')) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              Navigator.of(
                context,
              ).pop(); // Close modal after opening external app
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Get Directions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // WebView Content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FastMapView extends StatefulWidget {
  final String htmlContent;
  final String title;

  const FastMapView({super.key, required this.htmlContent, this.title = 'Map'});

  @override
  State<FastMapView> createState() => _FastMapViewState();
}

class _FastMapViewState extends State<FastMapView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Open external links in system browser
            if (request.url.startsWith('https://www.google.com/maps') ||
                request.url.startsWith('https://www.waze.com')) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class GoogleMapsWebView extends StatefulWidget {
  final String url;
  final String title;

  const GoogleMapsWebView({
    super.key,
    required this.url,
    this.title = 'Google Maps',
  });

  @override
  State<GoogleMapsWebView> createState() => _GoogleMapsWebViewState();
}

class _GoogleMapsWebViewState extends State<GoogleMapsWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1',
      )
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Loading Google Maps: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('Google Maps loaded successfully');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading map: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(widget.url))) {
                await launchUrl(
                  Uri.parse(widget.url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            tooltip: 'Open in External Browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading Google Maps...',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This may take a few seconds',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HtmlWebView extends StatefulWidget {
  final String htmlContent;
  final String title;

  const HtmlWebView({
    super.key,
    required this.htmlContent,
    this.title = 'Map View',
  });

  @override
  State<HtmlWebView> createState() => _HtmlWebViewState();
}

class _HtmlWebViewState extends State<HtmlWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Don't show loading for local HTML content
            if (!url.startsWith('data:')) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow external links to open in system browser
            if (request.url.startsWith('https://www.google.com/maps') ||
                request.url.startsWith('https://www.waze.com') ||
                request.url.startsWith('https://maps.apple.com')) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load HTML content and immediately hide loading
    _controller.loadHtmlString(widget.htmlContent);
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadHtmlString(widget.htmlContent),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Modal to display collection requests list with location navigation
class CollectionRequestsModal extends StatefulWidget {
  final List<WasteCollection> collectionRequests;
  final Function(WasteCollection) onLocationTap;

  const CollectionRequestsModal({
    super.key,
    required this.collectionRequests,
    required this.onLocationTap,
  });

  @override
  State<CollectionRequestsModal> createState() =>
      _CollectionRequestsModalState();
}

class _CollectionRequestsModalState extends State<CollectionRequestsModal> {
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocationIfEnabled();
      if (position != null && mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Enhanced Modal Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collection Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.collectionRequests.length} requests',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_currentLocation != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Location enabled',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            // Requests List
            Expanded(
              child: widget.collectionRequests.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No collection requests',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Requests will appear here when assigned',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.collectionRequests.length,
                      itemBuilder: (context, index) {
                        final request = widget.collectionRequests[index];
                        return _buildRequestCard(context, request, index + 1);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WasteCollection request,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(request.status).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(request.status).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onLocationTap(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with number and status
              Row(
                children: [
                  // Request number with enhanced design
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(request.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusDisplayName(request.status),
                      style: TextStyle(
                        color: _getStatusColor(request.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Distance badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.navigation,
                          color: Colors.blue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDistanceText(request),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Address
              Text(
                request.address,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Details row
              Row(
                children: [
                  // Waste type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.category,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getWasteTypeDisplayName(request.wasteType),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(request.scheduledDate),
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Notes if available
              if (request.notes != null && request.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.notes!,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Action button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onLocationTap(request),
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Navigate to Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWasteTypeDisplayName(WasteType wasteType) {
    switch (wasteType) {
      case WasteType.general:
        return 'General Waste';
      case WasteType.recyclable:
        return 'Recyclable';
      case WasteType.hazardous:
        return 'Hazardous';
      case WasteType.organic:
        return 'Organic';
      case WasteType.electronic:
        return 'Electronic';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get status display name
  String _getStatusDisplayName(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return 'Pending';
      case CollectionStatus.scheduled:
        return 'Scheduled';
      case CollectionStatus.approved:
        return 'Approved';
      case CollectionStatus.inProgress:
        return 'In Progress';
      case CollectionStatus.completed:
        return 'Completed';
      case CollectionStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get status color
  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return Colors.orange;
      case CollectionStatus.scheduled:
        return Colors.teal;
      case CollectionStatus.approved:
        return Colors.blue;
      case CollectionStatus.inProgress:
        return Colors.purple;
      case CollectionStatus.completed:
        return Colors.green;
      case CollectionStatus.cancelled:
        return Colors.red;
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Get distance text for display
  String _getDistanceText(WasteCollection request) {
    if (_currentLocation == null ||
        request.latitude == null ||
        request.longitude == null) {
      return 'Distance unknown';
    }

    final distance = _calculateDistance(
      _currentLocation!,
      LatLng(request.latitude!, request.longitude!),
    );

    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
