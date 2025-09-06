import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../collection/collection_request_screen.dart';

class AdministratorDashboardScreen extends StatelessWidget {
  const AdministratorDashboardScreen({super.key});

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
                      Icons.admin_panel_settings,
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
                          'Administrator',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          currentUser?.name ?? 'Admin',
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

              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Users',
                      value: '1,234',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _StatCard(
                      title: 'Active Collections',
                      value: '89',
                      icon: Icons.local_shipping,
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
                      title: 'Pending Requests',
                      value: '23',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _StatCard(
                      title: 'Today\'s Collections',
                      value: '156',
                      icon: Icons.check_circle,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Active Drivers',
                      value: '12',
                      icon: Icons.local_shipping,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _StatCard(
                      title: 'System Health',
                      value: '98%',
                      icon: Icons.health_and_safety,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // System Overview
              Text(
                'System Overview',
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
                        Icon(Icons.analytics, color: AppColors.primary),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(
                          'Performance Metrics',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Collection Efficiency',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '94%',
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Satisfaction',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '4.8/5',
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    icon: Icons.people_outline,
                    title: 'User Management',
                    subtitle: 'Manage all users',
                    color: AppColors.primary,
                    onTap: () {
                      // Navigate to user management
                    },
                  ),
                  _ActionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Review Requests',
                    subtitle: 'Manage collection requests',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionRequestScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    subtitle: 'View system statistics',
                    color: Colors.green,
                    onTap: () {
                      // Navigate to analytics
                    },
                  ),
                  _ActionCard(
                    icon: Icons.settings_outlined,
                    title: 'System Settings',
                    subtitle: 'Configure system',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                  _ActionCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Driver Management',
                    subtitle: 'Manage drivers & routes',
                    color: Colors.indigo,
                    onTap: () {
                      // Navigate to driver management
                    },
                  ),
                  _ActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Send Notifications',
                    subtitle: 'Alert all users',
                    color: Colors.red,
                    onTap: () {
                      // Navigate to notifications
                    },
                  ),
                  _ActionCard(
                    icon: Icons.backup_outlined,
                    title: 'Backup System',
                    subtitle: 'Create system backup',
                    color: Colors.teal,
                    onTap: () {
                      // Navigate to backup
                    },
                  ),
                  _ActionCard(
                    icon: Icons.security_outlined,
                    title: 'Security',
                    subtitle: 'Manage security settings',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to security
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Recent System Activities
              Text(
                'Recent System Activities',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Activity Cards
              _ActivityCard(
                title: 'New User Registered',
                subtitle: 'Juan Dela Cruz - Resident',
                time: '5 minutes ago',
                icon: Icons.person_add,
                color: Colors.blue,
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _ActivityCard(
                title: 'Collection Request Approved',
                subtitle: 'Maria Santos - Bulk Waste',
                time: '15 minutes ago',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              _ActivityCard(
                title: 'System Backup Completed',
                subtitle: 'Daily backup successful',
                time: '1 hour ago',
                icon: Icons.backup,
                color: Colors.teal,
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
