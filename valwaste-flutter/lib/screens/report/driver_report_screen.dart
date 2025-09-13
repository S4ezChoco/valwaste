import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/driver_collection_service.dart';
import '../../models/waste_collection.dart';

class DriverReportScreen extends StatefulWidget {
  const DriverReportScreen({super.key});

  @override
  State<DriverReportScreen> createState() => _DriverReportScreenState();
}

class _DriverReportScreenState extends State<DriverReportScreen> {
  List<WasteCollection> _completedCollections = [];
  Map<String, dynamic> _collectionStats = {};
  bool _isLoading = true;
  String _selectedPeriod = 'Today';
  final List<String> _periodOptions = ['Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load completed collections and statistics
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (_selectedPeriod) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(const Duration(days: 1));
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          endDate = startDate.add(const Duration(days: 7));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(const Duration(days: 1));
      }

      // Get completed collections for the period
      final collections = await DriverCollectionService.getDriverCollections(
        startDate: startDate,
        endDate: endDate,
        status: CollectionStatus.completed,
      );

      // Get collection statistics
      final stats = await DriverCollectionService.getDriverCollectionStats(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _completedCollections = collections;
        _collectionStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading collection data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collection Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _periodOptions.length,
              itemBuilder: (context, index) {
                final option = _periodOptions[index];
                final isSelected = _selectedPeriod == option;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = option;
                    });
                    _loadCollectionData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: AppSizes.paddingSmall),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: AppSizes.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: AppTextStyles.body1.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCollectionData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Cards
                          _buildStatisticsCards(),

                          const SizedBox(height: AppSizes.paddingLarge),

                          // Completed Collections
                          Text(
                            'Completed Collections',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),

                          if (_completedCollections.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                AppSizes.paddingLarge,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMedium,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(
                                    height: AppSizes.paddingMedium,
                                  ),
                                  Text(
                                    'No Completed Collections',
                                    style: AppTextStyles.heading3.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.paddingSmall),
                                  Text(
                                    'You haven\'t completed any collections for $_selectedPeriod',
                                    style: AppTextStyles.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._completedCollections.map(
                              (collection) => _buildCollectionCard(collection),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      children: [
        // Row 1: Total Collections and Completed
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Collections',
                '${_collectionStats['total_collections'] ?? 0}',
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSizes.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${_collectionStats['completed_collections'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingSmall),

        // Row 2: Total Weight and Completion Rate
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Weight',
                '${_collectionStats['total_weight']?.toStringAsFixed(1) ?? '0.0'} kg',
                Icons.scale,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppSizes.paddingSmall),
            Expanded(
              child: _buildStatCard(
                'Completion Rate',
                '${(_collectionStats['completion_rate'] ?? 0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
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

  Widget _buildCollectionCard(WasteCollection collection) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.wasteTypeText,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${collection.quantity} ${collection.unit}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.paddingSmall),

          // Address
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  collection.address,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.paddingSmall),

          // Date and Time
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${collection.scheduledDate.day}/${collection.scheduledDate.month}/${collection.scheduledDate.year}',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${collection.scheduledDate.hour.toString().padLeft(2, '0')}:${collection.scheduledDate.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          if (collection.description.isNotEmpty) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              collection.description,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
