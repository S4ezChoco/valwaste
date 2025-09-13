import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/constants.dart';
import '../../services/firebase_collection_service.dart';
import '../../models/waste_collection.dart';
import '../collection/collection_request_screen.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  
  const MapScreen({super.key, this.schedule});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  List<Marker> _wasteCollectionPoints = [];
  String _selectedBarangay = 'Valenzuela City';
  LatLng? _selectedBarangayLocation;
  bool _isLocationPickerExpanded = false;
  bool _isSatelliteView = false;
  bool _is3DView = false;
  final List<String> _barangays = [
    'Valenzuela City',
    'Barangay Isla',
    'Barangay Malanday',
    'Barangay Marulas',
    'Barangay Karuhatan',
    'Barangay Dalandanan',
    'Barangay Gen. T. de Leon',
    'Barangay Mapulang Lupa',
    'Barangay Parada',
    'Barangay Poblacion',
    'Barangay Rincon',
    'Barangay Tagalag',
    'Barangay Ugong',
    'Barangay Viente Reales',
  ];

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
    _mapController = MapController();
    _initializeMap();
    if (widget.schedule != null) {
      _loadScheduleRoute();
    }
  }

  Future<void> _initializeMap() async {
    try {
      await _requestLocationPermission();
      await _getCurrentLocation();
      _loadWasteCollectionPoints();
    } catch (e) {
      print('Error initializing map: $e');
      // Set default location if initialization fails
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(14.7000, 120.9833); // Valenzuela City default
        });
      }
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Return default position if timeout
          return Position(
            latitude: 14.7000,
            longitude: 120.9833,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        },
      );

      if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        // Clear selected barangay marker when going to current location
        _selectedBarangayLocation = null;
      });

      // Center map on current location
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 15.0);
        }
      }
    } catch (e) {
      print('Error getting location: $e');
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

  void _loadScheduleRoute() {
    if (widget.schedule == null) return;
    
    final streets = widget.schedule!['streets'] as List<dynamic>? ?? [];
    final latitude = widget.schedule!['latitude'];
    final longitude = widget.schedule!['longitude'];
    
    // If we have coordinates from the schedule, center the map there
    if (latitude != null && longitude != null) {
      final centerPoint = LatLng(latitude.toDouble(), longitude.toDouble());
      _mapController.move(centerPoint, 14.0);
      
      // Add a marker for the schedule location
      setState(() {
        _wasteCollectionPoints.add(
          Marker(
            point: centerPoint,
            width: 60,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 24),
            ),
          ),
        );
      });
    }
    
    // Add markers for each street in the route
    for (int i = 0; i < streets.length && i < 5; i++) {
      // Limit to first 5 streets for performance
      final street = streets[i];
      // Try to find coordinates for the street (simplified - in real app would use geocoding)
      LatLng? streetCoord;
      
      // Check if street name contains a known barangay
      for (final entry in _barangayCoordinates.entries) {
        if (street.toString().toLowerCase().contains(entry.key.toLowerCase().replaceAll('barangay ', ''))) {
          streetCoord = entry.value;
          break;
        }
      }
      
      if (streetCoord != null) {
        setState(() {
          _wasteCollectionPoints.add(
            Marker(
              point: streetCoord!,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 6,
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
          );
        });
      }
    }
  }

  void _loadWasteCollectionPoints() {
    // Sample waste collection points in Valenzuela City - in a real app, these would come from an API
    _wasteCollectionPoints = [
      Marker(
        point: LatLng(14.7000, 120.9833), // Valenzuela City Hall
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showCollectionPointInfo(
            'Valenzuela City Hall Collection Center',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.delete, color: Colors.white, size: 24),
          ),
        ),
      ),
      Marker(
        point: LatLng(14.7100, 120.9900), // Malanday Collection Center
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showCollectionPointInfo('Malanday Collection Center'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.recycling, color: Colors.white, size: 24),
          ),
        ),
      ),
      Marker(
        point: LatLng(14.6900, 120.9750), // Marulas Waste Facility
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () =>
              _showCollectionPointInfo('Marulas Waste Management Facility'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
          ),
        ),
      ),
      Marker(
        point: LatLng(14.7050, 120.9700), // Karuhatan Collection Point
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showCollectionPointInfo('Karuhatan Collection Point'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.delete, color: Colors.white, size: 24),
          ),
        ),
      ),
      Marker(
        point: LatLng(14.7150, 120.9800), // Dalandanan Collection Center
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showCollectionPointInfo('Dalandanan Collection Center'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.recycling, color: Colors.white, size: 24),
          ),
        ),
      ),
    ];
  }

  void _showCollectionPointInfo(String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Compact header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Compact info section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildCompactInfoRow(
                      Icons.access_time,
                      'Operating Hours',
                      '8:00 AM - 6:00 PM',
                      Colors.blue,
                    ),
            const SizedBox(height: 8),
                    _buildCompactInfoRow(
                      Icons.recycling,
                      'Accepts',
                      'Paper, Plastic, Metal, Glass',
                      Colors.green,
                    ),
            const SizedBox(height: 8),
                    _buildCompactInfoRow(
                      Icons.circle,
                      'Status',
                      'Open',
                      Colors.green,
                      isStatus: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Compact buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestCollection(title);
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Request Collection',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isStatus) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      subtitle,
                      style: AppTextStyles.body1.copyWith(
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
      ),
    );
  }

  void _requestCollection(String location) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Request Collection',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Compact content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Request collection from $location?',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Compact buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
              Navigator.pop(context);

                        // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                            content: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Creating collection request...',
                                    style: AppTextStyles.body2,
                                  ),
                                ),
                              ],
                            ),
                  backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        try {
                          // Create collection request in Firebase
                          final result =
                              await FirebaseCollectionService.createCollectionRequest(
                                wasteType: WasteType.general, // Default type
                                quantity: 5.0, // Default quantity
                                unit: 'kg',
                                description:
                                    'Collection request from $location via map',
                                scheduledDate: DateTime.now().add(
                                  const Duration(days: 1),
                                ),
                                address: location,
                                notes: 'Requested from map location: $location',
                              );

                          if (result['success']) {
                            // Show success message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Collection request created successfully!',
                                          style: AppTextStyles.body2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }

                            // Navigate to collection request screen for more details
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CollectionRequestScreen(),
                                ),
                              );
                            }
                          } else {
                            // Show error message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          result['message'] ??
                                              'Failed to create collection request',
                                          style: AppTextStyles.body2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Show error message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error: $e',
                                        style: AppTextStyles.body2,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Confirm',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  void _navigateToBarangay(String barangay) {
    try {
    final coordinates = _barangayCoordinates[barangay];
    if (coordinates != null) {
      // Set the selected barangay location
      setState(() {
        _selectedBarangayLocation = coordinates;
      });

      // Animate to the selected barangay location
      _mapController.move(coordinates, 15.0);

      // Show success message
        if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigated to $barangay'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
        }
    } else {
      // Show error if coordinates not found
        if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this barangay'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
        }
      }
    } catch (e) {
      print('Error navigating to barangay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to $barangay: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
      appBar: AppBar(
        title: const Text('Waste Collection Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Location Picker
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header - Always Visible
                InkWell(
                  onTap: () {
                    setState(() {
                      _isLocationPickerExpanded = !_isLocationPickerExpanded;
                    });
                  },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
            ),
            child: Row(
              children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                  color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
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
                                'Select Location',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _selectedBarangay,
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _getCurrentLocation,
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          tooltip: 'Use current location',
                        ),
                        Icon(
                          _isLocationPickerExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                // Collapsible Content with Animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isLocationPickerExpanded ? null : 0,
                  child: _isLocationPickerExpanded
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Dropdown Section
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBarangay,
                      isExpanded: true,
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                                        size: 20,
                                      ),
                      ),
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _barangays.map((String barangay) {
                                      final isSelected =
                                          barangay == _selectedBarangay;
                        return DropdownMenuItem<String>(
                          value: barangay,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? Icons.location_on
                                                  : Icons.location_on_outlined,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                barangay,
                                                style: AppTextStyles.body1
                                                    .copyWith(
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : AppColors
                                                                .textPrimary,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedBarangay = newValue;
                          });
                          // Navigate to the selected barangay
                          _navigateToBarangay(newValue);
                        }
                      },
                    ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Quick Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      icon: Icons.near_me,
                                      label: 'Near Me',
                                      color: Colors.blue,
                                      onTap: _getCurrentLocation,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      icon: Icons.search,
                                      label: 'Search',
                                      color: Colors.green,
                                      onTap: () {
                                        _showSearchLocationDialog();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      icon: Icons.favorite,
                                      label: 'Favorites',
                                      color: Colors.red,
                                      onTap: () {
                                        _showFavoritesDialog();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : null,
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
                onTap: (_, __) {
                  // Handle map tap if needed
                },
                onMapReady: () {
                  // Map is ready, ensure controller is properly initialized
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15.0);
                  }
                  // Apply 3D view if enabled
                  if (_is3DView) {
                    _apply3DView();
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
                            color: Colors.blue.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
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
                            color: Colors.orange.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              // Toggle 3D view
              setState(() {
                _is3DView = !_is3DView;
              });

              // Apply 3D view if enabled
              if (_is3DView) {
                _apply3DView();
              } else {
                // Return to normal view
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 15.0);
                }

                // Show normal view message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Normal View - Standard map view',
                              style: AppTextStyles.body2,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.indigo,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            backgroundColor: _is3DView ? Colors.purple : Colors.indigo,
            heroTag: "3d_view",
            child: Icon(
              _is3DView ? Icons.view_in_ar : Icons.view_in_ar_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () {
              // Toggle satellite view
              setState(() {
                _isSatelliteView = !_isSatelliteView;
              });
            },
            backgroundColor: _isSatelliteView ? Colors.grey : Colors.blue,
            heroTag: "map_type",
            child: Icon(
              _isSatelliteView ? Icons.map : Icons.satellite,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () {
              // Navigate to collection request screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CollectionRequestScreen(),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            heroTag: "request_collection",
            child: const Icon(Icons.local_shipping, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
        onPressed: () {
          // Add new collection point or report issue
          _showAddCollectionPointDialog();
        },
            backgroundColor: Colors.orange,
            heroTag: "add_point",
        child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showAddCollectionPointDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_location,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Map Actions',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Options
              Column(
                children: [
                  _buildActionOption(
                    icon: Icons.local_shipping,
                    title: 'Request Collection',
                    subtitle: 'Create a new collection request',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionRequestScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionOption(
                    icon: Icons.add_location,
                    title: 'Report New Point',
                    subtitle: 'Suggest a new collection location',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showReportNewPointDialog();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionOption(
                    icon: Icons.report,
                    title: 'Report Issue',
                    subtitle: 'Report a problem with existing point',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showReportIssueDialog();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                    title,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showReportNewPointDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report New Collection Point'),
        content: const Text(
          'This feature will allow you to suggest new waste collection locations. Coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text(
          'This feature will allow you to report problems with existing collection points. Coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Location'),
        content: const Text(
          'This feature will allow you to search for specific locations. Coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favorite Locations'),
        content: const Text(
          'This feature will allow you to save and access your favorite locations. Coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTileUrl() {
    if (_is3DView) {
      // Use Mapbox 3D style with enhanced building visibility
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw';
    } else if (_isSatelliteView) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    } else {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _apply3DView() {
    try {
      // Apply 3D perspective by adjusting zoom and center
      if (_currentLocation != null) {
        _mapController.move(
          _currentLocation!,
          19.0,
        ); // Higher zoom for better building visibility
      }

      // Show 3D view activated message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '3D View Activated - Enhanced building visibility',
                    style: AppTextStyles.body2,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error applying 3D view: $e');
    }
  }

  @override
  void dispose() {
    try {
    _mapController.dispose();
    } catch (e) {
      print('Error disposing map controller: $e');
    }
    super.dispose();
  }
}
