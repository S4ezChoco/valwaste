import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../utils/barangay_data.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_collection_service.dart';
import '../../services/route_optimization_service.dart';
import '../../models/waste_collection.dart';
import '../../widgets/announcement_card.dart';
import '../map/map_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<WasteCollection> _scheduledCollections = [];
  Map<String, dynamic>? _latestSchedule;
  bool _isLoadingSchedule = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledCollections();
    _loadLatestSchedule();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadScheduledCollections() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        final collections =
            await RouteOptimizationService.getOptimizedRouteForUser(
              userId: currentUser.id,
              userRole: currentUser.role,
            );

        print(
          'Driver dashboard: Loaded ${collections.length} scheduled collections',
        );
        for (var collection in collections) {
          print(
            'Scheduled collection: ${collection.id}, status: ${collection.status}, address: ${collection.address}',
          );
        }

        if (mounted) {
          setState(() {
            _scheduledCollections = collections;
          });
        }
      }
    } catch (e) {
      print('Error loading scheduled collections: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading scheduled collections: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startRoute(WasteCollection request) {
    print('Starting route for: ${request.wasteTypeText}');
    print(
      'Request details: ${request.address}, ${request.quantity} ${request.unit}',
    );

    // Navigate to map screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  Future<void> _loadLatestSchedule() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) return;

      // Query truck_schedule collection for driver's latest schedule
      final scheduleQuery = await FirebaseFirestore.instance
          .collection('truck_schedule')
          .where('driverId', isEqualTo: currentUser.id)
          .where('status', whereIn: ['pending', 'in_progress'])
          .orderBy('date', descending: false)
          .orderBy('startTime', descending: false)
          .limit(1)
          .get();

      if (scheduleQuery.docs.isNotEmpty) {
        setState(() {
          _latestSchedule = scheduleQuery.docs.first.data();
          _latestSchedule!['id'] = scheduleQuery.docs.first.id;
          _isLoadingSchedule = false;
        });
      } else {
        setState(() {
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      print('Error loading latest schedule: $e');
      setState(() {
        _isLoadingSchedule = false;
      });
    }
  }


  void _navigateToScheduleLocation() {
    if (_latestSchedule != null && _latestSchedule!['location'] != null) {
      // Navigate to map with schedule location
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MapScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Map Content
          SafeArea(
            child: Column(
              children: [
                // Header with ValWaste title
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${currentUser?.name ?? 'Driver'}!',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Driver of ValWaste',
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            onPressed: _loadScheduledCollections,
                            tooltip: 'Refresh Collections',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      // ValWaste Title
                      Text(
                        'ValWaste',
                        style: AppTextStyles.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // Map takes remaining space
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      child: const MapScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Latest Schedule Card (from admin panel)
          if (!_isLoadingSchedule && _latestSchedule != null)
            Positioned(
              top: 200,
              left: AppSizes.paddingLarge,
              right: AppSizes.paddingLarge,
              child: GestureDetector(
                onTap: _navigateToScheduleLocation,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Expanded(
                            child: Text(
                              'Today\'s Schedule',
                              style: AppTextStyles.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to Navigate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      // Truck and Time Info
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_latestSchedule!['startTime'] ?? 'N/A'} - ${_latestSchedule!['endTime'] ?? 'N/A'}',
                            style: AppTextStyles.body2.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: AppSizes.paddingMedium),
                          Icon(Icons.fire_truck, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _latestSchedule!['truck'] ?? 'No Truck Assigned',
                            style: AppTextStyles.body2.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              BarangayData.formatLocationDisplay(
                                _latestSchedule!['location'] ?? 'Unknown',
                              ),
                              style: AppTextStyles.body2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Streets if available
                      if (_latestSchedule!['streets'] != null &&
                          (_latestSchedule!['streets'] as List).isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          'Routes: ${(_latestSchedule!['streets'] as List).take(2).join(', ')}${(_latestSchedule!['streets'] as List).length > 2 ? ' +${(_latestSchedule!['streets'] as List).length - 2} more' : ''}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Announcement Overlay (if there are announcements)
          Positioned(
            bottom: 100,
            left: AppSizes.paddingLarge,
            right: AppSizes.paddingLarge,
            child: LatestAnnouncementCard(),
          ),

          // Scheduled Collections Overlay (if there are collections)
          if (_scheduledCollections.isNotEmpty)
            Positioned(
              top: 200,
              left: AppSizes.paddingLarge,
              right: AppSizes.paddingLarge,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scheduled Collections',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    ..._scheduledCollections
                        .take(2)
                        .map(
                          (request) => Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSizes.paddingSmall,
                            ),
                            padding: const EdgeInsets.all(
                              AppSizes.paddingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.paddingSmall),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        BarangayData.formatLocationDisplay(
                                          request.address,
                                        ),
                                        style: AppTextStyles.body2.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        request.wasteTypeText,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _startRoute(request),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.paddingSmall,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (_scheduledCollections.length > 2)
                      Text(
                        '+${_scheduledCollections.length - 2} more requests',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
