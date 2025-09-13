import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_collection_service.dart';
import '../../models/waste_collection.dart';
import '../../widgets/announcement_card.dart';
import '../map/map_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<WasteCollection> _approvedRequests = [];

  @override
  void initState() {
    super.initState();
    _loadApprovedRequests();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadApprovedRequests() async {
    try {
      final requests =
          await FirebaseCollectionService.getApprovedCollectionRequests();
      if (mounted) {
        setState(() {
          _approvedRequests = requests;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading approved requests: $e'),
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

  String _getLocationDisplayName(String address) {
    // If address contains coordinates, return a generic location name
    if (address.contains(',') &&
        RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$').hasMatch(address.trim())) {
      return 'Collection Point';
    }

    // If address contains "Collection Point", use that
    if (address.toLowerCase().contains('collection point')) {
      return address;
    }

    // If address contains "Valenzuela City", extract the main part
    if (address.toLowerCase().contains('valenzuela city')) {
      final parts = address.split(',');
      if (parts.length > 1) {
        return parts[0].trim();
      }
    }

    // For other addresses, take the first part before comma or use full address if short
    if (address.contains(',')) {
      final parts = address.split(',');
      final firstPart = parts[0].trim();
      return firstPart.length > 20
          ? '${firstPart.substring(0, 20)}...'
          : firstPart;
    }

    // If address is too long, truncate it
    if (address.length > 25) {
      return '${address.substring(0, 25)}...';
    }

    return address;
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

          // Announcement Overlay (if there are announcements)
          Positioned(
            bottom: 100,
            left: AppSizes.paddingLarge,
            right: AppSizes.paddingLarge,
            child: LatestAnnouncementCard(),
          ),

          // Approved Requests Overlay (if there are requests)
          if (_approvedRequests.isNotEmpty)
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
                      'Approved Requests',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    ..._approvedRequests
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
                                        _getLocationDisplayName(
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
                    if (_approvedRequests.length > 2)
                      Text(
                        '+${_approvedRequests.length - 2} more requests',
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
