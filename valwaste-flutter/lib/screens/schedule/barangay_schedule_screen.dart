import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';

class BarangayScheduleScreen extends StatefulWidget {
  const BarangayScheduleScreen({super.key});

  @override
  State<BarangayScheduleScreen> createState() => _BarangayScheduleScreenState();
}

class _BarangayScheduleScreenState extends State<BarangayScheduleScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _scheduledCollections = [];
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScheduleData();
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleData() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) return;

      // Get barangay from user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.id)
          .get();
      final userData = userDoc.data();
      final barangay = userData?['barangay'] ?? 'Valenzuela City';

      // Load scheduled collections
      final scheduledCollections = await _firestore
          .collection('collections')
          .where('barangay', isEqualTo: barangay)
          .where('status', whereIn: ['approved', 'scheduled', 'inProgress'])
          .get();

      List<Map<String, dynamic>> collections = [];
      for (final doc in scheduledCollections.docs) {
        final data = doc.data();

        // Get user information
        final userDoc = await _firestore
            .collection('users')
            .doc(data['user_id'])
            .get();

        String userName = 'Unknown User';
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userName =
              userData['name'] ??
              userData['email'] ??
              userData['displayName'] ??
              'User ${data['user_id'].substring(0, 8)}';
        }

        collections.add({
          'id': doc.id,
          'residentName': userName,
          'address': data['address'] ?? 'No address',
          'wasteType': _getWasteTypeText(data['waste_type']),
          'quantity': data['quantity'] ?? 1,
          'unit': data['unit'] ?? 'bags',
          'scheduledDate': data['scheduled_date'],
          'status': _getStatusText(data['status']),
          'driverId': data['driver_id'],
          'createdAt': data['created_at'],
        });
      }

      // Sort by scheduled date
      collections.sort((a, b) {
        final aDate = _parseDate(a['scheduledDate']);
        final bDate = _parseDate(b['scheduledDate']);
        return aDate.compareTo(bDate);
      });

      setState(() {
        _scheduledCollections = collections;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading schedule data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReportsData() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) return;

      // Get barangay from user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.id)
          .get();
      final userData = userDoc.data();
      final barangay = userData?['barangay'] ?? 'Valenzuela City';

      // Generate reports data
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);

      // Load collections for reports
      final allCollections = await _firestore
          .collection('collections')
          .where('barangay', isEqualTo: barangay)
          .get();

      // Calculate statistics
      int totalCollections = allCollections.docs.length;
      int completedThisWeek = 0;
      int completedThisMonth = 0;
      int pendingRequests = 0;
      Map<String, int> wasteTypeStats = {};

      for (final doc in allCollections.docs) {
        final data = doc.data();
        final status = data['status'];
        final createdAt = _parseDate(data['created_at']);
        final wasteType = data['waste_type'] ?? 'general';

        // Count by status
        if (status == 'completed') {
          if (createdAt.isAfter(thisWeek)) completedThisWeek++;
          if (createdAt.isAfter(thisMonth)) completedThisMonth++;
        } else if (status == 'pending') {
          pendingRequests++;
        }

        // Count by waste type
        wasteTypeStats[wasteType] = (wasteTypeStats[wasteType] ?? 0) + 1;
      }

      setState(() {
        _reports = [
          {
            'title': 'Total Collections',
            'value': totalCollections.toString(),
            'icon': Icons.assignment,
            'color': Colors.blue,
          },
          {
            'title': 'Completed This Week',
            'value': completedThisWeek.toString(),
            'icon': Icons.check_circle,
            'color': Colors.green,
          },
          {
            'title': 'Completed This Month',
            'value': completedThisMonth.toString(),
            'icon': Icons.calendar_month,
            'color': Colors.purple,
          },
          {
            'title': 'Pending Requests',
            'value': pendingRequests.toString(),
            'icon': Icons.pending,
            'color': Colors.orange,
          },
        ];
      });
    } catch (e) {
      print('Error loading reports data: $e');
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.parse(date);
    if (date is Timestamp) return date.toDate();
    return DateTime.now();
  }

  String _getWasteTypeText(String wasteType) {
    switch (wasteType) {
      case 'general':
        return 'Regular Collection';
      case 'recyclable':
        return 'Recyclable Collection';
      case 'organic':
        return 'Organic Waste';
      case 'hazardous':
        return 'Hazardous Waste';
      case 'electronic':
        return 'Electronic Waste';
      default:
        return 'Waste Collection';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'scheduled':
        return 'Scheduled';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'scheduled':
        return Colors.purple;
      case 'in progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Schedule & Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Schedule', icon: Icon(Icons.schedule)),
            Tab(text: 'Reports', icon: Icon(Icons.analytics)),
            Tab(text: 'Statistics', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab(),
          _buildReportsTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedule Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 24),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Text(
                      'Collection Schedule',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Manage and monitor scheduled waste collections',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // Schedule List
          if (_scheduledCollections.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      'No scheduled collections',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      'Approved collection requests will appear here.',
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_scheduledCollections.length, (index) {
              final collection = _scheduledCollections[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
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
                        Expanded(
                          child: Text(
                            collection['residentName'],
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              collection['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(
                                collection['status'],
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            collection['status'],
                            style: AppTextStyles.body2.copyWith(
                              color: _getStatusColor(collection['status']),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      collection['address'],
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          collection['wasteType'],
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.schedule,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(collection['scheduledDate']),
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reports Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.white, size: 24),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Text(
                      'Collection Reports',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Overview of collection activities and performance',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // Reports Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSizes.paddingMedium,
            mainAxisSpacing: AppSizes.paddingMedium,
            childAspectRatio: 1.2,
            children: _reports
                .map((report) => _buildReportCard(report))
                .toList(),
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Recent Activity
          Text(
            'Recent Activity',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.paddingMedium),

          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  Icons.check_circle,
                  Colors.green,
                  'Collection completed',
                  'Regular waste collection at Brgy. Malinta',
                  '2 hours ago',
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.schedule,
                  Colors.blue,
                  'New collection scheduled',
                  'Recyclable waste collection at Brgy. Marulas',
                  '4 hours ago',
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.pending,
                  Colors.orange,
                  'Request pending approval',
                  'Hazardous waste collection at Brgy. Dalandanan',
                  '6 hours ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.white, size: 24),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Text(
                      'Collection Statistics',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Detailed analytics and performance metrics',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // Performance Metrics
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildMetricRow('Completion Rate', '95%', Colors.green),
                _buildMetricRow(
                  'Average Response Time',
                  '2.5 hours',
                  Colors.blue,
                ),
                _buildMetricRow(
                  'Customer Satisfaction',
                  '4.8/5',
                  Colors.orange,
                ),
                _buildMetricRow('Efficiency Score', '92%', Colors.purple),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // Waste Type Distribution
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waste Type Distribution',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildWasteTypeRow('Regular Waste', '45%', Colors.grey),
                _buildWasteTypeRow('Recyclable', '30%', Colors.blue),
                _buildWasteTypeRow('Organic', '20%', Colors.green),
                _buildWasteTypeRow('Hazardous', '5%', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSmall),
            decoration: BoxDecoration(
              color: report['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Icon(report['icon'], color: report['color'], size: 24),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            report['value'],
            style: AppTextStyles.heading2.copyWith(
              color: report['color'],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report['title'],
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    Color color,
    String title,
    String description,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTypeRow(String type, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(child: Text(type, style: AppTextStyles.body1)),
          Text(
            percentage,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    final dateTime = _parseDate(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
