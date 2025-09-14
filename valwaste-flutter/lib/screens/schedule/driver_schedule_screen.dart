import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  List<Map<String, dynamic>> _assignedSchedules = [];
  bool _isLoading = true;
  String _selectedFilter = 'Today';
  final List<String> _filterOptions = ['Today', 'This Week', 'All'];

  @override
  void initState() {
    super.initState();
    _loadAssignedSchedules();
  }

  Future<void> _loadAssignedSchedules() async {
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

      // Get truck schedules assigned to this driver
      final schedules = await _getDriverAssignedSchedules();

      // Filter schedules based on selected filter
      final filteredSchedules = _filterSchedules(schedules);

      setState(() {
        _assignedSchedules = filteredSchedules;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading driver schedules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getDriverAssignedSchedules() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) {
        return [];
      }

      print('Fetching schedules for driver: ${currentUser.id}');

      // Get truck schedules where driverId matches current user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('truck_schedule')
          .where('driverId', isEqualTo: currentUser.id)
          .get();

      print('Found ${querySnapshot.docs.length} schedules for driver');

      final allSchedules = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is set
        return data;
      }).toList();

      // Filter out cancelled or completed schedules
      final activeSchedules = allSchedules.where((schedule) {
        final status = schedule['status'] ?? 'scheduled';
        return status == 'scheduled' || status == 'inProgress';
      }).toList();

      // Sort by date and start time
      activeSchedules.sort((a, b) {
        final dateComparison = (a['date'] ?? '').compareTo(b['date'] ?? '');
        if (dateComparison != 0) return dateComparison;
        return (a['startTime'] ?? '').compareTo(b['startTime'] ?? '');
      });

      print('Filtered to ${activeSchedules.length} active schedules');
      return activeSchedules;
    } catch (e) {
      print('Error getting driver assigned schedules: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _filterSchedules(
    List<Map<String, dynamic>> schedules,
  ) {
    final now = DateTime.now();

    // Today's date in multiple possible formats to match PHP admin
    final todayString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayStringAlt =
        '${now.day}/${now.month}/${now.year}'; // D/M/YYYY format (14/9/2025)
    final todayStringAlt2 =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'; // DD/MM/YYYY format

    print('=== DATE FILTER DEBUG ===');
    print('Current DateTime: $now');
    print('Today filter options:');
    print('  Format 1: "$todayString" (YYYY-MM-DD)');
    print('  Format 2: "$todayStringAlt" (D/M/YYYY)');
    print('  Format 3: "$todayStringAlt2" (DD/MM/YYYY)');
    print('Total schedules: ${schedules.length}');

    // Print all schedule dates for debugging
    for (int i = 0; i < schedules.length; i++) {
      final scheduleData = schedules[i];
      print('Schedule $i:');
      print('  date: "${scheduleData['date']}"');
      print('  driver: "${scheduleData['driver']}"');
      print('  status: "${scheduleData['status']}"');
    }

    switch (_selectedFilter) {
      case 'Today':
        final todaySchedules = schedules.where((schedule) {
          final scheduleDate = schedule['date'] ?? '';
          print('\nChecking schedule date: "$scheduleDate"');

          if (scheduleDate.isEmpty) {
            print('  Empty date, skipping');
            return false;
          }

          // Try multiple format matches
          if (scheduleDate == todayString) {
            print('  ✅ Exact match with YYYY-MM-DD format');
            return true;
          }

          if (scheduleDate == todayStringAlt) {
            print('  ✅ Exact match with D/M/YYYY format');
            return true;
          }

          if (scheduleDate == todayStringAlt2) {
            print('  ✅ Exact match with DD/MM/YYYY format');
            return true;
          }

          // Try parsing the date and comparing
          try {
            DateTime? scheduleDateTime;

            // Try different parsing approaches
            if (scheduleDate.contains('-')) {
              // YYYY-MM-DD format
              scheduleDateTime = DateTime.parse(scheduleDate);
            } else if (scheduleDate.contains('/')) {
              // DD/MM/YYYY or D/M/YYYY format
              final parts = scheduleDate.split('/');
              if (parts.length == 3) {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                scheduleDateTime = DateTime(year, month, day);
              }
            }

            if (scheduleDateTime != null) {
              final todayStart = DateTime(now.year, now.month, now.day);
              final isSameDay =
                  scheduleDateTime.year == todayStart.year &&
                  scheduleDateTime.month == todayStart.month &&
                  scheduleDateTime.day == todayStart.day;

              print('  Parsed: schedule=$scheduleDateTime, today=$todayStart');
              print('  Same day: $isSameDay');

              if (isSameDay) {
                print('  ✅ Date parsing match!');
                return true;
              }
            }
          } catch (e) {
            print('  ❌ Error parsing date: $e');
          }

          print('  ❌ No match found');
          return false;
        }).toList();

        print('Found ${todaySchedules.length} schedules for TODAY');
        print('=== END DEBUG ===');
        return todaySchedules;

      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return schedules.where((schedule) {
          final scheduleDateString = schedule['date'] ?? '';
          if (scheduleDateString.isEmpty) return false;

          try {
            final scheduleDate = DateTime.parse(scheduleDateString);
            return scheduleDate.isAfter(
                  startOfWeek.subtract(const Duration(days: 1)),
                ) &&
                scheduleDate.isBefore(endOfWeek.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();

      case 'All':
      default:
        return schedules;
    }
  }

  Future<void> _markAsDone(Map<String, dynamic> schedule) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Done'),
          content: Text(
            'Are you sure you want to mark this truck schedule as completed?',
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
        print('Marking schedule as done: ${schedule['id']}');

        try {
          // Update status to completed in Firestore
          await FirebaseFirestore.instance
              .collection('truck_schedule')
              .doc(schedule['id'])
              .update({'status': 'completed', 'completedAt': Timestamp.now()});

          print('Successfully updated schedule status to completed');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the list to remove the completed schedule
          _loadAssignedSchedules();
        } catch (updateError) {
          print('Error updating schedule: $updateError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update schedule: $updateError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark schedule as done: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.purple;
      case 'inProgress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, int scheduleNumber) {
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
                          '$scheduleNumber',
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
                                schedule['status'] ?? 'scheduled',
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (schedule['status'] ?? 'scheduled').toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(
                                  schedule['status'] ?? 'scheduled',
                                ),
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
                                  Icons.local_shipping,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  schedule['truck'] ?? 'No truck',
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

                // Schedule info
                Text(
                  'Time: ${schedule['startTime'] ?? 'N/A'} - ${schedule['endTime'] ?? 'N/A'}',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSizes.paddingSmall),

                // Date and collector tags
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
                          Icon(Icons.people, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '${(schedule['collectors'] as List?)?.length ?? 0} Collectors',
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
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(schedule['date'] ?? ''),
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

                if ((schedule['streets'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSizes.paddingSmall),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingSmall),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Streets: ${(schedule['streets'] as List?)?.take(3).join(', ') ?? 'No streets assigned'}${(schedule['streets'] as List?)?.length != null && (schedule['streets'] as List).length > 3 ? ' +${(schedule['streets'] as List).length - 3} more' : ''}',
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
              Container(
                width: 50,
                height: 32,
                child: MaterialButton(
                  onPressed: () {
                    print(
                      'Done button pressed for schedule: ${schedule['id']}',
                    );
                    _markAsDone(schedule);
                  },
                  color: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 1,
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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
                    onPressed: _loadAssignedSchedules,
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
                      _loadAssignedSchedules();
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
                  : _assignedSchedules.isEmpty
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
                            'No Schedules Assigned',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'You don\'t have any truck schedules assigned for $_selectedFilter',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAssignedSchedules,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                        itemCount: _assignedSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _assignedSchedules[index];
                          return _buildScheduleCard(schedule, index + 1);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'No date';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
