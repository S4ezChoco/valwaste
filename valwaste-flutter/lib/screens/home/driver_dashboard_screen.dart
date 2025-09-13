import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

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
              // Welcome Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.local_shipping,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currentUser?.name ?? 'Driver',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Today's Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Today\'s Stops',
                      value: '23',
                      icon: Icons.location_on,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _StatCard(
                      title: 'Completed',
                      value: '18',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Remaining',
                      value: '5',
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _StatCard(
                      title: 'Efficiency',
                      value: '78%',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Current Route
              Text(
                'Current Route',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: AppColors.primary),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(
                          'Route A - Morning Shift',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      'Next stop: 123 Main St, Barangay 1',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    LinearProgressIndicator(
                      value: 0.75,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      '75% Complete',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Action Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMedium,
                mainAxisSpacing: AppSizes.paddingMedium,
                childAspectRatio: 1.2,
                children: [
                  _ActionCard(
                    icon: Icons.map_outlined,
                    title: 'View Route',
                    subtitle: 'See today\'s route',
                    color: AppColors.primary,
                    onTap: () {
                      // Navigate to map
                    },
                  ),
                  _ActionCard(
                    icon: Icons.check_circle_outline,
                    title: 'Mark Complete',
                    subtitle: 'Update collection status',
                    color: Colors.green,
                    onTap: () {
                      // Mark collection complete
                    },
                  ),
                  _ActionCard(
                    icon: Icons.schedule_outlined,
                    title: 'Schedule',
                    subtitle: 'View collection schedule',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to schedule
                    },
                  ),
                  _ActionCard(
                    icon: Icons.report_problem_outlined,
                    title: 'Report Issue',
                    subtitle: 'Report problems',
                    color: Colors.red,
                    onTap: () {
                      // Report issue
                    },
                  ),
                  _ActionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Start Route',
                    subtitle: 'Begin collection route',
                    color: Colors.blue,
                    onTap: () {
                      // Start route
                    },
                  ),
                  _ActionCard(
                    icon: Icons.stop_outlined,
                    title: 'End Route',
                    subtitle: 'Finish collection route',
                    color: Colors.grey,
                    onTap: () {
                      // End route
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Next Stops
              Text(
                'Next Stops',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Stop Cards
              _StopCard(
                address: '123 Main St, Barangay 1',
                time: '9:30 AM',
                wasteType: 'Regular',
                status: 'Pending',
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _StopCard(
                address: '456 Oak Ave, Barangay 2',
                time: '10:00 AM',
                wasteType: 'Recyclable',
                status: 'Pending',
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _StopCard(
                address: '789 Pine St, Barangay 3',
                time: '10:30 AM',
                wasteType: 'Bulk Waste',
                status: 'Pending',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSizes.paddingSmall),
              Text(
                title,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final String address;
  final String time;
  final String wasteType;
  final String status;

  const _StopCard({
    required this.address,
    required this.time,
    required this.wasteType,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$wasteType • $time',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: status == 'Pending' ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
