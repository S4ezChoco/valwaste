import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class NativeNavigationScreen extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destination;
  final String destinationName;

  const NativeNavigationScreen({
    Key? key,
    required this.currentLocation,
    required this.destination,
    required this.destinationName,
  }) : super(key: key);

  @override
  State<NativeNavigationScreen> createState() => _NativeNavigationScreenState();
}

class _NativeNavigationScreenState extends State<NativeNavigationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _routeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _routeAnimation;

  double _distanceRemaining = 0.0;
  int _timeRemaining = 0;
  String _nextStreet = "Calculating...";
  double _nextDistance = 0.0;

  LatLng _currentPosition = LatLng(0, 0);
  StreamSubscription<Position>? _positionStream;
  MapController _mapController = MapController();
  double _mapRotation = 0.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _routeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeController, curve: Curves.easeInOut),
    );

    _routeController.forward();

    // Initialize real navigation
    _initializeNavigation();
  }

  void _initializeNavigation() async {
    // Set initial position
    _currentPosition = widget.currentLocation;

    // Calculate route
    await _calculateRoute();

    // Calculate initial map rotation
    _calculateMapRotation();

    // Start real-time location tracking
    _startLocationTracking();

    // Calculate initial distance and time
    _updateNavigationInfo();
  }

  Future<void> _calculateRoute() async {
    try {
      // Calculate distance between current and destination
      final distance = Geolocator.distanceBetween(
        widget.currentLocation.latitude,
        widget.currentLocation.longitude,
        widget.destination.latitude,
        widget.destination.longitude,
      );

      _distanceRemaining = distance / 1609.34; // Convert to miles
      _timeRemaining = (_distanceRemaining * 2)
          .round(); // Rough estimate: 2 minutes per mile

      setState(() {
        _nextStreet = widget.destinationName;
        _nextDistance = _distanceRemaining;
      });
    } catch (e) {
      print('Error calculating route: $e');
    }
  }

  void _startLocationTracking() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
            });
            _updateNavigationInfo();
          }
        });
  }

  void _updateNavigationInfo() {
    if (_currentPosition.latitude != 0 && _currentPosition.longitude != 0) {
      // Calculate distance to destination
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        widget.destination.latitude,
        widget.destination.longitude,
      );

      _distanceRemaining = distance / 1609.34; // Convert to miles
      _timeRemaining = (_distanceRemaining * 2).round(); // Rough estimate

      // Calculate bearing (direction) to destination for auto-rotation
      _calculateMapRotation();

      setState(() {
        _nextDistance = _distanceRemaining;
      });
    }
  }

  void _calculateMapRotation() {
    if (_currentPosition.latitude != 0 && _currentPosition.longitude != 0) {
      // Calculate bearing from current position to destination
      final bearing = Geolocator.bearingBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        widget.destination.latitude,
        widget.destination.longitude,
      );

      // Convert bearing to rotation (destination at top = 0 degrees)
      // Bearing is 0-360, we want destination at top (north = 0)
      _mapRotation = -bearing * (3.14159 / 180); // Convert to radians

      // Update map rotation
      _mapController.rotate(_mapRotation);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _routeController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            _buildTopNavigationBar(),

            // Main navigation instruction
            _buildMainInstruction(),

            // Map area (simplified)
            Expanded(child: _buildMapArea()),

            // Bottom navigation info
            _buildBottomNavigationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      height: 60,
      color: Colors.grey[900],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainInstruction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _routeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * _routeAnimation.value),
            child: Opacity(
              opacity: 0.7 + (0.3 * _routeAnimation.value),
              child: Row(
                children: [
                  // Turn icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.turn_right,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Distance and street
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_nextDistance.toStringAsFixed(1)} miles',
                          style: const TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _nextStreet,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Voice button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapArea() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition.latitude != 0
            ? _currentPosition
            : widget.currentLocation,
        initialZoom: 18.0, // ZOOMED IN - can see driver and collection clearly
        minZoom: 15.0,
        maxZoom: 20.0,
        initialRotation:
            _mapRotation, // AUTO ROTATION - destination always at top
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        // Google Maps Terrain tiles with live traffic
        TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.valwaste.app',
          maxZoom: 20,
        ),

        // Google Maps Traffic overlay
        TileLayer(
          urlTemplate:
              'https://mt1.google.com/vt/lyrs=m@221097413,traffic&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.valwaste.app',
          maxZoom: 20,
        ),

        // REAL Route polyline - ZOOMED IN
        PolylineLayer(
          polylines: [
            Polyline(
              points: [widget.currentLocation, widget.destination],
              strokeWidth: 8.0,
              color: Colors.blue,
            ),
          ],
        ),

        // REAL Markers - ZOOMED IN so you can see driver and collection clearly
        MarkerLayer(
          markers: [
            // REAL Current location marker (driver) - BIG and CLEAR
            Marker(
              point: _currentPosition.latitude != 0
                  ? _currentPosition
                  : widget.currentLocation,
              width: 60,
              height: 60,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
              ),
            ),

            // REAL Destination marker (collection request) - BIG and CLEAR
            Marker(
              point: widget.destination,
              width: 70,
              height: 70,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationInfo() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.record_voice_over,
              color: Colors.lightBlue,
              size: 20,
            ),
          ),

          const SizedBox(width: 15),

          // Time and distance info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${DateTime.now().add(Duration(minutes: _timeRemaining)).hour}:${DateTime.now().add(Duration(minutes: _timeRemaining)).minute.toString().padLeft(2, '0')} PM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_timeRemaining min',
                  style: const TextStyle(color: Colors.lightBlue, fontSize: 14),
                ),
              ],
            ),
          ),

          // Distance
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_distanceRemaining.toStringAsFixed(1)} miles',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'remaining',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(width: 15),

          // End navigation button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
