import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/enhanced_notification_service.dart';
import '../../models/user.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/barangay_notification_card.dart';
import '../schedule/barangay_schedule_screen.dart';

class BarangayOfficialDashboardScreen extends StatefulWidget {
  const BarangayOfficialDashboardScreen({super.key});

  @override
  State<BarangayOfficialDashboardScreen> createState() =>
      _BarangayOfficialDashboardScreenState();
}

class _BarangayOfficialDashboardScreenState
    extends State<BarangayOfficialDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _stats = {
    'pending_requests': 0,
    'todays_collections': 0,
    'active_drivers': 0,
    'routes_today': 0,
  };
  List<Map<String, dynamic>> _recentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    // Listen to real-time collection updates
    _firestore.collection('collections').snapshots().listen((snapshot) {
      if (mounted) {
        _loadDashboardData(); // Refresh data when collections change
      }
    });

    // Listen to real-time user updates (for driver count)
    _firestore.collection('users').snapshots().listen((snapshot) {
      if (mounted) {
        _loadDashboardData(); // Refresh data when users change
      }
    });
  }

  Future<void> _loadDashboardData() async {
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

      // Load pending requests for this barangay
      // Get ALL pending requests to show all requests for approval
      final pendingRequests = await _firestore
          .collection('collections')
          .where('status', isEqualTo: 'pending')
          .get();

      // Load today's collections (simplified query)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all collections and filter in memory to avoid index requirements
      final allCollections = await _firestore
          .collection('collections')
          .where('barangay', isEqualTo: barangay)
          .get();

      final todaysCollections = allCollections.docs.where((doc) {
        final data = doc.data();
        final scheduledDate = data['scheduled_date'];
        if (scheduledDate == null) return false;

        DateTime collectionDate;
        if (scheduledDate is String) {
          collectionDate = DateTime.parse(scheduledDate);
        } else if (scheduledDate is Timestamp) {
          collectionDate = scheduledDate.toDate();
        } else {
          return false;
        }

        return collectionDate.isAfter(startOfDay) &&
            collectionDate.isBefore(endOfDay);
      }).toList();

      // Load active drivers
      final activeDrivers = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .get();

      // Load routes today (collections with drivers assigned) - simplified query
      final routesToday = allCollections.docs.where((doc) {
        final data = doc.data();
        final scheduledDate = data['scheduled_date'];
        final status = data['status'];

        if (scheduledDate == null || status == null) return false;

        DateTime collectionDate;
        if (scheduledDate is String) {
          collectionDate = DateTime.parse(scheduledDate);
        } else if (scheduledDate is Timestamp) {
          collectionDate = scheduledDate.toDate();
        } else {
          return false;
        }

        return collectionDate.isAfter(startOfDay) &&
            collectionDate.isBefore(endOfDay) &&
            (status == 'scheduled' || status == 'inProgress');
      }).toList();

      // Load recent requests
      await _loadRecentRequests(barangay);

      setState(() {
        _stats = {
          'pending_requests': pendingRequests.docs.length,
          'todays_collections': todaysCollections.length,
          'active_drivers': activeDrivers.docs.length,
          'routes_today': routesToday.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentRequests(String barangay) async {
    try {
      // Get recent collections for this barangay (simplified query)
      // Get all collections to show all requests
      final recentCollections = await _firestore
          .collection('collections')
          .get();

      List<Map<String, dynamic>> requests = [];

      for (final doc in recentCollections.docs) {
        final data = doc.data();

        // Show ALL requests regardless of barangay for approval

        // Get user information
        final userDoc = await _firestore
            .collection('users')
            .doc(data['user_id'])
            .get();

        // Get user name with fallbacks
        String userName;
        String userInitials;

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userName =
              userData['name'] ??
              userData['email'] ??
              userData['displayName'] ??
              'User ${data['user_id'].substring(0, 8)}';
        } else {
          // User document doesn't exist, use user ID as fallback
          userName = 'User ${data['user_id'].substring(0, 8)}';
        }

        userInitials = _getInitials(userName);
        final statusText = _getStatusText(data['status']);

        requests.add({
          'id': doc.id,
          'residentName': userName,
          'address': data['address'] ?? 'No address',
          'requestType': _getWasteTypeText(data['waste_type']),
          'status': statusText,
          'time': _getTimeAgo(data['created_at']),
          'avatar': userInitials,
          'wasteType': data['waste_type'],
          'quantity': data['quantity'],
          'unit': data['unit'],
          'createdAt': data['created_at'],
        });
      }

      // Sort by creation date in memory (most recent first) and limit to 10
      requests.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        DateTime aDate, bDate;
        if (aTime is String) {
          aDate = DateTime.parse(aTime);
        } else if (aTime is Timestamp) {
          aDate = aTime.toDate();
        } else {
          return 0;
        }

        if (bTime is String) {
          bDate = DateTime.parse(bTime);
        } else if (bTime is Timestamp) {
          bDate = bTime.toDate();
        } else {
          return 0;
        }

        return bDate.compareTo(aDate); // Descending order (newest first)
      });

      // Limit to 10 most recent
      if (requests.length > 10) {
        requests = requests.take(10).toList();
      }

      setState(() {
        _recentRequests = requests;
      });
    } catch (e) {
      print('Error loading recent requests: $e');
    }
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
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
        return 'Pending Approval';
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

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Unknown time';

    DateTime createdTime;
    if (createdAt is String) {
      createdTime = DateTime.parse(createdAt);
    } else if (createdAt is Timestamp) {
      createdTime = createdAt.toDate();
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(createdTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Approve a collection request
  Future<void> _approveCollectionRequest(String collectionId) async {
    try {
      await _firestore.collection('collections').doc(collectionId).update({
        'status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
        'approved_by': FirebaseAuthService.currentUser?.id,
      });

      // Get collection details for notification
      final doc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final wasteType = data['waste_type'];
        final address = data['address'];
        final userId = data['user_id'];

        // Notify the resident
        await EnhancedNotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Collection Request Approved',
          message:
              'Your $wasteType collection request at $address has been approved!',
          type: 'approval',
          data: {'collection_id': collectionId, 'status': 'approved'},
        );

        // Notify drivers about the new approved collection
        await _notifyDriversAboutApprovedCollection(collectionId, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection request approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData(); // Refresh data
      }
    } catch (e) {
      print('Error approving collection request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Decline a collection request
  Future<void> _declineCollectionRequest(String collectionId) async {
    try {
      await _firestore.collection('collections').doc(collectionId).update({
        'status': 'cancelled',
        'declined_at': DateTime.now().toIso8601String(),
        'declined_by': FirebaseAuthService.currentUser?.id,
      });

      // Get collection details for notification
      final doc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final wasteType = data['waste_type'];
        final address = data['address'];
        final userId = data['user_id'];

        // Notify the resident
        await EnhancedNotificationService.sendNotificationToUser(
          userId: userId,
          title: 'Collection Request Declined',
          message:
              'Your $wasteType collection request at $address has been declined. Please contact barangay office for more information.',
          type: 'decline',
          data: {'collection_id': collectionId, 'status': 'cancelled'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection request declined.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadDashboardData(); // Refresh data
      }
    } catch (e) {
      print('Error declining collection request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Notify drivers about approved collection
  Future<void> _notifyDriversAboutApprovedCollection(
    String collectionId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Get all drivers
      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();

      for (final doc in driversSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Approved Collection',
          message:
              'New ${data['waste_type']} collection approved at ${data['address']}',
          type: 'approved_collection',
          data: {
            'collection_id': collectionId,
            'waste_type': data['waste_type'],
            'address': data['address'],
            'quantity': data['quantity'].toString(),
            'scheduled_date': data['scheduled_date'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
          },
        );
      }
    } catch (e) {
      print('Error notifying drivers: $e');
    }
  }

  // Show collection request management interface
  void _showCollectionRequestManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    'Collection Request Management',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _recentRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          Text(
                            'No collection requests',
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'Collection requests from residents will appear here.',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: _recentRequests.length,
                      itemBuilder: (context, index) {
                        final request = _recentRequests[index];
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: AppSizes.paddingSmall,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                request['avatar'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              request['residentName'],
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(request['address']),
                                Text(request['requestType']),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(request['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request['status'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request['time'],
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _showRequestDetails(context, request);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'in progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resident: ${request['residentName']}'),
            Text('Address: ${request['address']}'),
            Text('Type: ${request['requestType']}'),
            Text('Status: ${request['status']}'),
            Text('Time: ${request['time']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if ((request['status'] == 'Pending Approval' ||
                  request['status'] == 'Pending') &&
              request['id'] != null) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveCollectionRequest(request['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _declineCollectionRequest(request['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Decline'),
            ),
          ],
        ],
      ),
    );
  }

  // Show schedule management interface
  void _showScheduleManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BarangayScheduleScreen()),
    );
  }

  // Show notification management interface
  void _showNotificationManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notifications'),
        content: const Text(
          'Notification management feature will be implemented here.\n\nThis will allow barangay officials to:\n• Send announcements to residents\n• Alert about schedule changes\n• Notify about collection updates\n• Send emergency notifications',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            currentUser?.name ?? 'Barangay Official',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Barangay Official',
                              style: AppTextStyles.body2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingSmall),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Latest Announcement Card
              LatestAnnouncementCard(),

              // Collection Request Notifications
              BarangayNotificationCard(),

              const SizedBox(height: AppSizes.paddingLarge),

              // Enhanced Statistics Cards
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _EnhancedStatCard(
                        title: 'Pending Requests',
                        value: '${_stats['pending_requests']}',
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _EnhancedStatCard(
                        title: 'Today\'s Collections',
                        value: '${_stats['todays_collections']}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingMedium),

                Row(
                  children: [
                    Expanded(
                      child: _EnhancedStatCard(
                        title: 'Active Drivers',
                        value: '${_stats['active_drivers']}',
                        icon: Icons.local_shipping,
                        color: Colors.blue,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _EnhancedStatCard(
                        title: 'Routes Today',
                        value: '${_stats['routes_today']}',
                        icon: Icons.route,
                        color: Colors.purple,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSizes.paddingLarge),

              // Enhanced Quick Actions Section
              Row(
                children: [
                  Icon(Icons.flash_on, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Enhanced Action Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.paddingMedium,
                mainAxisSpacing: AppSizes.paddingMedium,
                childAspectRatio: 1.1,
                children: [
                  _EnhancedActionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Review Requests',
                    subtitle: 'Manage collection requests',
                    color: AppColors.primary,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    onTap: () {
                      // Navigate to collection request management (view only)
                      _showCollectionRequestManagement(context);
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Reports',
                    subtitle: 'View collection reports',
                    color: Colors.blue,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    onTap: () {
                      _showScheduleManagement(context);
                    },
                  ),
                  _EnhancedActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Send Notifications',
                    subtitle: 'Alert residents',
                    color: Colors.red,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    onTap: () {
                      _showNotificationManagement(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Enhanced Recent Requests Section
              Row(
                children: [
                  Icon(Icons.history, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    'Recent Requests',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      final currentUser = FirebaseAuthService.currentUser;
                      if (currentUser != null) {
                        final userDoc = await _firestore
                            .collection('users')
                            .doc(currentUser.id)
                            .get();
                        final userData = userDoc.data();
                        final barangay =
                            userData?['barangay'] ?? 'Valenzuela City';
                        await _loadRecentRequests(barangay);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Requests',
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Enhanced Request Cards - Real Data
              if (_recentRequests.isEmpty)
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
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          'No recent requests',
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          'Requests will appear here when residents submit collection requests.',
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
                ...List.generate(
                  _recentRequests.length > 3 ? 3 : _recentRequests.length,
                  (index) {
                    final request = _recentRequests[index];
                    return Column(
                      children: [
                        _EnhancedRequestCard(
                          residentName: request['residentName'],
                          address: request['address'],
                          requestType: request['requestType'],
                          status: request['status'],
                          time: request['time'],
                          avatar: request['avatar'],
                          collectionId: request['id'],
                          onApprove:
                              (request['status'] == 'Pending Approval' ||
                                      request['status'] == 'Pending') &&
                                  request['id'] != null
                              ? () => _approveCollectionRequest(request['id'])
                              : null,
                          onDecline:
                              (request['status'] == 'Pending Approval' ||
                                      request['status'] == 'Pending') &&
                                  request['id'] != null
                              ? () => _declineCollectionRequest(request['id'])
                              : null,
                        ),
                        if (index < 2)
                          const SizedBox(height: AppSizes.paddingSmall),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const _EnhancedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _EnhancedActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedRequestCard extends StatelessWidget {
  final String residentName;
  final String address;
  final String requestType;
  final String status;
  final String time;
  final String avatar;
  final String? collectionId;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const _EnhancedRequestCard({
    required this.residentName,
    required this.address,
    required this.requestType,
    required this.status,
    required this.time,
    required this.avatar,
    this.collectionId,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                avatar,
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        residentName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: AppTextStyles.body2.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  address,
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
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      requestType,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Approval buttons for pending requests
                if ((status == 'Pending Approval' || status == 'Pending') &&
                    onApprove != null &&
                    onDecline != null) ...[
                  const SizedBox(height: AppSizes.paddingSmall),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: AppTextStyles.body2.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDecline,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: AppTextStyles.body2.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}
