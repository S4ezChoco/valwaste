import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/announcement_service.dart';
import '../collection/collection_request_screen.dart';
import '../guide/recycling_guide_screen.dart';
import '../reports/resident_reports_screen.dart';
import '../reports/create_report_screen.dart';
import '../announcements/announcements_screen.dart';
import '../schedule/schedule_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() => _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _todaySchedule;
  int _activeReports = 0;
  int _totalReports = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTodaySchedule();
    await _loadReportStats();
  }

  Future<void> _loadTodaySchedule() async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final scheduleQuery = await _firestore
        .collection('truck_schedule')
        .where('date', isEqualTo: todayString)
        .limit(1)
        .get();
    
    if (scheduleQuery.docs.isNotEmpty && mounted) {
      setState(() {
        _todaySchedule = scheduleQuery.docs.first.data();
      });
    }
  }

  Future<void> _loadReportStats() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final reportsQuery = await _firestore
        .collection('barangay_reports')
        .where('reporterId', isEqualTo: user.uid)
        .get();
    
    if (mounted) {
      setState(() {
        _totalReports = reportsQuery.docs.length;
        _activeReports = reportsQuery.docs
            .where((doc) => doc.data()['status'] == 'pending_review' || doc.data()['status'] == 'sent_to_admin')
            .length;
      });
    }
  }

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
              if (_todaySchedule != null)
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
                              'Scheduled for ${_todaySchedule!['startTime']} - ${_todaySchedule!['endTime']}',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 24),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Collection Today',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'Check schedule for upcoming collections',
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

              // Announcements Section
              StreamBuilder<QuerySnapshot>(
                stream: AnnouncementService.getActiveAnnouncements(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  final latestAnnouncement = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    margin: const EdgeInsets.only(bottom: AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.campaign, color: AppColors.primary, size: 20),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Text(
                              'Latest Announcement',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          latestAnnouncement['message'] ?? '',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AnnouncementsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View all announcements →',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleScreen(),
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
                    icon: Icons.report_problem,
                    title: 'Report Issue',
                    subtitle: 'Report waste problems',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateReportScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.notifications,
                    title: 'Announcements',
                    subtitle: 'Important updates',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnnouncementsScreen(),
                        ),
                      );
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

              const SizedBox(height: AppSizes.paddingLarge),

              // Report Statistics
              Text(
                'Your Reports',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Activity Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _totalReports.toString(),
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Reports',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _activeReports.toString(),
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
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
