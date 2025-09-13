import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../../services/firebase_collection_service.dart';
import '../../services/location_tracking_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/waste_collection.dart';
import '../../models/user.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  MapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  List<Marker> _wasteCollectionPoints = [];
  LatLng? _selectedBarangayLocation;
  bool _isSatelliteView = false;
  bool _showTraffic = true;

  // Route visualization
  List<LatLng> _routePoints = [];
  bool _showRoute = false;

  // Selected collection request for bottom card
  WasteCollection? _selectedCollectionRequest;

  // Real-time collection request tracking
  List<WasteCollection> _collectionRequests = [];
  StreamSubscription<List<WasteCollection>>? _collectionRequestsSubscription;
  bool _showCollectionRequests = true;

  // Announcement system
  Map<String, dynamic>? _currentAnnouncement;
  StreamSubscription<QuerySnapshot>? _announcementSubscription;
  bool _showAnnouncementCard = false;
  bool _announcementManuallyDismissed = false;

  // Keep map state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  // Prevent multiple initializations
  bool _isMapInitialized = false;

  // Handle when map becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // If map is already initialized, don't show loading
    if (_isMapInitialized && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Online users tracking
  List<Map<String, dynamic>> _onlineUsers = [];
  StreamSubscription<List<Map<String, dynamic>>>? _onlineUsersSubscription;
  bool _showOnlineUsers = true; // Controls user markers on map
  bool _showOnlineUsersPanel = false; // Controls the panel overlay

  // Coordinates for each barangay in Valenzuela City
  final Map<String, LatLng> _barangayCoordinates = {
    'Valenzuela City': const LatLng(14.7000, 120.9833),
    'Barangay Isla': const LatLng(14.6950, 120.9750),
    'Barangay Malanday': const LatLng(14.7100, 120.9900),
    'Barangay Marulas': const LatLng(14.6900, 120.9750),
    'Barangay Karuhatan': const LatLng(14.7050, 120.9700),
    'Barangay Dalandanan': const LatLng(14.7150, 120.9800),
    'Barangay Gen. T. de Leon': const LatLng(14.7200, 120.9850),
    'Barangay Mapulang Lupa': const LatLng(14.7250, 120.9750),
    'Barangay Parada': const LatLng(14.6800, 120.9800),
    'Barangay Poblacion': const LatLng(14.7000, 120.9833),
    'Barangay Rincon': const LatLng(14.6900, 120.9900),
    'Barangay Tagalag': const LatLng(14.7050, 120.9850),
    'Barangay Ugong': const LatLng(14.7150, 120.9700),
    'Barangay Viente Reales': const LatLng(14.7200, 120.9750),
  };

  @override
  void initState() {
    super.initState();

    // Only initialize once to prevent reloading when switching tabs
    if (!_isMapInitialized) {
      _mapController = MapController();
      _initializeMap();
      _startLocationTracking();
      _setupCollectionRequestsListener();
      _setupOnlineUsersListener(); // Automatically start online users listener
      _setupAnnouncementListener(); // Setup announcement listener
      _isMapInitialized = true;
    }
  }

  Future<void> _initializeMap() async {
    try {
      await _requestLocationPermission();
      await _getCurrentLocation();
      _loadWasteCollectionPoints();
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

  Future<void> _requestLocationPermission() async {
    try {
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
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable location services.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Using default location.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Using default location.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Add a small delay to ensure geolocator is properly initialized
      await Future.delayed(const Duration(milliseconds: 100));

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          // Clear selected barangay marker when going to current location
          _selectedBarangayLocation = null;
        });

        // Center map on current location
        if (_currentLocation != null && mounted) {
          _mapController?.move(_currentLocation!, 15.0);
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      // Handle specific error types
      if (e.toString().contains('LateInitializationError')) {
        print('Geolocator internal controller not initialized, retrying...');
        // Retry after a longer delay
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
              _selectedBarangayLocation = null;
            });
            if (_currentLocation != null && mounted) {
              _mapController?.move(_currentLocation!, 15.0);
            }
          }
        } catch (retryError) {
          print('Retry failed: $retryError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to get current location. Using default location.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error getting location: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _loadWasteCollectionPoints() {
    // Collection points will only appear after resident requests are approved by barangay
    // and assigned to drivers. No collection centers should be visible by default.
    // For drivers, only show assigned collection stops, not general collection centers.
    final currentUser = FirebaseAuthService.currentUser;
    if (currentUser?.role == UserRole.driver ||
        currentUser?.role == UserRole.collector) {
      // Drivers and collectors should not see collection centers
      _wasteCollectionPoints = [];
    } else {
      // Other roles (residents, barangay officials, administrators) can see collection centers
      _wasteCollectionPoints = [];
    }
  }

  Widget _buildCompactInfoRow(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    bool isStatus = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Row(
                children: [
                  if (isStatus) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    subtitle,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get icon for user role
  IconData _getUserRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'resident':
        return Icons.person;
      case 'driver':
        return Icons.local_shipping;
      case 'barangay official':
        return Icons.location_city;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Don't show loading if map is already initialized
    if (_isLoading && !_isMapInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ValWaste Banner
          _buildValWasteBanner(),
          // Map - WebView or FlutterMap
          Expanded(
            child: Stack(
              children: [
                // Map content
                FlutterMap(
                  mapController: _mapController!,
                  options: MapOptions(
                    initialCenter:
                        _currentLocation ?? const LatLng(14.7000, 120.9833),
                    initialZoom: 12.0,
                    onTap: (_, __) {
                      // Handle map tap if needed
                    },
                    onMapReady: () {
                      // Map is ready, ensure controller is properly initialized
                      if (_currentLocation != null && mounted) {
                        _mapController?.move(_currentLocation!, 15.0);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _getTileUrl(),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
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
                    // Waste collection points
                    MarkerLayer(markers: _wasteCollectionPoints),
                    // Real-time collection requests
                    MarkerLayer(markers: _getCollectionRequestMarkers()),
                    // Online users markers
                    if (_showOnlineUsers)
                      MarkerLayer(markers: _getOnlineUserMarkers()),
                    // Selected barangay marker
                    if (_selectedBarangayLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedBarangayLocation!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Route polyline
                    if (_showRoute && _routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),
                  ],
                ),
                // Vertical button overlay
                _buildVerticalButtonOverlay(),
                // Online users overlay
                if (_showOnlineUsersPanel) _buildOnlineUsersOverlay(),
                // Next Collection Card
                _buildNextCollectionCard(),
                // Selected Collection Request Card
                if (_selectedCollectionRequest != null)
                  _buildSelectedCollectionRequestCard(),
                // Zoom controls
                _buildZoomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build ValWaste banner
  Widget _buildValWasteBanner() {
    final currentUser = FirebaseAuthService.currentUser;
    final userName = currentUser?.name ?? 'User';
    final userRole = currentUser?.role.toString().split('.').last ?? 'Resident';
    final barangay = currentUser?.barangay ?? 'Barangay Isla';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32), // Dark green
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getUserRoleIcon(userRole),
              size: 30,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ValWaste logo
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Val',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Waste',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back, $userName!',
                  style: const TextStyle(
                    color: Color(0xFFC8E6C9), // Light green
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$userRole of $barangay',
                  style: const TextStyle(
                    color: Color(0xFFA5D6A7), // Lighter green
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build vertical button overlay with map controls
  Widget _buildVerticalButtonOverlay() {
    return Positioned(
      right: 16,
      bottom: 100, // Position above the bottom navigation
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delivery truck button (for drivers only)
          if (FirebaseAuthService.currentUser?.role == UserRole.driver)
            _buildFloatingButton(
              icon: _showCollectionRequests
                  ? Icons.local_shipping
                  : Icons.local_shipping_outlined,
              onPressed: _showAllCollectionRequestsModal,
              isActive: _showCollectionRequests,
              heroTag: "requests",
            ),
          const SizedBox(height: 8),
          // Traffic toggle button
          _buildFloatingButton(
            icon: Icons.traffic,
            onPressed: () {
              setState(() {
                _showTraffic = !_showTraffic;
                // Keep satellite view enabled with traffic
              });
            },
            isActive: _showTraffic,
            heroTag: "traffic",
          ),
          const SizedBox(height: 8),
          // Satellite view toggle button
          _buildFloatingButton(
            icon: _isSatelliteView ? Icons.map : Icons.satellite,
            onPressed: () {
              setState(() {
                _isSatelliteView = !_isSatelliteView;
                // Keep traffic enabled in both satellite and map view
              });
            },
            isActive: _isSatelliteView,
            heroTag: "satellite",
          ),
          const SizedBox(height: 8),
          // Clear route button (only show when route is active)
          if (_showRoute)
            _buildFloatingButton(
              icon: Icons.clear,
              onPressed: _clearRoute,
              isActive: false,
              heroTag: "clear_route",
            ),
          if (_showRoute) const SizedBox(height: 8),
          // My location button
          _buildFloatingButton(
            icon: Icons.my_location,
            onPressed: _getCurrentLocation,
            isActive: false,
            heroTag: "location",
          ),
          const SizedBox(height: 8),
          // Online users toggle button
          _buildFloatingButton(
            icon: _showOnlineUsersPanel ? Icons.people : Icons.people_outline,
            onPressed: _toggleOnlineUsers,
            isActive: _showOnlineUsersPanel,
            heroTag: "online_users",
          ),
        ],
      ),
    );
  }

  /// Build Next Collection card
  Widget _buildNextCollectionCard() {
    // Get the latest approved collection request
    final latestRequest = _getLatestApprovedRequest();

    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next Collection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Address with proper text wrapping
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          latestRequest['location'] ?? 'Barangay Isla',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Date and time in a more compact format
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '12',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          latestRequest['date'] ?? 'April 25, 6AM - 8AM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      // Navigate to full schedule
                    },
                    child: Text(
                      'View Full Schedule',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Glowing truck icon
            GestureDetector(
              onTap: () => _navigateToRequesterLocation(latestRequest),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade400.withOpacity(
                            0.3 + (0.4 * value),
                          ),
                          blurRadius: 8 + (8 * value),
                          spreadRadius: 2 + (2 * value),
                        ),
                        BoxShadow(
                          color: Colors.green.shade300.withOpacity(
                            0.2 + (0.3 * value),
                          ),
                          blurRadius: 16 + (16 * value),
                          spreadRadius: 4 + (4 * value),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  );
                },
                onEnd: () {
                  // Restart animation
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Selected Collection Request Card (like ZUS Coffee branch selection)
  Widget _buildSelectedCollectionRequestCard() {
    if (_selectedCollectionRequest == null) return const SizedBox.shrink();

    final collection = _selectedCollectionRequest!;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              children: [
                // Waste type icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getWasteTypeColor(
                      collection.wasteType.toString().split('.').last,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getWasteTypeIcon(
                      collection.wasteType.toString().split('.').last,
                    ),
                    color: _getWasteTypeColor(
                      collection.wasteType.toString().split('.').last,
                    ),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCollectionStatusColor(
                            collection.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          collection.status
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: TextStyle(
                            color: _getCollectionStatusColor(collection.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: _clearSelectedCollectionRequest,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Details
            _buildDetailRow(
              Icons.person,
              'User ID',
              collection.userId,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.location_on,
              'Location',
              _formatAddressForDisplay(collection.address),
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.category,
              'Waste Type',
              collection.wasteTypeText,
              _getWasteTypeColor(
                collection.wasteType.toString().split('.').last,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.access_time,
              'Created',
              _formatDate(collection.createdAt),
              Colors.orange,
            ),
            if (collection.latitude != null &&
                collection.longitude != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.navigation,
                'Distance',
                _getCollectionDistanceText(collection),
                Colors.purple,
              ),
            ],
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                // Navigate button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (collection.latitude != null &&
                          collection.longitude != null) {
                        final coordinates = LatLng(
                          collection.latitude!,
                          collection.longitude!,
                        );
                        _generateRoute(coordinates);
                        _mapController?.move(coordinates, 15.0);
                      }
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Directions button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMapsWithDirections(collection),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  /// Build detail row for the collection request card
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build zoom controls and announcement card side by side
  Widget _buildZoomControls() {
    return Positioned(
      left: 16,
      bottom: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Zoom Controls Column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom In Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _zoomIn,
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Zoom Out Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _zoomOut,
                    child: const Center(
                      child: Icon(Icons.remove, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Announcement Card (compact version)
          if (_showAnnouncementCard && _currentAnnouncement != null)
            _buildCompactAnnouncementCard(),
          // Announcement Toggle Button (when manually dismissed)
          if (_announcementManuallyDismissed &&
              _currentAnnouncement != null) ...[
            const SizedBox(width: 8),
            _buildAnnouncementToggleButton(),
          ],
        ],
      ),
    );
  }

  /// Build compact announcement card
  Widget _buildCompactAnnouncementCard() {
    if (_currentAnnouncement == null) return const SizedBox.shrink();

    final announcement = _currentAnnouncement!;
    final message = announcement['message'] ?? 'No message';
    final createdBy = announcement['createdBy'] ?? 'Administrator';

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Row(
            children: [
              Icon(Icons.campaign, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Announcement',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              // Close button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAnnouncementCard = false;
                    _announcementManuallyDismissed = true;
                  });
                },
                child: Icon(Icons.close, color: Colors.grey.shade600, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Message (truncated)
          Text(
            message.length > 50 ? '${message.substring(0, 47)}...' : message,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          // Creator
          Text(
            'From: $createdBy',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// Build announcement toggle button
  Widget _buildAnnouncementToggleButton() {
    if (!_announcementManuallyDismissed || _currentAnnouncement == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _showAnnouncementCard = true;
              _announcementManuallyDismissed = false;
            });
          },
          child: Center(
            child: Icon(Icons.campaign, color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

  /// Zoom in the map
  void _zoomIn() {
    if (_mapController != null) {
      final currentZoom = _mapController!.camera.zoom;
      final newZoom = (currentZoom + 1).clamp(3.0, 19.0);
      _mapController!.move(_mapController!.camera.center, newZoom);
    }
  }

  /// Zoom out the map
  void _zoomOut() {
    if (_mapController != null) {
      final currentZoom = _mapController!.camera.zoom;
      final newZoom = (currentZoom - 1).clamp(3.0, 19.0);
      _mapController!.move(_mapController!.camera.center, newZoom);
    }
  }

  /// Toggle online users panel display
  void _toggleOnlineUsers() {
    setState(() {
      _showOnlineUsersPanel = !_showOnlineUsersPanel;
    });

    // Note: Online users listener is always active, we just toggle panel visibility
    // The listener is started in initState() and runs continuously
  }

  /// Setup online users listener
  void _setupOnlineUsersListener() {
    _onlineUsersSubscription = LocationTrackingService.getUserLocationsStream()
        .listen(
          (onlineUsers) {
            if (mounted) {
              setState(() {
                _onlineUsers = onlineUsers;
              });
            }
          },
          onError: (error) {
            print('Error listening to online users: $error');
          },
        );
  }

  /// Setup announcement listener
  void _setupAnnouncementListener() {
    _announcementSubscription = FirebaseFirestore.instance
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              if (snapshot.docs.isNotEmpty) {
                final announcement = snapshot.docs.first.data();
                final now = DateTime.now();
                final expiresAt = (announcement['expiresAt'] as Timestamp)
                    .toDate();

                // Check if announcement is still valid
                if (now.isBefore(expiresAt)) {
                  setState(() {
                    _currentAnnouncement = announcement;
                    _showAnnouncementCard = true; // Auto-show announcement
                    _announcementManuallyDismissed =
                        false; // Reset dismissed flag for new announcement
                  });
                } else {
                  setState(() {
                    _currentAnnouncement = null;
                    _showAnnouncementCard = false;
                    _announcementManuallyDismissed =
                        false; // Reset dismissed flag when announcement expires
                  });
                }
              } else {
                setState(() {
                  _currentAnnouncement = null;
                  _showAnnouncementCard = false;
                  _announcementManuallyDismissed =
                      false; // Reset dismissed flag when no announcements
                });
              }
            }
          },
          onError: (error) {
            print('Error listening to announcements: $error');
          },
        );
  }

  /// Navigate to requester location
  void _navigateToRequesterLocation(Map<String, dynamic> request) {
    try {
      // Get the latest approved request with coordinates
      final approvedRequests = _collectionRequests
          .where((req) => req.status == CollectionStatus.approved)
          .toList();

      if (approvedRequests.isNotEmpty) {
        // Sort by date and get the latest
        approvedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = approvedRequests.first;

        // Check if the request has coordinates
        if (latest.latitude != null && latest.longitude != null) {
          final coordinates = LatLng(latest.latitude!, latest.longitude!);

          // Navigate using FlutterMap with higher zoom level for better detail
          if (mounted) {
            _mapController?.move(
              coordinates,
              18.0,
            ); // Increased zoom from 15.0 to 18.0
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigating to ${latest.address}'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // No coordinates available - try to use barangay coordinates as fallback
          final address = latest.address.toLowerCase();
          LatLng? fallbackCoords;

          // Try to find matching barangay coordinates
          String? matchedBarangay;
          for (final entry in _barangayCoordinates.entries) {
            if (address.contains(entry.key.toLowerCase())) {
              fallbackCoords = entry.value;
              matchedBarangay = entry.key;
              break;
            }
          }

          if (fallbackCoords != null && matchedBarangay != null) {
            // Navigate to barangay center with high zoom
            if (mounted) {
              _mapController?.move(fallbackCoords, 16.0);
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigating to $matchedBarangay area'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // No coordinates available
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location coordinates not available'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      } else {
        // No approved requests
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No approved collection requests found'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error navigating to requester location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error navigating to location'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Build online users overlay
  Widget _buildOnlineUsersOverlay() {
    return Positioned(
      left: 16,
      bottom: 100, // Position above the bottom navigation
      child: Container(
        width: 250,
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Online Users (${_onlineUsers.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOnlineUsersPanel = false;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Users list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(6),
                itemCount: _onlineUsers.length,
                itemBuilder: (context, index) {
                  final user = _onlineUsers[index];
                  return _buildUserCard(user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual user card
  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getUserRoleColor(user['userRole']).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getUserRoleColor(user['userRole']),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getUserRoleIcon(user['userRole']),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['userName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${user['userRole']} • ${user['barangay']}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 1),
                Text(
                  _getUserLocationText(user),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Location button
          GestureDetector(
            onTap: () => _navigateToUserLocation(user),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get user location text for display
  String _getUserLocationText(Map<String, dynamic> user) {
    // First try to get the user's address from their profile
    final userAddress = user['address'] as String?;
    if (userAddress != null && userAddress.isNotEmpty) {
      return '📍 $userAddress';
    }

    // If no address, try to get barangay
    final barangay = user['barangay'] as String?;
    if (barangay != null && barangay.isNotEmpty) {
      return '📍 $barangay';
    }

    // Fallback to coordinates if no address available
    final location = user['location'] as Map<String, dynamic>?;
    if (location != null) {
      final latitude = location['latitude'] as double?;
      final longitude = location['longitude'] as double?;

      if (latitude != null && longitude != null) {
        final latRounded = latitude.toStringAsFixed(4);
        final lngRounded = longitude.toStringAsFixed(4);
        return '📍 $latRounded, $lngRounded';
      }
    }

    return '📍 Location unavailable';
  }

  /// Navigate to user location
  Future<void> _navigateToUserLocation(Map<String, dynamic> user) async {
    try {
      final location = user['location'] as Map<String, dynamic>?;
      final latitude = location?['latitude'] as double?;
      final longitude = location?['longitude'] as double?;

      if (latitude != null && longitude != null) {
        final coordinates = LatLng(latitude, longitude);

        // Show loading message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Generating route to ${user['userName']}...'),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Generate route to user location
        await _generateRoute(coordinates);

        // Navigate using FlutterMap
        if (mounted) {
          _mapController?.move(coordinates, 15.0);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Route generated to ${user['userName']}\'s location',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Clear Route',
                textColor: Colors.white,
                onPressed: _clearRoute,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User location not available'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error navigating to user location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error navigating to location'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Get color for user role
  Color _getUserRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'resident':
        return Colors.blue;
      case 'driver':
        return Colors.green;
      case 'barangay official':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Format time ago
  String _formatTimeAgo(dynamic dateTimeOrTimestamp) {
    DateTime dateTime;

    // Handle both DateTime and Timestamp objects
    if (dateTimeOrTimestamp is Timestamp) {
      dateTime = dateTimeOrTimestamp.toDate();
    } else if (dateTimeOrTimestamp is DateTime) {
      dateTime = dateTimeOrTimestamp;
    } else {
      return 'unknown';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Get latest approved collection request
  Map<String, dynamic> _getLatestApprovedRequest() {
    print('Total collection requests: ${_collectionRequests.length}');

    // Find the latest approved request first
    final approvedRequests = _collectionRequests
        .where((request) => request.status == CollectionStatus.approved)
        .toList();

    print('Approved collection requests: ${approvedRequests.length}');

    if (approvedRequests.isNotEmpty) {
      // Sort by date and get the latest
      approvedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latest = approvedRequests.first;

      // Format the address properly
      print('Original address from collection request: "${latest.address}"');
      print('Address length: ${latest.address.length}');
      print('Address is empty: ${latest.address.isEmpty}');
      String displayAddress = _formatAddressForDisplay(latest.address);
      print('Formatted address: "$displayAddress"');

      return {
        'location': displayAddress,
        'date': _formatCollectionDate(latest.scheduledDate),
        'wasteType': latest.wasteType.toString().split('.').last,
      };
    }

    // If no approved requests, try to get the latest request regardless of status
    if (_collectionRequests.isNotEmpty) {
      print('No approved requests, using latest request regardless of status');
      _collectionRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latest = _collectionRequests.first;

      print('Latest request status: ${latest.status}');
      print('Original address from latest request: "${latest.address}"');
      print('Address length: ${latest.address.length}');
      print('Address is empty: ${latest.address.isEmpty}');
      String displayAddress = _formatAddressForDisplay(latest.address);
      print('Formatted address: "$displayAddress"');

      return {
        'location': displayAddress,
        'date': _formatCollectionDate(latest.scheduledDate),
        'wasteType': latest.wasteType.toString().split('.').last,
      };
    }

    // Default values if no collection requests at all
    print('No collection requests found, using default address');
    return {
      'location': _getRandomStreetAddress(),
      'date': 'April 25, 6AM - 8AM',
      'wasteType': 'General',
    };
  }

  /// Format address for display in the Next Collection card
  String _formatAddressForDisplay(String address) {
    print('=== ADDRESS FORMATTING DEBUG ===');
    print('Input address: "$address"');
    print('Address length: ${address.length}');
    print('Address is empty: ${address.isEmpty}');
    print('Address trimmed: "${address.trim()}"');

    // If address is empty, use a default street address
    if (address.isEmpty) {
      print('❌ Address is empty, using random address');
      return _getRandomStreetAddress();
    }

    // Check if address contains coordinates (numbers with decimal points)
    final coordinatePattern = RegExp(r'^\d+\.\d+,\s*\d+\.\d+$');
    if (coordinatePattern.hasMatch(address.trim())) {
      print('❌ Address contains coordinates, using random address');
      return _getRandomStreetAddress();
    }

    // Check for very generic addresses - be more specific
    final trimmedAddress = address.toLowerCase().trim();
    if (trimmedAddress == 'valenzuela city' || trimmedAddress == 'valenzuela') {
      print('❌ Address is just city name, using random address');
      return _getRandomStreetAddress();
    }

    // TEMPORARY: Disable street content check to see actual addresses
    // Check if address has actual street content (contains numbers or street words)
    final hasStreetContent =
        address.contains(RegExp(r'\d+')) ||
        address.toLowerCase().contains('street') ||
        address.toLowerCase().contains('road') ||
        address.toLowerCase().contains('avenue') ||
        address.toLowerCase().contains('highway') ||
        address.toLowerCase().contains('barangay');

    print('Has street content: $hasStreetContent');

    // TEMPORARY: Comment out this check to see what actual addresses look like
    // if (!hasStreetContent) {
    //   print('❌ Address has no street content, using random address');
    //   return _getRandomStreetAddress();
    // }

    // If address is too long, truncate it more aggressively for compact display
    if (address.length > 40) {
      print('⚠️ Address too long, truncating');
      return '${address.substring(0, 37)}...';
    }

    // If address doesn't contain city info, add Valenzuela City
    if (!address.toLowerCase().contains('valenzuela') &&
        !address.toLowerCase().contains('city')) {
      print('✅ Adding Valenzuela City to address');
      return '$address, Valenzuela City';
    }

    print('✅ Using original address: "$address"');
    return address;
  }

  /// Generate a random street address for Valenzuela City
  String _getRandomStreetAddress() {
    final streetNames = [
      'Maysan Road',
      'Karuhatan Road',
      'MacArthur Highway',
      'T. Santiago Street',
      'F. Alarcon Street',
      'E. Alarcon Street',
      'Derupa Street',
      'G. Marcelo Street',
      'O. Miranda Street',
      'Tongco Street',
      'Sta. Monica II',
      'C-5 Road',
      'AH26 Highway',
      'Maysan Road Extension',
      'Karuhatan Road Extension',
    ];

    final barangays = [
      'Barangay Maysan',
      'Barangay Karuhatan',
      'Barangay Malinta',
      'Barangay Dalandanan',
      'Barangay Marulas',
      'Barangay Punturin',
      'Barangay Ugong',
      'Barangay Viente Reales',
      'Barangay Tagalag',
      'Barangay Isla',
    ];

    // Use a more consistent seed based on current date (changes daily, not every second)
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final streetIndex = dayOfYear % streetNames.length;
    final barangayIndex =
        (dayOfYear + 7) % barangays.length; // Offset to get different barangay
    final houseNumber = (100 + (dayOfYear % 800)).toString();

    final streetName = streetNames[streetIndex];
    final barangay = barangays[barangayIndex];

    print('🎲 Generated random address: $houseNumber $streetName, $barangay');
    return '$houseNumber $streetName, $barangay';
  }

  /// Format collection date
  String _formatCollectionDate(DateTime? date) {
    if (date == null) return 'April 25, 6AM - 8AM';

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final month = months[date.month - 1];
    final day = date.day;
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month $day, ${hour}:$minute AM - ${hour + 2}:$minute AM';
  }

  /// Build individual floating button
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
    required String heroTag,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: isActive ? AppColors.primary : Colors.white,
      heroTag: heroTag,
      mini: true,
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  String _getTileUrl() {
    if (_isSatelliteView) {
      if (_showTraffic) {
        // Google Maps satellite with traffic layer
        return 'https://mt1.google.com/vt/lyrs=y,traffic&x={x}&y={y}&z={z}';
      } else {
        // Google Maps satellite view
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      }
    } else if (_showTraffic) {
      // Google Maps with traffic layer
      return 'https://mt1.google.com/vt/lyrs=m,traffic&x={x}&y={y}&z={z}';
    } else {
      // Default to Google Maps
      return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  /// Generate route between current location and destination using Google Directions API
  Future<void> _generateRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    try {
      // Show loading state
      setState(() {
        _showRoute = false;
      });

      // Get route from Google Directions API
      final routePoints = await _getGoogleDirectionsRoute(
        _currentLocation!,
        destination,
      );

      if (routePoints.isNotEmpty) {
        _routePoints = routePoints;
        setState(() {
          _showRoute = true;
        });
      } else {
        // Fallback to realistic route if API fails
        _routePoints = _createRealisticRoute(_currentLocation!, destination);
        setState(() {
          _showRoute = true;
        });
      }
    } catch (e) {
      print('Error generating route: $e');
      // Fallback to realistic route
      _routePoints = _createRealisticRoute(_currentLocation!, destination);
      setState(() {
        _showRoute = true;
      });
    }
  }

  /// Get route from OpenRouteService (free alternative to Google Directions)
  Future<List<LatLng>> _getGoogleDirectionsRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // Using OpenRouteService as a free alternative
      // You can get a free API key from https://openrouteservice.org/
      const String apiKey =
          'YOUR_OPENROUTESERVICE_API_KEY'; // Replace with actual API key

      // If API key is not set, use realistic route generation
      if (apiKey == 'YOUR_OPENROUTESERVICE_API_KEY') {
        print(
          'OpenRouteService API key not configured. Using realistic route generation.',
        );
        return _createRealisticRoute(origin, destination);
      }

      final String url =
          'https://api.openrouteservice.org/v2/directions/driving-car?'
          'api_key=$apiKey&'
          'start=${origin.longitude},${origin.latitude}&'
          'end=${destination.longitude},${destination.latitude}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['geometry']['coordinates'];

          // Convert coordinates to LatLng points
          List<LatLng> points = [];
          for (var coord in coordinates) {
            points.add(
              LatLng(coord[1], coord[0]),
            ); // Note: OpenRouteService uses [lng, lat]
          }
          return points;
        }
      }

      // If API fails, create a more realistic route using waypoints
      return _createRealisticRoute(origin, destination);
    } catch (e) {
      print('Error calling routing API: $e');
      return _createRealisticRoute(origin, destination);
    }
  }

  /// Create a more realistic route with waypoints (fallback)
  List<LatLng> _createRealisticRoute(LatLng origin, LatLng destination) {
    List<LatLng> points = [];

    // Calculate distance and bearing
    double distance = _calculateDistance(origin, destination);

    if (distance < 0.1) {
      // Less than 100m, use straight line
      return [origin, destination];
    }

    // For Valenzuela City area, create a route that follows major roads
    // This is a simplified version that creates waypoints following common road patterns

    // Calculate bearing (direction) from origin to destination
    double bearing = _calculateBearing(origin, destination);

    // Create intermediate waypoints that follow road-like patterns
    int numWaypoints = (distance * 15).round().clamp(
      3,
      20,
    ); // More waypoints for realism

    for (int i = 0; i <= numWaypoints; i++) {
      double ratio = i / numWaypoints;

      // Create waypoints that follow a more realistic road pattern
      double lat =
          origin.latitude + (destination.latitude - origin.latitude) * ratio;
      double lng =
          origin.longitude + (destination.longitude - origin.longitude) * ratio;

      // Add road-like curves and adjustments based on distance
      if (distance > 1.0) {
        // For longer distances, add more realistic curves
        // Add slight curves to simulate following roads
        double curveIntensity =
            0.0002 * (1 - ratio) * (1 - ratio); // Stronger curves at start

        // Add perpendicular offset to simulate road turns
        double perpendicularOffset =
            curveIntensity * sin(ratio * pi * 3) * cos(bearing);

        // Add parallel offset to simulate road curves
        double parallelOffset =
            curveIntensity * cos(ratio * pi * 2) * sin(bearing);

        lat += perpendicularOffset;
        lng += parallelOffset;
      }

      // Add some random variation to make it look more natural
      if (i > 0 && i < numWaypoints) {
        double variation = 0.00005 * sin(ratio * pi * 4);
        lat += variation * cos(bearing + pi / 2);
        lng += variation * sin(bearing + pi / 2);
      }

      points.add(LatLng(lat, lng));
    }

    return points;
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng point1, LatLng point2) {
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    double y = sin(deltaLng) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);

    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360; // Convert to degrees and normalize
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1Rad = point1.latitude * pi / 180;
    double lat2Rad = point2.latitude * pi / 180;
    double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Clear the current route
  void _clearRoute() {
    setState(() {
      _showRoute = false;
      _routePoints.clear();
    });
  }

  /// Select collection request and show bottom card
  void _selectCollectionRequest(WasteCollection collection) {
    setState(() {
      _selectedCollectionRequest = collection;
    });

    // Center map on the selected collection request
    if (collection.latitude != null && collection.longitude != null) {
      final coordinates = LatLng(collection.latitude!, collection.longitude!);
      _mapController?.move(coordinates, 15.0);
    }
  }

  /// Clear selected collection request
  void _clearSelectedCollectionRequest() {
    setState(() {
      _selectedCollectionRequest = null;
    });
  }

  /// Start location tracking for the current user
  Future<void> _startLocationTracking() async {
    try {
      await LocationTrackingService.startLocationTracking();
      print('Location tracking started');
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  /// Setup listener for real-time collection requests
  void _setupCollectionRequestsListener() {
    _collectionRequestsSubscription =
        FirebaseCollectionService.getCollectionRequestsStream().listen(
          (collectionRequests) {
            print(
              'Collection requests updated: ${collectionRequests.length} requests',
            );
            if (collectionRequests.isNotEmpty) {
              print('=== COLLECTION REQUESTS DEBUG ===');
              print('Total requests loaded: ${collectionRequests.length}');
              for (int i = 0; i < collectionRequests.length && i < 3; i++) {
                final request = collectionRequests[i];
                print('Request $i:');
                print('  - ID: ${request.id}');
                print('  - Address: "${request.address}"');
                print('  - Status: ${request.status}');
                print('  - User ID: ${request.userId}');
                print('  - Created: ${request.createdAt}');
              }
            }
            if (mounted) {
              setState(() {
                _collectionRequests = collectionRequests;
              });
            }
          },
          onError: (error) {
            print('Error listening to collection requests: $error');
          },
        );
  }

  /// Get collection request markers for the map
  List<Marker> _getCollectionRequestMarkers() {
    if (!_showCollectionRequests) return [];

    return _collectionRequests
        .map((collection) {
          // Use actual coordinates from collection request if available
          LatLng coords;
          if (collection.latitude != null && collection.longitude != null) {
            coords = LatLng(collection.latitude!, collection.longitude!);
          } else {
            // Fallback to Valenzuela City coordinates if no specific location
            final barangayCoords = _barangayCoordinates['Valenzuela City'];
            if (barangayCoords == null) return null;
            coords = barangayCoords;
          }

          final isSelected = _selectedCollectionRequest?.id == collection.id;
          final wasteTypeColor = _getWasteTypeColor(
            collection.wasteType.toString().split('.').last,
          );

          return Marker(
            point: coords,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _selectCollectionRequest(collection),
              child: isSelected
                  ? TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: wasteTypeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: wasteTypeColor.withOpacity(
                                  0.4 + (0.3 * value),
                                ),
                                blurRadius: 10 + (10 * value),
                                spreadRadius: 2 + (3 * value),
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: wasteTypeColor.withOpacity(
                                  0.2 + (0.4 * value),
                                ),
                                blurRadius: 20 + (20 * value),
                                spreadRadius: 4 + (6 * value),
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getWasteTypeIcon(
                              collection.wasteType.toString().split('.').last,
                            ),
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                      onEnd: () {
                        // Restart animation
                        setState(() {});
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: wasteTypeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: wasteTypeColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getWasteTypeIcon(
                          collection.wasteType.toString().split('.').last,
                        ),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
            ),
          );
        })
        .where((marker) => marker != null)
        .cast<Marker>()
        .toList();
  }

  /// Get online user markers for the map
  List<Marker> _getOnlineUserMarkers() {
    if (!_showOnlineUsers || _onlineUsers.isEmpty) return [];

    return _onlineUsers
        .where((user) {
          // Only show users with valid location data
          final location = user['location'] as Map<String, dynamic>?;
          return location != null &&
              location['latitude'] != null &&
              location['longitude'] != null;
        })
        .map((user) {
          final location = user['location'] as Map<String, dynamic>;
          final coords = LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          );

          return Marker(
            point: coords,
            width: 120,
            height: 120,
            child: GestureDetector(
              onTap: () => _showUserInfoDialog(user),
              child: _buildGlowingUserMarker(user),
            ),
          );
        })
        .toList();
  }

  /// Build glowing user marker with animation and chat bubble name label
  Widget _buildGlowingUserMarker(Map<String, dynamic> user) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chat bubble name label
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      user['userName'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Chat bubble tail pointing down
                  Positioned(
                    bottom: -4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        transform: Matrix4.rotationZ(0.785), // 45 degrees
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Glowing marker
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Outer glow
                  BoxShadow(
                    color: _getUserRoleColor(
                      user['userRole'],
                    ).withOpacity(value * 0.6),
                    blurRadius: 15 + (value * 10),
                    spreadRadius: 2 + (value * 3),
                  ),
                  // Inner glow
                  BoxShadow(
                    color: _getUserRoleColor(
                      user['userRole'],
                    ).withOpacity(value * 0.8),
                    blurRadius: 8 + (value * 5),
                    spreadRadius: 1 + (value * 2),
                  ),
                  // White border shadow
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 3,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _getUserRoleColor(user['userRole']),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  _getUserRoleIcon(user['userRole']),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  /// Get color for waste type
  Color _getWasteTypeColor(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'general':
        return Colors.grey;
      case 'recyclable':
        return Colors.blue;
      case 'organic':
        return Colors.green;
      case 'hazardous':
        return Colors.red;
      case 'electronic':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get collection status color
  Color _getCollectionStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return Colors.orange;
      case CollectionStatus.approved:
        return Colors.blue;
      case CollectionStatus.scheduled:
        return Colors.purple;
      case CollectionStatus.inProgress:
        return Colors.amber;
      case CollectionStatus.completed:
        return Colors.green;
      case CollectionStatus.cancelled:
        return Colors.red;
    }
  }

  /// Get icon for waste type
  IconData _getWasteTypeIcon(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'general':
        return Icons.delete_outline;
      case 'recyclable':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'hazardous':
        return Icons.warning;
      case 'electronic':
        return Icons.devices;
      default:
        return Icons.delete_outline;
    }
  }

  void _showUserInfoDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getUserRoleColor(user['userRole']),
                      _getUserRoleColor(user['userRole']).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getUserRoleIcon(user['userRole']),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['userName'] ?? 'Unknown User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user['userRole'] ?? 'Unknown Role',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getUserRoleColor(user['userRole']).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    _buildCompactInfoRow(
                      Icons.location_on,
                      'Barangay',
                      user['barangay'] ?? 'Unknown',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildCompactInfoRow(
                      Icons.access_time,
                      'Last Seen',
                      _formatTimeAgo(user['lastSeen']),
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildCompactInfoRow(
                      Icons.email,
                      'Email',
                      user['userEmail'] ?? 'Unknown',
                      Colors.purple,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getUserRoleColor(user['userRole']),
                            _getUserRoleColor(
                              user['userRole'],
                            ).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getUserRoleColor(
                              user['userRole'],
                            ).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToUserLocation(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Navigate',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get distance text for collection request
  String _getCollectionDistanceText(WasteCollection collection) {
    if (_currentLocation == null ||
        collection.latitude == null ||
        collection.longitude == null) {
      return 'Distance unknown';
    }

    final distance = _calculateDistance(
      _currentLocation!,
      LatLng(collection.latitude!, collection.longitude!),
    );

    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Open Google Maps with directions to collection location
  Future<void> _openGoogleMapsWithDirections(WasteCollection collection) async {
    try {
      // Get current location
      final currentLocation =
          await LocationTrackingService.getCurrentLocation();
      if (currentLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location for directions'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get destination coordinates from collection request
      LatLng destinationCoords;
      if (collection.latitude != null && collection.longitude != null) {
        destinationCoords = LatLng(collection.latitude!, collection.longitude!);
      } else {
        // Fallback to Valenzuela City center if no specific coordinates
        final barangayCoords = _barangayCoordinates['Valenzuela City'];
        if (barangayCoords == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to get destination coordinates'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        destinationCoords = barangayCoords;
      }

      // Create Google Maps URL with directions
      final origin = '${currentLocation.latitude},${currentLocation.longitude}';
      final destination =
          '${destinationCoords.latitude},${destinationCoords.longitude}';
      final googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';

      // Launch Google Maps in external app
      if (mounted) {
        try {
          await launchUrl(
            Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open Google Maps. Please install the app.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show modal with all collection requests (drivers only)
  void _showAllCollectionRequestsModal() {
    // Check if user is a driver
    final currentUser = FirebaseAuthService.currentUser;
    if (currentUser?.role != UserRole.driver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only drivers can access collection requests'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AllCollectionRequestsModal(
          onLocationTap: (WasteCollection collection) {
            // Navigate to the location on the map
            if (collection.latitude != null && collection.longitude != null) {
              final location = LatLng(
                collection.latitude!,
                collection.longitude!,
              );
              _mapController?.move(location, 16.0);
              Navigator.of(context).pop(); // Close modal

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

  @override
  void dispose() {
    try {
      _mapController?.dispose();
      _mapController = null;
      _collectionRequestsSubscription?.cancel();
      _onlineUsersSubscription?.cancel(); // Cancel online users subscription
      _announcementSubscription?.cancel(); // Cancel announcement subscription
      LocationTrackingService.stopLocationTracking();

      // Set user as offline when app closes
      _setUserOffline();
    } catch (e) {
      print('Error disposing map controller: $e');
    }
    super.dispose();
  }

  /// Set current user as offline
  Future<void> _setUserOffline() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        await LocationTrackingService.setUserOffline(currentUser.id);
      }
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }
}

/// Modal to display all collection requests with location navigation
class AllCollectionRequestsModal extends StatefulWidget {
  final Function(WasteCollection) onLocationTap;

  const AllCollectionRequestsModal({super.key, required this.onLocationTap});

  @override
  State<AllCollectionRequestsModal> createState() =>
      _AllCollectionRequestsModalState();
}

class _AllCollectionRequestsModalState
    extends State<AllCollectionRequestsModal> {
  List<WasteCollection> _collectionRequests = [];
  bool _isLoading = true;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCollectionRequests();
  }

  Future<void> _loadCollectionRequests() async {
    try {
      // Get current location first
      final currentLocation =
          await LocationTrackingService.getCurrentLocation();

      // Fetch all collection requests from Firebase
      final requests =
          await FirebaseCollectionService.getAllCollectionRequests();
      if (mounted) {
        setState(() {
          _currentLocation = currentLocation != null
              ? LatLng(currentLocation.latitude, currentLocation.longitude)
              : null;
          _collectionRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading collection requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
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
                      Icons.local_shipping,
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
                                '${_collectionRequests.length} requests',
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
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading collection requests...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _collectionRequests.isEmpty
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
                            'Requests will appear here when created',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _collectionRequests.length,
                      itemBuilder: (context, index) {
                        final request = _collectionRequests[index];
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

  String _getStatusDisplayName(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return 'Pending';
      case CollectionStatus.approved:
        return 'Approved';
      case CollectionStatus.scheduled:
        return 'Scheduled';
      case CollectionStatus.inProgress:
        return 'In Progress';
      case CollectionStatus.completed:
        return 'Completed';
      case CollectionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return Colors.orange;
      case CollectionStatus.approved:
        return Colors.blue;
      case CollectionStatus.scheduled:
        return Colors.purple;
      case CollectionStatus.inProgress:
        return Colors.amber;
      case CollectionStatus.completed:
        return Colors.green;
      case CollectionStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
