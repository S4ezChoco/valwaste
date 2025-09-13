import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/schedule_service.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _upcomingSchedules = [];
  List<Map<String, dynamic>> _pastSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final upcoming = await ScheduleService.getUpcomingSchedules();
      final past = await ScheduleService.getPastSchedules();

      setState(() {
        _upcomingSchedules = upcoming;
        _pastSchedules = past;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading schedules: $e');
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
        backgroundColor: AppColors.primary,
        title: const Text(
          'My Schedules',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.upcoming),
              text: 'Upcoming (${_upcomingSchedules.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Past (${_pastSchedules.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleList(_upcomingSchedules, true),
          _buildScheduleList(_pastSchedules, false),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<Map<String, dynamic>> schedules, bool isUpcoming) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              isUpcoming ? 'No upcoming schedules' : 'No past schedules',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              isUpcoming
                  ? 'Your schedules will appear here'
                  : 'Your completed schedules will appear here',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return _buildScheduleCard(schedule, isUpcoming);
        },
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, bool isUpcoming) {
    final date = schedule['date'] ?? '';
    final truck = schedule['truck'] ?? 'No Truck';
    final startTime = schedule['startTime'] ?? '';
    final endTime = schedule['endTime'] ?? '';
    final streets = schedule['streets'] as List<dynamic>? ?? [];
    final wasteCollectors = schedule['wasteCollectors'] as List<dynamic>? ?? [];
    final location = schedule['location'];

    // Parse date for better display
    String formattedDate = date;
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final dateObj = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        formattedDate = '${months[dateObj.month - 1]} ${dateObj.day}, ${dateObj.year}';
        
        // Check if it's today
        final now = DateTime.now();
        if (dateObj.year == now.year && dateObj.month == now.month && dateObj.day == now.day) {
          formattedDate = 'Today';
        } else if (dateObj.year == now.year && 
                   dateObj.month == now.month && 
                   dateObj.day == now.day + 1) {
          formattedDate = 'Tomorrow';
        }
      }
    } catch (e) {
      // Keep original format if parsing fails
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: InkWell(
        onTap: () => _showScheduleDetails(schedule),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: isUpcoming ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusMedium),
                  topRight: Radius.circular(AppSizes.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUpcoming ? AppColors.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_shipping,
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
                          truck,
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: AppTextStyles.body2.copyWith(
                                color: isUpcoming && formattedDate == 'Today' 
                                    ? AppColors.primary 
                                    : AppColors.textSecondary,
                                fontWeight: formattedDate == 'Today' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '$startTime - $endTime',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (streets.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.route, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${streets.length} stops: ${streets.take(3).join(', ')}${streets.length > 3 ? '...' : ''}',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (wasteCollectors.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Team: ${wasteCollectors.join(', ')}',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (location != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDetails(Map<String, dynamic> schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['truck'] ?? 'No Truck',
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          schedule['date'] ?? '',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'Schedule Time',
                      Icons.access_time,
                      '${schedule['startTime']} - ${schedule['endTime']}',
                    ),
                    if (schedule['location'] != null)
                      _buildDetailSection(
                        'Location',
                        Icons.location_on,
                        schedule['location'],
                      ),
                    if (schedule['wasteCollectors'] != null && (schedule['wasteCollectors'] as List).isNotEmpty)
                      _buildDetailSection(
                        'Team Members',
                        Icons.people,
                        (schedule['wasteCollectors'] as List).join('\n'),
                      ),
                    if (schedule['streets'] != null && (schedule['streets'] as List).isNotEmpty) ...[
                      const SizedBox(height: AppSizes.paddingLarge),
                      Text(
                        'Route Stops (${(schedule['streets'] as List).length})',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      ...(schedule['streets'] as List).asMap().entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: AppTextStyles.body1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: AppSizes.paddingLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
