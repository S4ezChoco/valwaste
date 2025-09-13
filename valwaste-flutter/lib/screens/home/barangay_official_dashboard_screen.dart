import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/announcement_banner.dart';
import '../collection/collection_request_screen.dart';

class BarangayOfficialDashboardScreen extends StatelessWidget {
  const BarangayOfficialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Announcement Banner at the top
              const AnnouncementBanner(),
              
              const SizedBox(height: AppSizes.paddingMedium),
              
              // Enhanced Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            currentUser?.name ?? 'Barangay Official',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Barangay Official',
                              style: AppTextStyles.body2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingSmall),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Enhanced Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _EnhancedStatCard(
                      title: 'Pending Requests',
                      value: '12',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _EnhancedStatCard(
                      title: 'Today\'s Collections',
                      value: '45',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _EnhancedStatCard(
                      title: 'Active Drivers',
                      value: '8',
                      icon: Icons.local_shipping,
                      color: Colors.blue,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _EnhancedStatCard(
                      title: 'Routes Today',
                      value: '5',
                      icon: Icons.route,
                      color: Colors.purple,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600,
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Enhanced Quick Actions Section
              Row(
                children: [
                  Icon(Icons.flash_on, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Enhanced Action Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMedium,
                mainAxisSpacing: AppSizes.paddingMedium,
                childAspectRatio: 1.1,
                children: [
                  _EnhancedActionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Review Requests',
                    subtitle: 'Manage collection requests',
                    color: AppColors.primary,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionRequestScreen(),
                        ),
                      );
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.schedule_outlined,
                    title: 'Manage Schedule',
                    subtitle: 'Update collection times',
                    color: Colors.blue,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    onTap: () {
                      // Navigate to schedule management
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.map_outlined,
                    title: 'Route Planning',
                    subtitle: 'Optimize collection routes',
                    color: Colors.purple,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    onTap: () {
                      // Navigate to map
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Reports',
                    subtitle: 'View collection statistics',
                    color: Colors.teal,
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    onTap: () {
                      // Navigate to reports
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.people_outline,
                    title: 'Driver Management',
                    subtitle: 'Manage driver assignments',
                    color: Colors.indigo,
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                    ),
                    onTap: () {
                      // Navigate to driver management
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Send Notifications',
                    subtitle: 'Alert residents',
                    color: Colors.red,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    onTap: () {
                      // Navigate to notifications
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Enhanced Recent Requests Section
              Row(
                children: [
                  Icon(Icons.history, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    'Recent Requests',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionRequestScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Enhanced Request Cards
              _EnhancedRequestCard(
                residentName: 'Juan Dela Cruz',
                address: '123 Main St, Barangay 1',
                requestType: 'Regular Collection',
                status: 'Pending',
                time: '1 hour ago',
                avatar: 'JD',
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _EnhancedRequestCard(
                residentName: 'Maria Santos',
                address: '456 Oak Ave, Barangay 2',
                requestType: 'Bulk Waste',
                status: 'Approved',
                time: '2 hours ago',
                avatar: 'MS',
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _EnhancedRequestCard(
                residentName: 'Pedro Reyes',
                address: '789 Pine St, Barangay 3',
                requestType: 'Recyclable Collection',
                status: 'Completed',
                time: '3 hours ago',
                avatar: 'PR',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const _EnhancedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _EnhancedActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedRequestCard extends StatelessWidget {
  final String residentName;
  final String address;
  final String requestType;
  final String status;
  final String time;
  final String avatar;

  const _EnhancedRequestCard({
    required this.residentName,
    required this.address,
    required this.requestType,
    required this.status,
    required this.time,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                avatar,
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        residentName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: AppTextStyles.body2.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  address,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      requestType,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
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
}
