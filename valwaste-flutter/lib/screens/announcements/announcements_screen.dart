import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/announcement_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Announcements',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archive'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveAnnouncements(),
          _ArchivedAnnouncements(),
        ],
      ),
    );
  }
}

class _ActiveAnnouncements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AnnouncementService.getActiveAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading announcements',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.error,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'No active announcements',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.campaign,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Expanded(
                          child: Text(
                            'Admin Announcement',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (data['duration'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${data['duration']}h',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      data['message'] ?? '',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdAt != null
                              ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                              : 'Unknown',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (expiresAt != null) ...[
                          const SizedBox(width: AppSizes.paddingMedium),
                          Icon(
                            Icons.timer_off,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ArchivedAnnouncements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AnnouncementService.getArchivedAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading archived announcements',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.error,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'No archived announcements',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final archivedAt = (data['archivedAt'] as Timestamp?)?.toDate();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.archive,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(
                          'Archived Announcement',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      data['message'] ?? '',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      archivedAt != null
                          ? 'Archived: ${archivedAt.day}/${archivedAt.month}/${archivedAt.year}'
                          : 'Unknown',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
