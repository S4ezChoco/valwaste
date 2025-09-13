import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/driver_collection_service.dart';
import '../../models/waste_collection.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  List<WasteCollection> _assignedCollections = [];
  bool _isLoading = true;
  String _selectedFilter = 'Today';
  final List<String> _filterOptions = ['Today', 'This Week', 'All'];

  @override
  void initState() {
    super.initState();
    _loadAssignedCollections();
  }

  Future<void> _loadAssignedCollections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get collections assigned to this driver
      final collections = await _getDriverAssignedCollections();

      // Filter collections based on selected filter
      final filteredCollections = _filterCollections(collections);

      setState(() {
        _assignedCollections = filteredCollections;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading driver collections: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<WasteCollection>> _getDriverAssignedCollections() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Get collections where assigned_to matches current user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('collections')
          .where('assigned_to', isEqualTo: currentUser.id)
          .get();

      final allCollections = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return WasteCollection.fromJson(data);
      }).toList();

      // Filter out completed collections in the app
      final filteredCollections = allCollections.where((collection) {
        return collection.status == CollectionStatus.approved ||
            collection.status == CollectionStatus.scheduled ||
            collection.status == CollectionStatus.inProgress;
      }).toList();

      // Sort by scheduled date
      filteredCollections.sort(
        (a, b) => a.scheduledDate.compareTo(b.scheduledDate),
      );

      return filteredCollections;
    } catch (e) {
      print('Error getting driver assigned collections: $e');
      return [];
    }
  }

  List<WasteCollection> _filterCollections(List<WasteCollection> collections) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'Today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        return collections.where((collection) {
          return collection.scheduledDate.isAfter(startOfDay) &&
              collection.scheduledDate.isBefore(endOfDay);
        }).toList();

      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return collections.where((collection) {
          return collection.scheduledDate.isAfter(startOfWeek) &&
              collection.scheduledDate.isBefore(endOfWeek);
        }).toList();

      case 'All':
      default:
        return collections;
    }
  }

  Future<void> _markAsDone(WasteCollection collection) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Done'),
          content: Text(
            'Are you sure you want to mark this ${collection.wasteTypeText} collection as completed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Update status to completed using DriverCollectionService
        final result = await DriverCollectionService.updateCollectionStatus(
          collectionId: collection.id,
          status: CollectionStatus.completed,
        );

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collection marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the list to remove the completed collection
          _loadAssignedCollections();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark collection as done: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return Colors.grey;
      case CollectionStatus.approved:
        return Colors.blue;
      case CollectionStatus.scheduled:
        return Colors.purple;
      case CollectionStatus.inProgress:
        return Colors.orange;
      case CollectionStatus.completed:
        return Colors.green;
      case CollectionStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildCollectionRequestCard(
    WasteCollection collection,
    int requestNumber,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Collection details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with request number and status
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '$requestNumber',
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                collection.status,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              collection.statusText,
                              style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(collection.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.navigation,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Distance unknown',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingSmall),

                // Address
                Text(
                  collection.address,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSizes.paddingSmall),

                // Waste type and date tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            collection.wasteTypeText,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            '${collection.scheduledDate.day}/${collection.scheduledDate.month}/${collection.scheduledDate.year}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (collection.description.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingSmall),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingSmall),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      collection.description,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right side - Done button
          const SizedBox(width: AppSizes.paddingSmall),
          Column(
            children: [
              SizedBox(
                width: 80,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _markAsDone(collection),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Done',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MY ASSIGNED COLLECTIONS',
                          style: AppTextStyles.heading3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Driver Collection Schedule',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadAssignedCollections,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // Filter Options
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final option = _filterOptions[index];
                  final isSelected = _selectedFilter == option;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = option;
                      });
                      _loadAssignedCollections();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: AppSizes.paddingSmall,
                      ),
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

            // Collections List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _assignedCollections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          Text(
                            'No Collections Assigned',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'You don\'t have any collections assigned for $_selectedFilter',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAssignedCollections,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                        itemCount: _assignedCollections.length,
                        itemBuilder: (context, index) {
                          final collection = _assignedCollections[index];
                          return _buildCollectionRequestCard(
                            collection,
                            index + 1,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
