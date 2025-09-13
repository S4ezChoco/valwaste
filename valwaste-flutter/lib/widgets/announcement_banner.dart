import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/announcement_service.dart';

class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AnnouncementService.getActiveAnnouncements(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final announcements = snapshot.data!.docs;
        
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index].data() as Map<String, dynamic>;
                  final title = announcement['title'] ?? 'Announcement';
                  final content = announcement['content'] ?? '';
                  final priority = announcement['priority'] ?? 'normal';
                  
                  Color bgColor = AppColors.primary.withOpacity(0.1);
                  Color borderColor = AppColors.primary;
                  IconData icon = Icons.info_outline;
                  
                  if (priority == 'high') {
                    bgColor = Colors.red.withOpacity(0.1);
                    borderColor = Colors.red;
                    icon = Icons.warning;
                  } else if (priority == 'medium') {
                    bgColor = Colors.orange.withOpacity(0.1);
                    borderColor = Colors.orange;
                    icon = Icons.announcement;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: borderColor.withOpacity(0.3)),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: borderColor, size: 24),
                        ),
                        const SizedBox(width: AppSizes.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                content,
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (announcements.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${index + 1}/${announcements.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: borderColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (announcements.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      announcements.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
