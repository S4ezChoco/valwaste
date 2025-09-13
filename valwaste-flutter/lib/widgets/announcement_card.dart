import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class LatestAnnouncementCard extends StatefulWidget {
  LatestAnnouncementCard({super.key});

  @override
  State<LatestAnnouncementCard> createState() => _LatestAnnouncementCardState();
}

class _LatestAnnouncementCardState extends State<LatestAnnouncementCard> {
  final AnnouncementService _service = AnnouncementService();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Announcement>>(
      stream: _service.getActiveAnnouncements(),
      builder: (context, snapshot) {
        print(
          'LatestAnnouncementCard: Connection state: ${snapshot.connectionState}',
        );
        print('LatestAnnouncementCard: Has data: ${snapshot.hasData}');
        print('LatestAnnouncementCard: Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('LatestAnnouncementCard: Error: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          print(
            'LatestAnnouncementCard: Data length: ${snapshot.data!.length}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('LatestAnnouncementCard: Hiding due to error');
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('LatestAnnouncementCard: Hiding - no announcements');
          return const SizedBox.shrink(); // Hide if no announcements
        }

        final announcements = snapshot.data!;
        print(
          'LatestAnnouncementCard: Showing ${_isExpanded ? 'all' : 'latest'} announcements',
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.announcement,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isExpanded ? 'All Announcements' : 'Latest Announcement',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (announcements.length > 1)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Announcements content
              if (_isExpanded) ...[
                // Show all announcements
                ...(announcements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final announcement = entry.value;
                  final isLast = index == announcements.length - 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.message,
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            announcement.createdBy,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            announcement.timeAgo,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: AppColors.divider.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }).toList()),
              ] else ...[
                // Show only latest announcement
                Text(
                  announcements.first.message,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      announcements.first.createdBy,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      announcements.first.timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
