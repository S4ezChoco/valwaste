import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/report_service.dart';
import 'create_report_screen.dart';

class ResidentReportsScreen extends StatelessWidget {
  const ResidentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text('Please login to view reports'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'My Reports',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ReportService.getResidentReports(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reports',
                style: AppTextStyles.body1.copyWith(color: AppColors.error),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Text(
                    'No reports yet',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateReportScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(data['category']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data['category'] ?? 'Other',
                              style: AppTextStyles.caption.copyWith(
                                color: _getCategoryColor(data['category']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _StatusBadge(status: data['status']),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        data['title'] ?? 'Untitled Report',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['location'] ?? 'Unknown location',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            createdAt != null
                                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                : '',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (data['status'] == 'rejected' && data['barangayNotes'] != null) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rejection reason: ${data['barangayNotes']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateReportScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Missed Collection':
        return Colors.blue;
      case 'Illegal Dumping':
        return Colors.red;
      case 'Damaged Equipment':
        return Colors.orange;
      case 'Complaint':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;

  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'pending_review':
        color = Colors.orange;
        text = 'Pending Review';
        break;
      case 'sent_to_admin':
        color = Colors.blue;
        text = 'Sent to Admin';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'resolved':
        color = Colors.green;
        text = 'Resolved';
        break;
      case 'unresolved':
        color = Colors.grey;
        text = 'Unresolved';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
