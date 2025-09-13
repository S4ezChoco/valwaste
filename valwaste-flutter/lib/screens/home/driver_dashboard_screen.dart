import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/location_service.dart';
import '../../services/attendance_service.dart';
import '../schedule/schedule_screen.dart';
import '../map/map_screen.dart';
// Removed unused imports for now - will add back when implementing photo features

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isRouteActive = false;
  Map<String, dynamic>? _todaySchedule;
  Map<String, dynamic>? _todayAttendance;
  List<Map<String, dynamic>> _nextStops = [];
  int _completedStops = 0;
  int _totalStops = 0;
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTodaySchedule();
    await _loadTodayAttendance();
    await _loadStops();
  }

  Future<void> _loadTodaySchedule() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final driverName = userDoc.data()?['name'] ?? '';

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final scheduleQuery = await _firestore
        .collection('truck_schedule')
        .where('date', isEqualTo: todayString)
        .where('driver', isEqualTo: driverName)
        .get();

    if (scheduleQuery.docs.isNotEmpty && mounted) {
      setState(() {
        _todaySchedule = scheduleQuery.docs.first.data();
      });
    }
  }

  Future<void> _loadTodayAttendance() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final attendance = await AttendanceService.getTodayAttendance(user.uid);
    if (attendance != null && mounted) {
      setState(() {
        _todayAttendance = attendance.data() as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _loadStops() async {
    if (_todaySchedule == null) return;

    final streets = _todaySchedule!['streets'] as List<dynamic>? ?? [];
    setState(() {
      _totalStops = streets.length;
      _nextStops = streets.map((street) => {
        'address': street,
        'status': 'Pending',
        'wasteType': 'Regular',
      }).toList();
    });
  }

  Future<void> _toggleRoute() async {
    try {
      if (_isRouteActive) {
        await LocationService.stopLocationTracking();
        setState(() {
          _isRouteActive = false;
        });
      } else {
        // Check location permission first
        final hasPermission = await LocationService.isLocationServiceEnabled();
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services to start route'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        await LocationService.startLocationTracking();
        setState(() {
          _isRouteActive = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markStopComplete(int index) {
    setState(() {
      _nextStops[index]['status'] = 'Completed';
      _completedStops++;
    });
  }

  Future<void> _checkIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    try {
      // Get team members from schedule
      final wasteCollectors = _todaySchedule?['wasteCollectors'] as List<dynamic>? ?? [];
      final teamMembers = wasteCollectors.map((collector) => {
        'name': collector.toString(),
        'role': 'Waste Collector',
      }).toList();

      // Check in
      await AttendanceService.checkIn(
        location: 'Valenzuela City',
        notes: 'Started shift',
        teamMembers: teamMembers.cast<Map<String, String>>(),
      );

      await _loadTodayAttendance();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checked in successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingIn = false;
      });
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      if (_todayAttendance != null) {
        // Get the document ID from the attendance record
        final activeAttendance = await AttendanceService.getActiveAttendance(_auth.currentUser!.uid);
        
        if (activeAttendance != null) {
          await AttendanceService.checkOut(
            attendanceId: activeAttendance.id,
            notes: 'Ended shift',
          );

          await _loadTodayAttendance();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checked out successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active attendance record found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-out failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthService.currentUser;
    final hasSchedule = _todaySchedule != null;
    final efficiency = _totalStops > 0 ? (_completedStops / _totalStops * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.local_shipping,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            currentUser?.name ?? 'Driver',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Today's Stats
                if (hasSchedule) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Today\'s Stops',
                          value: _totalStops.toString(),
                          icon: Icons.location_on,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: _StatCard(
                          title: 'Completed',
                          value: _completedStops.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.paddingMedium),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Remaining',
                          value: (_totalStops - _completedStops).toString(),
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: _StatCard(
                          title: 'Efficiency',
                          value: '$efficiency%',
                          icon: Icons.trending_up,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: AppSizes.paddingMedium),
                        Expanded(
                          child: Text(
                            'No schedule assigned for today',
                            style: AppTextStyles.body1.copyWith(
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Current Route
                if (hasSchedule) ...[
                  Text(
                    'Current Route',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.route,
                              color: _isRouteActive ? Colors.green : AppColors.primary,
                            ),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Expanded(
                              child: Text(
                                '${_todaySchedule!['truck'] ?? 'Truck'} - ${_todaySchedule!['startTime']} to ${_todaySchedule!['endTime']}',
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_isRouteActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        if (_nextStops.isNotEmpty)
                          Text(
                            'Next stop: ${_nextStops.firstWhere((s) => s['status'] == 'Pending', orElse: () => {'address': 'All completed'})['address']}',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        LinearProgressIndicator(
                          value: _totalStops > 0 ? _completedStops / _totalStops : 0,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          '${(_totalStops > 0 ? (_completedStops / _totalStops * 100).toInt() : 0)}% Complete',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.paddingLarge),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),

                // Action Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.paddingMedium,
                  mainAxisSpacing: AppSizes.paddingMedium,
                  childAspectRatio: 1.2,
                  children: [
                    _ActionCard(
                      icon: Icons.map_outlined,
                      title: 'View Route',
                      subtitle: 'See today\'s route',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                      },
                    ),
                    if (_todayAttendance != null && _todayAttendance!['checkOut'] == null)
                      _ActionCard(
                        icon: Icons.logout,
                        title: 'Check Out',
                        subtitle: 'End your shift',
                        color: Colors.red,
                        isLoading: _isCheckingOut,
                        onTap: _isCheckingOut ? null : _checkOut,
                      )
                    else if (_todayAttendance == null)
                      _ActionCard(
                        icon: Icons.login,
                        title: 'Check In',
                        subtitle: 'Start your shift',
                        color: Colors.green,
                        isLoading: _isCheckingIn,
                        onTap: _isCheckingIn ? null : _checkIn,
                      )
                    else
                      _ActionCard(
                        icon: Icons.check_circle,
                        title: 'Completed',
                        subtitle: 'Shift completed',
                        color: Colors.grey,
                        onTap: null,
                      ),
                    _ActionCard(
                      icon: Icons.schedule_outlined,
                      title: 'Schedule',
                      subtitle: 'View collection schedule',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScheduleScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_problem_outlined,
                      title: 'Report Issue',
                      subtitle: 'Report problems',
                      color: Colors.red,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report feature coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                    if (hasSchedule && !_isRouteActive)
                      _ActionCard(
                        icon: Icons.location_on_outlined,
                        title: 'Start Route',
                        subtitle: 'Begin collection route',
                        color: Colors.blue,
                        onTap: _toggleRoute,
                      )
                    else if (_isRouteActive)
                      _ActionCard(
                        icon: Icons.stop_outlined,
                        title: 'End Route',
                        subtitle: 'Finish collection route',
                        color: Colors.grey,
                        onTap: _toggleRoute,
                      )
                    else
                      _ActionCard(
                        icon: Icons.location_off,
                        title: 'No Route',
                        subtitle: 'No schedule today',
                        color: Colors.grey,
                        onTap: null,
                      ),
                    _ActionCard(
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'View past routes',
                      color: Colors.purple,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('History feature coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Next Stops
                if (hasSchedule && _nextStops.isNotEmpty) ...[
                  Text(
                    'Next Stops',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Stop Cards
                  ..._nextStops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                      child: _StopCard(
                        address: stop['address'],
                        time: _calculateStopTime(index),
                        wasteType: stop['wasteType'],
                        status: stop['status'],
                        onComplete: stop['status'] == 'Pending'
                            ? () => _markStopComplete(index)
                            : null,
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateStopTime(int index) {
    if (_todaySchedule == null) return '';
    
    final startTime = _todaySchedule!['startTime'] as String? ?? '08:00';
    final timeParts = startTime.split(':');
    final startHour = int.parse(timeParts[0]);
    final startMinute = int.parse(timeParts[1]);
    
    // Assume 20 minutes per stop
    final totalMinutes = startHour * 60 + startMinute + (index * 20);
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSizes.paddingSmall),
              Text(
                title,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
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
              if (isLoading)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: 32, color: color),
              const SizedBox(height: AppSizes.paddingSmall),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final String address;
  final String time;
  final String wasteType;
  final String status;
  final VoidCallback? onComplete;

  const _StopCard({
    required this.address,
    required this.time,
    required this.wasteType,
    required this.status,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$wasteType • $time',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onComplete != null)
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: onComplete,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: status == 'Pending' ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
