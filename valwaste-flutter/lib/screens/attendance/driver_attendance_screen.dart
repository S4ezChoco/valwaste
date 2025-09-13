import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/schedule_service.dart';
import '../../services/attendance_service.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  State<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _schedules = [];
  Map<String, dynamic>? _selectedSchedule;
  Map<String, dynamic>? _activeAttendance;
  bool _isLoading = true;
  bool _isProcessing = false;

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
      // Load schedules
      final schedules = await ScheduleService.getUpcomingSchedules();
      
      // Load active attendance
      final user = _auth.currentUser;
      if (user != null) {
        final activeAttendance = await AttendanceService.getActiveAttendance(user.uid);
        if (activeAttendance != null) {
          setState(() {
            _activeAttendance = activeAttendance.data() as Map<String, dynamic>?;
          });
        }
      }

      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a schedule first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get team members from schedule
      final wasteCollectors = _selectedSchedule!['wasteCollectors'] as List<dynamic>? ?? [];
      final teamMembers = wasteCollectors.map((collector) => {
        'name': collector.toString(),
        'role': 'Waste Collector',
      }).toList();

      // Create attendance record
      await AttendanceService.checkIn(
        location: _selectedSchedule!['location'] ?? 'Valenzuela City',
        notes: 'Schedule: ${_selectedSchedule!['truck']} - ${_selectedSchedule!['date']} - ID: ${_selectedSchedule!['id']}',
        teamMembers: teamMembers.cast<Map<String, String>>(),
      );

      // Update attendance in admin panel format
      await _firestore.collection('attendance').add({
        'userId': _auth.currentUser!.uid,
        'userName': (await _firestore.collection('users').doc(_auth.currentUser!.uid).get()).data()?['name'] ?? '',
        'checkIn': Timestamp.now(),
        'checkOut': null,
        'date': _selectedSchedule!['date'],
        'scheduleId': _selectedSchedule!['id'],
        'truck': _selectedSchedule!['truck'],
        'route': (_selectedSchedule!['streets'] as List<dynamic>? ?? []).join(', '),
        'teamMembers': teamMembers,
        'status': 'Checked In',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkOut() async {
    if (_activeAttendance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active attendance to check out'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get active attendance record
      final activeAttendance = await AttendanceService.getActiveAttendance(_auth.currentUser!.uid);
      
      if (activeAttendance != null) {
        // Update mobile app attendance
        await AttendanceService.checkOut(
          attendanceId: activeAttendance.id,
          notes: 'Shift completed',
        );

        // Update admin panel attendance
        final attendanceQuery = await _firestore
            .collection('attendance')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .where('checkOut', isEqualTo: null)
            .limit(1)
            .get();

        if (attendanceQuery.docs.isNotEmpty) {
          await attendanceQuery.docs.first.reference.update({
            'checkOut': Timestamp.now(),
            'status': 'Completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked out successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _activeAttendance != null ? 'Check Out' : 'Check In',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeAttendance != null
              ? _buildCheckOutView()
              : _buildCheckInView(),
    );
  }

  Widget _buildCheckInView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          color: Colors.blue.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Text(
                  'Select a schedule to check in',
                  style: AppTextStyles.body1.copyWith(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _schedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        'No schedules available',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        'Contact admin to assign schedules',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _schedules[index];
                    final isSelected = _selectedSchedule?['id'] == schedule['id'];
                    final date = schedule['date'] ?? '';
                    final truck = schedule['truck'] ?? 'No Truck';
                    final startTime = schedule['startTime'] ?? '';
                    final endTime = schedule['endTime'] ?? '';
                    final streets = schedule['streets'] as List<dynamic>? ?? [];
                    final wasteCollectors = schedule['wasteCollectors'] as List<dynamic>? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSchedule = schedule;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.local_shipping,
                                      color: AppColors.primary,
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
                                        Text(
                                          date,
                                          style: AppTextStyles.body2.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.paddingMedium),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$startTime - $endTime',
                                      style: AppTextStyles.body2.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (streets.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.paddingSmall),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.route, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Routes: ${streets.join(', ')}',
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
                              if (wasteCollectors.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.paddingSmall),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Team: ${wasteCollectors.join(', ')}',
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
                              if (schedule['location'] != null) ...[
                                const SizedBox(height: AppSizes.paddingSmall),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        schedule['location'],
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing || _selectedSchedule == null ? null : _checkIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Check In',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckOutView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Text(
                  'You are currently checked in',
                  style: AppTextStyles.body1.copyWith(color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_user,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                Text(
                  'Active Shift',
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                if (_activeAttendance != null) ...[
                  Text(
                    'Check-in Time: ${_formatTime(_activeAttendance!['checkIn'])}',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_activeAttendance!['location'] != null) ...[
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _activeAttendance!['location'],
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _checkOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Check Out',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'N/A';
    }
    
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
