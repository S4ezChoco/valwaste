import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/pdf_service.dart';
import '../../services/firebase_collection_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/waste_collection.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isGeneratingReport = false;
  bool _isLoading = true;
  List<WasteCollection> _collections = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final collections = await FirebaseCollectionService.getUserCollections();
      final stats = await FirebaseCollectionService.getUserCollectionStats();

      setState(() {
        _collections = collections;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      // Calculate waste type breakdown
      final Map<String, int> wasteTypeBreakdown = {};
      for (var collection in _collections) {
        final wasteType = collection.wasteTypeText;
        wasteTypeBreakdown[wasteType] = (wasteTypeBreakdown[wasteType] ?? 0) + 1;
      }

      // Convert collections to report items (include all collections, not just completed)
      final recentReports = _collections
          .take(15) // Include more items in the report
          .map(
            (collection) => WasteReportItem(
              type: collection.wasteTypeText,
              date: collection.completedAt != null
                  ? '${collection.completedAt?.day}/${collection.completedAt?.month}/${collection.completedAt?.year}'
                  : '${collection.scheduledDate.day}/${collection.scheduledDate.month}/${collection.scheduledDate.year}',
              status: collection.statusText,
              quantity: '${collection.quantity} ${collection.unit}',
            ),
          )
          .toList();

      await PdfService.generateWasteReport(
        userName: FirebaseAuthService.currentUser?.name ?? 'User',
        totalCollections: _stats['totalCollections'] ?? 0,
        completedCollections: _stats['completedCollections'] ?? 0,
        pendingCollections: _stats['pendingCollections'] ?? 0,
        totalWeight: (_stats['totalWeight'] ?? 0.0).toDouble(),
        recentReports: recentReports,
        wasteTypeBreakdown: wasteTypeBreakdown,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: const BoxDecoration(color: AppColors.surface),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to Home',
                  ),
                  Expanded(
                    child: Text(
                      'Report',
                      style: AppTextStyles.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _loadData,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
            ),

            // Report Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: Column(
                        children: [
                          // Report Statistics Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildReportCard(
                                  title: 'Total Collections',
                                  value: '${_stats['totalCollections'] ?? 0}',
                                  icon: Icons.delete_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingMedium),
                              Expanded(
                                child: _buildReportCard(
                                  title: 'Completed',
                                  value:
                                      '${_stats['completedCollections'] ?? 0}',
                                  icon: Icons.recycling,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSizes.paddingMedium),

                          // Additional Statistics
                          Row(
                            children: [
                              Expanded(
                                child: _buildReportCard(
                                  title: 'Pending',
                                  value: '${_stats['pendingCollections'] ?? 0}',
                                  icon: Icons.schedule,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingMedium),
                              Expanded(
                                child: _buildReportCard(
                                  title: 'Total Weight',
                                  value:
                                      '${(_stats['totalWeight'] ?? 0.0).toStringAsFixed(1)} kg',
                                  icon: Icons.scale,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSizes.paddingLarge),

                          // Recent Reports
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(
                              AppSizes.paddingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Reports',
                                  style: AppTextStyles.heading3.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.paddingMedium),

                                _collections.isEmpty
                                    ? Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.history,
                                              size: 48,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(
                                              height: AppSizes.paddingMedium,
                                            ),
                                            Text(
                                              'No collection history',
                                              style: AppTextStyles.body1
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: AppSizes.paddingSmall,
                                            ),
                                            Text(
                                              'Start by requesting a collection',
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          // Collection Summary
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Showing ${_collections.length} collection${_collections.length == 1 ? '' : 's'} from your history',
                                                    style: AppTextStyles.body2
                                                        .copyWith(
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Collection Items
                                          ..._collections
                                              .take(5)
                                              .map(
                                                (collection) => Column(
                                                  children: [
                                                    _buildDetailedReportItem(
                                                      collection,
                                                    ),
                                                    if (collection !=
                                                        _collections
                                                            .take(5)
                                                            .last)
                                                      const Divider(),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ],
                                      ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSizes.paddingLarge),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _collections.isEmpty
                                      ? null
                                      : () {
                                          _showAllCollectionsDialog();
                                        },
                                  icon: const Icon(Icons.history, size: 18),
                                  label: Text(
                                    'View All (${_collections.length})',
                                    style: AppTextStyles.button.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSizes.paddingMedium,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingMedium),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingReport
                                      ? null
                                      : _generateReport,
                                  icon: _isGeneratingReport
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.file_download,
                                          size: 18,
                                        ),
                                  label: Text(
                                    _isGeneratingReport
                                        ? 'Generating...'
                                        : 'Generate PDF',
                                    style: AppTextStyles.button.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSizes.paddingMedium,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem({
    required String date,
    required String type,
    required String status,
    required String quantity,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: const Icon(
              Icons.description,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quantity,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportItem(WasteCollection collection) {
    Color statusColor;
    IconData statusIcon;

    switch (collection.status) {
      case CollectionStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case CollectionStatus.scheduled:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case CollectionStatus.approved:
        statusColor = Colors.lightBlue;
        statusIcon = Icons.check_circle_outline;
        break;
      case CollectionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case CollectionStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.work;
        break;
      case CollectionStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case CollectionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    collection.wasteTypeText,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    collection.statusText,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Details row
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.scale,
                    label: 'Quantity',
                    value: '${collection.quantity} ${collection.unit}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Scheduled',
                    value:
                        '${collection.scheduledDate.day}/${collection.scheduledDate.month}/${collection.scheduledDate.year}',
                  ),
                ),
              ],
            ),

            if (collection.address.isNotEmpty) ...[
              const SizedBox(height: 8),
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
                      collection.address,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (collection.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      collection.description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAllCollectionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All Collections (${_collections.length})',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Collections List
              Expanded(
                child: _collections.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No collections found',
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _collections.length,
                        itemBuilder: (context, index) {
                          final collection = _collections[index];
                          return Column(
                            children: [
                              _buildDetailedReportItem(collection),
                              if (index < _collections.length - 1)
                                const Divider(height: 16),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
