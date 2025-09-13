import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/report_service.dart';

class BarangayReportsScreen extends StatefulWidget {
  const BarangayReportsScreen({super.key});

  @override
  State<BarangayReportsScreen> createState() => _BarangayReportsScreenState();
}

class _BarangayReportsScreenState extends State<BarangayReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Review Reports',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ReportService.getBarangayReports(),
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
                    'No pending reports to review',
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

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                child: InkWell(
                  onTap: () => _showReportDetails(context, doc.id, data),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Pending Review',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reported by ${data['reportedBy'] ?? 'Anonymous'}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
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
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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

  void _showReportDetails(BuildContext context, String reportId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Details',
                        style: AppTextStyles.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),
                      
                      _DetailRow(
                        icon: Icons.title,
                        label: 'Title',
                        value: data['title'] ?? 'Untitled',
                      ),
                      _DetailRow(
                        icon: Icons.category,
                        label: 'Category',
                        value: data['category'] ?? 'Other',
                      ),
                      _DetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: data['location'] ?? 'Unknown',
                      ),
                      _DetailRow(
                        icon: Icons.person,
                        label: 'Reported By',
                        value: data['reportedBy'] ?? 'Anonymous',
                      ),
                      
                      const SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        'Description',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        data['description'] ?? 'No description provided',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: AppSizes.paddingLarge),
                      
                      // Mark as Critical Checkbox
                      CheckboxListTile(
                        value: false,
                        onChanged: (value) {
                          // Will be handled in action buttons
                        },
                        title: Text(
                          'Mark as Critical Issue',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'This will prioritize the report for admin review',
                          style: AppTextStyles.caption,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.red,
                      ),
                      
                      const SizedBox(height: AppSizes.paddingLarge),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectReport(context, reportId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                                ),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingMedium),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _sendToAdmin(context, reportId, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                                ),
                              ),
                              child: const Text(
                                'Send to Admin',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSizes.paddingSmall),
                      
                      // Send as Critical Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _sendToAdmin(context, reportId, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            'Send as Critical Issue',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendToAdmin(BuildContext context, String reportId, bool isCritical) async {
    try {
      await ReportService.sendReportToAdmin(reportId, isCritical: isCritical);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCritical
                  ? 'Report sent to admin as critical issue'
                  : 'Report sent to admin for review',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectReport(BuildContext context, String reportId) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Report'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (reason != null && reason.isNotEmpty) {
      try {
        await ReportService.rejectReport(reportId, reason);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.paddingSmall),
          Text(
            '$label: ',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
