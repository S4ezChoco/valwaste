import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../collection/collection_request_screen.dart';
import '../guide/recycling_guide_screen.dart';

class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

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
                      Icons.person,
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
                          'Welcome back!',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currentUser?.name ?? 'Resident',
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

              // Today's Collection Status
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Collection',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Scheduled for 9:00 AM - 11:00 AM',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                    icon: Icons.add_circle_outline,
                    title: 'Request Collection',
                    subtitle: 'Schedule waste pickup',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionRequestScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.schedule_outlined,
                    title: 'View Schedule',
                    subtitle: 'Check pickup times',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to schedule
                    },
                  ),
                  _ActionCard(
                    icon: Icons.recycling_outlined,
                    title: 'Recycling Guide',
                    subtitle: 'Learn proper disposal',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RecyclingGuideScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.map_outlined,
                    title: 'Collection Map',
                    subtitle: 'Track collection routes',
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to map
                    },
                  ),
                  _ActionCard(
                    icon: Icons.history_outlined,
                    title: 'Collection History',
                    subtitle: 'View past pickups',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to history
                    },
                  ),
                  _ActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Stay updated',
                    color: Colors.red,
                    onTap: () {
                      // Navigate to notifications
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Recent Activity
              Text(
                'Recent Activity',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Activity Cards
              _ActivityCard(
                title: 'Collection Request Submitted',
                subtitle: 'Regular waste collection for tomorrow',
                time: '2 hours ago',
                icon: Icons.add_circle,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _ActivityCard(
                title: 'Collection Completed',
                subtitle: 'Regular waste collection',
                time: 'Yesterday',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _ActivityCard(
                title: 'Recycling Guide Viewed',
                subtitle: 'Proper disposal methods',
                time: '3 days ago',
                icon: Icons.recycling,
                color: Colors.green,
              ),
            ],
          ),
        ),
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

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
