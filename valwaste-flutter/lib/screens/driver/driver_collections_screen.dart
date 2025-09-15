import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../utils/barangay_data.dart';
import '../../models/waste_collection.dart';
import '../../services/collection_approval_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/attendance_service.dart';

class DriverCollectionsScreen extends StatefulWidget {
  const DriverCollectionsScreen({super.key});

  @override
  State<DriverCollectionsScreen> createState() =>
      _DriverCollectionsScreenState();
}

class _DriverCollectionsScreenState extends State<DriverCollectionsScreen> {
  List<WasteCollection> _assignedCollections = [];
  bool _isLoading = true;

  // Attendance tracking
  bool _isShiftActive = false;
  DateTime? _shiftStartTime;
  String? _driverName;
  String? _truckInfo;
  String? _plateNumber;
  File? _startSelfie;
  File? _endSelfie;
  String? _attendanceId; // Track the attendance record ID
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _shiftTimer;

  // Schedule tracking
  Map<String, dynamic>? _todaySchedule;
  bool _hasSchedule = false;

  @override
  void initState() {
    super.initState();
    _initializeAttendance();
    _loadAssignedCollections();
    _checkForActiveShift();
    _loadTodaySchedule();
  }

  /// Initialize attendance collection in Firebase
  Future<void> _initializeAttendance() async {
    await AttendanceService.initializeAttendanceCollection();
  }

  /// Load today's schedule from Firebase
  Future<void> _loadTodaySchedule() async {
    try {
      print('🔄 Loading today\'s schedule...');
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) return;

      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('🔄 Looking for schedule for date: $todayString');
      print('🔄 Driver ID: ${currentUser.id}');

      // Query scheduled collections for today - use same logic as getDriverAssignments
      print('🔄 Querying for scheduled collections...');

      // First, let's see what collections exist for this driver using the correct collection name
      final allCollectionsSnapshot = await FirebaseFirestore.instance
          .collection('collections')
          .where('assigned_to', isEqualTo: currentUser.id)
          .get();

      print(
        '🔄 Found ${allCollectionsSnapshot.docs.length} total collections for driver (collections.assigned_to)',
      );

      // Print all collections for debugging
      for (var doc in allCollectionsSnapshot.docs) {
        final data = doc.data();
        print(
          '🔄 Collection ${doc.id}: status=${data['status']}, scheduledDate=${data['scheduledDate']}, assigned_to=${data['assigned_to']}',
        );
      }

      // Try different field name combinations
      QuerySnapshot? querySnapshot;

      // Try 1: scheduledDate field with correct collection and field names - check multiple statuses
      try {
        // First try 'scheduled' status
        querySnapshot = await FirebaseFirestore.instance
            .collection('collections')
            .where('status', isEqualTo: 'scheduled')
            .where('assigned_to', isEqualTo: currentUser.id)
            .where('scheduledDate', isEqualTo: todayString)
            .limit(1)
            .get();
        print(
          '🔄 Query 1a (collections.scheduledDate, status=scheduled): Found ${querySnapshot.docs.length} results',
        );

        // If no results, try 'approved' status
        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await FirebaseFirestore.instance
              .collection('collections')
              .where('status', isEqualTo: 'approved')
              .where('assigned_to', isEqualTo: currentUser.id)
              .where('scheduledDate', isEqualTo: todayString)
              .limit(1)
              .get();
          print(
            '🔄 Query 1b (collections.scheduledDate, status=approved): Found ${querySnapshot.docs.length} results',
          );
        }

        // If still no results, try any status with scheduledDate
        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await FirebaseFirestore.instance
              .collection('collections')
              .where('assigned_to', isEqualTo: currentUser.id)
              .where('scheduledDate', isEqualTo: todayString)
              .limit(1)
              .get();
          print(
            '🔄 Query 1c (collections.scheduledDate, any status): Found ${querySnapshot.docs.length} results',
          );
        }
      } catch (e) {
        print('🔄 Query 1 failed: $e');
      }

      // Try 2: scheduled_date field (snake_case) with correct collection - check multiple statuses
      if (querySnapshot == null || querySnapshot.docs.isEmpty) {
        try {
          // First try 'scheduled' status
          querySnapshot = await FirebaseFirestore.instance
              .collection('collections')
              .where('status', isEqualTo: 'scheduled')
              .where('assigned_to', isEqualTo: currentUser.id)
              .where('scheduled_date', isEqualTo: todayString)
              .limit(1)
              .get();
          print(
            '🔄 Query 2a (collections.scheduled_date, status=scheduled): Found ${querySnapshot.docs.length} results',
          );

          // If no results, try 'approved' status
          if (querySnapshot.docs.isEmpty) {
            querySnapshot = await FirebaseFirestore.instance
                .collection('collections')
                .where('status', isEqualTo: 'approved')
                .where('assigned_to', isEqualTo: currentUser.id)
                .where('scheduled_date', isEqualTo: todayString)
                .limit(1)
                .get();
            print(
              '🔄 Query 2b (collections.scheduled_date, status=approved): Found ${querySnapshot.docs.length} results',
            );
          }

          // If still no results, try any status with scheduled_date
          if (querySnapshot.docs.isEmpty) {
            querySnapshot = await FirebaseFirestore.instance
                .collection('collections')
                .where('assigned_to', isEqualTo: currentUser.id)
                .where('scheduled_date', isEqualTo: todayString)
                .limit(1)
                .get();
            print(
              '🔄 Query 2c (collections.scheduled_date, any status): Found ${querySnapshot.docs.length} results',
            );
          }
        } catch (e) {
          print('🔄 Query 2 failed: $e');
        }
      }

      // Try 3: date field with correct collection
      if (querySnapshot == null || querySnapshot.docs.isEmpty) {
        try {
          querySnapshot = await FirebaseFirestore.instance
              .collection('collections')
              .where('status', isEqualTo: 'scheduled')
              .where('assigned_to', isEqualTo: currentUser.id)
              .where('date', isEqualTo: todayString)
              .limit(1)
              .get();
          print(
            '🔄 Query 3 (collections.date): Found ${querySnapshot.docs.length} results',
          );
        } catch (e) {
          print('🔄 Query 3 failed: $e');
        }
      }

      // Try 4: Just get any scheduled collections for this driver (no date filter)
      if (querySnapshot == null || querySnapshot.docs.isEmpty) {
        try {
          querySnapshot = await FirebaseFirestore.instance
              .collection('collections')
              .where('status', isEqualTo: 'scheduled')
              .where('assigned_to', isEqualTo: currentUser.id)
              .limit(1)
              .get();
          print(
            '🔄 Query 4 (collections, no date filter): Found ${querySnapshot.docs.length} results',
          );
        } catch (e) {
          print('🔄 Query 4 failed: $e');
        }
      }

      // Try 5: Get any collections for this driver regardless of status (for debugging)
      if (querySnapshot == null || querySnapshot.docs.isEmpty) {
        try {
          querySnapshot = await FirebaseFirestore.instance
              .collection('collections')
              .where('assigned_to', isEqualTo: currentUser.id)
              .limit(5) // Get more records for debugging
              .get();
          print(
            '🔄 Query 5 (collections, any status): Found ${querySnapshot.docs.length} results',
          );

          // If we found collections, check their status and dates
          if (querySnapshot.docs.isNotEmpty) {
            for (var doc in querySnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>?;
              final status = data?['status'] as String?;
              final scheduledDate = data?['scheduledDate'] as String?;
              final scheduled_date = data?['scheduled_date'] as String?;
              final date = data?['date'] as String?;
              print(
                '🔄 Collection ${doc.id}: status=$status, scheduledDate=$scheduledDate, scheduled_date=$scheduled_date, date=$date',
              );

              // Check if any date field matches today
              final hasTodayDate =
                  scheduledDate == todayString ||
                  scheduled_date == todayString ||
                  date == todayString;

              // If it's approved or scheduled and has today's date, treat it as a valid schedule
              if ((status == 'approved' || status == 'scheduled') &&
                  hasTodayDate) {
                print(
                  '🔄 Found valid schedule: Collection ${doc.id} with status $status and today\'s date',
                );
                // Create a new query snapshot with just this document
                querySnapshot = await FirebaseFirestore.instance
                    .collection('collections')
                    .where(FieldPath.documentId, isEqualTo: doc.id)
                    .limit(1)
                    .get();
                break;
              }
            }

            // If no valid schedule found, reset to null
            if (querySnapshot != null && querySnapshot.docs.isEmpty) {
              print('🔄 No valid schedule found for today');
              querySnapshot = null;
            }
          }
        } catch (e) {
          print('🔄 Query 5 failed: $e');
        }
      }

      if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
        final scheduleData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _todaySchedule = scheduleData;
          _hasSchedule = true;
        });
        print(
          '✅ Found today\'s schedule: ${scheduleData['scheduledDate'] ?? scheduleData['scheduled_date'] ?? scheduleData['date'] ?? 'No date field'}',
        );
        print('🔄 Schedule details: ${scheduleData.toString()}');
      } else {
        setState(() {
          _todaySchedule = null;
          _hasSchedule = false;
        });
        print('❌ No schedule found for today');
      }
    } catch (e) {
      print('Error loading today\'s schedule: $e');
      setState(() {
        _todaySchedule = null;
        _hasSchedule = false;
      });
    }
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAssignedCollections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assignments =
          await CollectionApprovalService.getDriverAssignments();
      setState(() {
        _assignedCollections = assignments;
        _isLoading = false;
      });

      // Check for active shift after loading collections
      _checkForActiveShift();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assignments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startCollection(WasteCollection collection) async {
    // Show attendance modal first
    final attendanceData = await _showAttendanceModal();

    if (attendanceData != null) {
      // Start the collection
      final result = await CollectionApprovalService.startCollection(
        collection.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success']
                ? AppColors.success
                : AppColors.error,
          ),
        );

        if (result['success']) {
          // Record attendance in Firebase
          final currentUser = FirebaseAuthService.currentUser;
          if (currentUser != null) {
            print('🔄 Recording check-in in Firebase Firestore...');
            print('📊 Driver ID: ${attendanceData['driverId']}');
            print('📊 Driver Name: ${attendanceData['driverName']}');
            print('📊 Truck Info: ${attendanceData['truckInfo']}');
            print('📊 Plate Number: ${attendanceData['plateNumber']}');

            final attendanceResult = await AttendanceService.recordCheckIn(
              driverId: attendanceData['driverId'],
              driverName: attendanceData['driverName'],
              truckInfo: attendanceData['truckInfo'],
              plateNumber: attendanceData['plateNumber'],
              checkInSelfie: attendanceData['selfie'],
            );

            if (attendanceResult['success']) {
              // Start shift tracking
              setState(() {
                _isShiftActive = true;
                _shiftStartTime = DateTime.now();
                _driverName = attendanceData['driverName'];
                _truckInfo = attendanceData['truckInfo'];
                _plateNumber = attendanceData['plateNumber'];
                _startSelfie = attendanceData['selfie'];
                _attendanceId = attendanceResult['attendanceId'];
              });

              // Start timer for real-time updates
              _startShiftTimer();

              await _loadAssignedCollections();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check-in recorded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to record check-in: ${attendanceResult['message']}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showAttendanceModal() async {
    print('🔄 _showAttendanceModal called');
    print('🔄 _isShiftActive: $_isShiftActive');

    // If already checked in, don't show modal again
    if (_isShiftActive) {
      print('🔄 Already checked in, showing message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already checked in!'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    print('🔄 Showing attendance modal...');
    final nameController = TextEditingController();
    final driverIdController = TextEditingController();
    final truckController = TextEditingController();
    final plateController = TextEditingController();
    File? selectedImage;

    // Pre-fill driver ID with current user ID
    final currentUser = FirebaseAuthService.currentUser;
    if (currentUser != null) {
      driverIdController.text = currentUser.id;
    }

    print('🔄 ===== SHOWING ATTENDANCE MODAL =====');
    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Check-In Attendance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Driver Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // Driver ID
                TextField(
                  controller: driverIdController,
                  decoration: const InputDecoration(
                    labelText: 'Driver ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  readOnly: true, // Make it read-only since it's auto-filled
                ),
                const SizedBox(height: 16),

                // Truck Info
                TextField(
                  controller: truckController,
                  decoration: const InputDecoration(
                    labelText: 'Truck Information',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping),
                  ),
                ),
                const SizedBox(height: 16),

                // Plate Number
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                ),
                const SizedBox(height: 16),

                // Selfie Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Take Selfie for Attendance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (selectedImage != null)
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.camera_alt, size: 40),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          print('🔄 Take Selfie button pressed');
                          final image = await _imagePicker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          print('🔄 Image picker result: ${image?.path}');
                          if (image != null) {
                            print('🔄 Setting selected image: ${image.path}');
                            setModalState(() {
                              selectedImage = File(image.path);
                            });
                            print(
                              '🔄 Selected image updated: ${selectedImage?.path}',
                            );
                          } else {
                            print('🔄 No image selected');
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Selfie'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                print('🔄 ===== CHECK-IN BUTTON PRESSED =====');
                print('🔄 Check-In button pressed');
                print('🔄 Name: "${nameController.text}"');
                print('🔄 Truck: "${truckController.text}"');
                print('🔄 Plate: "${plateController.text}"');
                print(
                  '🔄 Selfie: ${selectedImage != null ? "Selected" : "Not selected"}',
                );
                print('🔄 Name empty: ${nameController.text.isEmpty}');
                print('🔄 Driver ID empty: ${driverIdController.text.isEmpty}');
                print('🔄 Truck empty: ${truckController.text.isEmpty}');
                print('🔄 Plate empty: ${plateController.text.isEmpty}');
                print('🔄 Selfie null: ${selectedImage == null}');

                if (nameController.text.isNotEmpty &&
                    driverIdController.text.isNotEmpty &&
                    truckController.text.isNotEmpty &&
                    plateController.text.isNotEmpty) {
                  print('🔄 All fields filled, returning data...');
                  Navigator.pop(context, {
                    'driverName': nameController.text,
                    'driverId': driverIdController.text,
                    'truckInfo': truckController.text,
                    'plateNumber': plateController.text,
                    'selfie': selectedImage,
                  });
                } else {
                  print('🔄 Missing fields, showing error...');
                  print('🔄 Validation failed - showing error message');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill all fields (name, driver ID, truck, plate)',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );

                  // TEMPORARY: Add a test button to bypass validation
                  print('🔄 ===== TESTING BYPASS VALIDATION =====');
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Test Check-In'),
                      content: const Text(
                        'Do you want to test check-in with dummy data?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close test dialog
                            Navigator.pop(context, {
                              // Close attendance modal with dummy data
                              'driverName': 'Test Driver',
                              'truckInfo': 'Test Truck',
                              'plateNumber': 'TEST-123',
                              'selfie': null, // No selfie required
                            });
                          },
                          child: const Text('Test Check-In'),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check-In'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeCollection(WasteCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Collection'),
        content: const Text('Have you completed this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await CollectionApprovalService.completeCollection(
        collection.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success']
                ? AppColors.success
                : AppColors.error,
          ),
        );

        if (result['success']) {
          await _loadAssignedCollections();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAssignedCollections();
              _loadTodaySchedule();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar (only show when shift is active)
          Builder(
            builder: (context) {
              print('🔄 Build method: _isShiftActive = $_isShiftActive');
              if (_isShiftActive) {
                print('🔄 Build method: calling _buildProgressBar');
                return _buildProgressBar();
              } else {
                print('🔄 Build method: not showing progress bar');
                return const SizedBox.shrink();
              }
            },
          ),
          // Content - Attendance Calendar
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAttendanceCalendar(),
          ),
        ],
      ),
    );
  }

  // Removed _buildListView and _buildReportsView - using attendance calendar as main view

  Widget _buildAttendanceCalendar() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final firstDayOfMonth = currentMonth;
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Calendar',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getMonthName(now.month)} ${now.year}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calendar Grid
          Expanded(
            child: Column(
              children: [
                // Weekday headers
                Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map(
                        (day) => Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Calendar days
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                        ),
                    itemCount: 42, // 6 weeks * 7 days
                    itemBuilder: (context, index) {
                      final dayNumber = index - firstWeekday + 1;
                      final isCurrentMonth =
                          dayNumber > 0 && dayNumber <= daysInMonth;
                      final isToday = isCurrentMonth && dayNumber == now.day;
                      final isPast = isCurrentMonth && dayNumber < now.day;
                      final isFuture = isCurrentMonth && dayNumber > now.day;

                      if (!isCurrentMonth) {
                        return Container(); // Empty cell for days outside current month
                      }

                      return _buildCalendarDay(
                        dayNumber,
                        isToday,
                        isPast,
                        isFuture,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Schedule Section
          const SizedBox(height: 20),
          _buildScheduleSection(),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasSchedule && _todaySchedule != null) ...[
            _buildScheduleInfo(),
          ] else ...[
            _buildNoScheduleInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    final schedule = _todaySchedule!;

    // Debug: Print all available fields
    print('🔄 Schedule data fields: ${schedule.keys.toList()}');
    print('🔄 Schedule data: $schedule');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Collection Request Scheduled',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Collection Request Details
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Requested by
                if (schedule['user_name'] != null)
                  _buildScheduleRow('Requested by', schedule['user_name']),

                // Waste type
                if (schedule['waste_type'] != null)
                  _buildScheduleRow('Waste Type', schedule['waste_type']),

                // Address
                if (schedule['address'] != null)
                  _buildScheduleRow('Address', schedule['address']),

                // Coordinates
                if (schedule['latitude'] != null &&
                    schedule['longitude'] != null)
                  _buildScheduleRow(
                    'Coordinates',
                    '${schedule['latitude']}, ${schedule['longitude']}',
                  ),

                // Status
                if (schedule['status'] != null)
                  _buildScheduleRow('Status', schedule['status']),

                // Scheduled date
                if (schedule['scheduledDate'] != null)
                  _buildScheduleRow(
                    'Scheduled Date',
                    schedule['scheduledDate'],
                  ),
                if (schedule['scheduled_date'] != null)
                  _buildScheduleRow(
                    'Scheduled Date',
                    schedule['scheduled_date'],
                  ),
                if (schedule['date'] != null)
                  _buildScheduleRow('Scheduled Date', schedule['date']),

                // Assigned truck
                if (schedule['assignedTruck'] != null)
                  _buildScheduleRow(
                    'Assigned Truck',
                    schedule['assignedTruck'],
                  ),
                if (schedule['truck'] != null)
                  _buildScheduleRow('Assigned Truck', schedule['truck']),

                // Assigned driver
                if (schedule['assignedDriver'] != null)
                  _buildScheduleRow(
                    'Assigned Driver',
                    schedule['assignedDriver'],
                  ),
                if (schedule['driver_name'] != null)
                  _buildScheduleRow('Assigned Driver', schedule['driver_name']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScheduleInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No schedule assigned for today. Please contact admin to get your schedule.',
              style: TextStyle(fontSize: 14, color: Colors.orange[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(int day, bool isToday, bool isPast, bool isFuture) {
    return GestureDetector(
      onTap: () {
        print('📅 Calendar day $day clicked');
        print('📅 isToday: $isToday, isPast: $isPast, isFuture: $isFuture');
        print('📅 _isShiftActive: $_isShiftActive');

        if (isToday && !_isShiftActive) {
          print('📅 Opening check-in modal...');
          if (_hasSchedule) {
            print('📅 Schedule found, allowing check-in...');
            _handleCalendarAttendance();
          } else {
            print('📅 No schedule found, preventing check-in...');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No schedule assigned for today. Please contact admin.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else if (isToday && _isShiftActive) {
          print('📅 Opening check-out modal...');
          _handleCalendarCheckOut();
        } else if (isPast) {
          print('📅 Opening attendance history...');
          _showAttendanceHistory(day);
        } else {
          print('📅 No action for this day');
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary
              : isPast
              ? Colors.grey[100]
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? AppColors.primary : Colors.grey[300]!,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? Colors.white
                    : isPast
                    ? Colors.grey[600]
                    : Colors.black87,
              ),
            ),
            if (isToday && !_isShiftActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _hasSchedule ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _hasSchedule ? 'Click to Check-In' : 'No Schedule',
                  style: TextStyle(
                    fontSize: 8,
                    color: _hasSchedule ? AppColors.primary : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isToday && _isShiftActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Click to Check-Out',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPast)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Past',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Future<void> _handleCalendarAttendance() async {
    print('🔄 ===== HANDLING CALENDAR ATTENDANCE =====');
    print('🔄 Handling calendar attendance...');
    final attendanceData = await _showAttendanceModal();
    print('🔄 Modal returned: ${attendanceData != null ? "DATA" : "NULL"}');

    if (attendanceData != null) {
      print('🔄 ===== ATTENDANCE DATA RECEIVED =====');
      print('🔄 Attendance data received from modal');
      print('🔄 Data: $attendanceData');
      // Record attendance in Firebase
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        print('🔄 Recording check-in in Firebase Firestore...');
        print('📊 Driver ID: ${attendanceData['driverId']}');
        print('📊 Driver Name: ${attendanceData['driverName']}');
        print('📊 Truck Info: ${attendanceData['truckInfo']}');
        print('📊 Plate Number: ${attendanceData['plateNumber']}');

        final attendanceResult = await AttendanceService.recordCheckIn(
          driverId: attendanceData['driverId'],
          driverName: attendanceData['driverName'],
          truckInfo: attendanceData['truckInfo'],
          plateNumber: attendanceData['plateNumber'],
          checkInSelfie: attendanceData['selfie'], // Can be null now
        );

        if (attendanceResult['success']) {
          print(
            '🔄 Attendance recorded successfully, starting shift tracking...',
          );
          // Start shift tracking
          setState(() {
            _isShiftActive = true;
            _shiftStartTime = DateTime.now();
            _driverName = attendanceData['driverName'];
            _truckInfo = attendanceData['truckInfo'];
            _plateNumber = attendanceData['plateNumber'];
            _startSelfie = attendanceData['selfie'];
            _attendanceId = attendanceResult['attendanceId'];
          });

          print('🔄 Shift state updated:');
          print('🔄 _isShiftActive: $_isShiftActive');
          print('🔄 _shiftStartTime: $_shiftStartTime');
          print('🔄 _driverName: $_driverName');
          print('🔄 _attendanceId: $_attendanceId');

          // Start timer for real-time updates
          print('🔄 Starting shift timer...');
          _startShiftTimer();

          await _loadAssignedCollections();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check-in recorded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to record check-in: ${attendanceResult['message']}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      print('🔄 No attendance data received (modal cancelled)');
    }
  }

  Future<void> _handleCalendarCheckOut() async {
    print('🔄 Handling calendar check-out...');

    if (!_isShiftActive) {
      print('🔄 No active shift to check out');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active shift to check out'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show end shift modal
    final endSelfie = await _showEndShiftModal();

    if (endSelfie != null) {
      print('🔄 End selfie received, processing check-out...');
      // Store the end selfie and call _endShift
      _endSelfie = endSelfie;
      await _endShift();
    } else {
      print('🔄 Check-out cancelled');
    }
  }

  Future<void> _showAttendanceHistory(int day) async {
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendance - ${day}/${now.month}/${now.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Attendance History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No attendance record found for this date.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Attendance records are automatically created when you check-in.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
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

  Widget _buildReportCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(WasteCollection collection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(collection.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    collection.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(collection.scheduledDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Waste type and quantity
            Row(
              children: [
                Icon(
                  _getWasteTypeIcon(collection.wasteType),
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  collection.wasteTypeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${collection.quantity} ${collection.unit}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    collection.address,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),

            // Coordinates
            if (collection.latitude != null &&
                collection.longitude != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Location: ${BarangayData.getNearestBarangay(collection.latitude!, collection.longitude!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],

            // Actions
            const SizedBox(height: 16),
            if (collection.status == CollectionStatus.scheduled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startCollection(collection),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Collection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (collection.status == CollectionStatus.inProgress) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeCollection(collection),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Complete Collection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.pending:
        return Colors.orange;
      case CollectionStatus.approved:
        return Colors.green;
      case CollectionStatus.scheduled:
        return Colors.blue;
      case CollectionStatus.inProgress:
        return Colors.purple;
      case CollectionStatus.completed:
        return Colors.green[700]!;
      case CollectionStatus.cancelled:
        return Colors.grey;
      case CollectionStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getWasteTypeIcon(WasteType wasteType) {
    switch (wasteType) {
      case WasteType.general:
        return Icons.delete;
      case WasteType.recyclable:
        return Icons.recycling;
      case WasteType.organic:
        return Icons.eco;
      case WasteType.hazardous:
        return Icons.warning;
      case WasteType.electronic:
        return Icons.devices;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _checkForActiveShift() async {
    print('🔄 _checkForActiveShift called');
    print('🔄 _assignedCollections length: ${_assignedCollections.length}');
    print('🔄 _isShiftActive: $_isShiftActive');

    // Check if there are any in-progress collections
    final inProgressCollections = _assignedCollections
        .where((c) => c.status == CollectionStatus.inProgress)
        .toList();

    print('🔄 In-progress collections: ${inProgressCollections.length}');

    if (inProgressCollections.isNotEmpty && !_isShiftActive) {
      print(
        '🔄 Found in-progress collections, checking for active attendance...',
      );
      // Check for existing active attendance record
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        final activeAttendance = await AttendanceService.getActiveAttendance(
          currentUser.id,
        );

        if (activeAttendance != null) {
          // Restore shift state from existing attendance record
          setState(() {
            _isShiftActive = true;
            _shiftStartTime = DateTime.parse(activeAttendance['checkInTime']);
            _driverName = activeAttendance['driverName'];
            _truckInfo = activeAttendance['truckInfo'];
            _plateNumber = activeAttendance['plateNumber'];
            _attendanceId = activeAttendance['id'];
          });
          _startShiftTimer();
        } else {
          // Restore shift state with default values if no attendance record found
          setState(() {
            _isShiftActive = true;
            _shiftStartTime = DateTime.now().subtract(
              const Duration(hours: 1),
            ); // Approximate
            _driverName = 'Driver'; // Default name
            _truckInfo = 'Truck'; // Default truck
            _plateNumber = 'ABC-123'; // Default plate
          });
          _startShiftTimer();
        }
      }
    }
  }

  void _startShiftTimer() {
    print('🔄 _startShiftTimer called');
    _shiftTimer?.cancel();
    _shiftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isShiftActive) {
        print(
          '🔄 Timer tick - updating progress bar (${DateTime.now().toIso8601String()})',
        );
        setState(() {
          // This will trigger a rebuild to update the progress bar
        });
      } else {
        print(
          '🔄 Timer stopping - mounted: $mounted, _isShiftActive: $_isShiftActive',
        );
        timer.cancel();
      }
    });
    print('🔄 Timer started successfully');
  }

  Widget _buildProgressBar() {
    print(
      '🔄 _buildProgressBar called - _isShiftActive: $_isShiftActive, _shiftStartTime: $_shiftStartTime',
    );
    if (!_isShiftActive || _shiftStartTime == null) {
      print('🔄 Progress bar not showing - conditions not met');
      return const SizedBox.shrink();
    }

    print('🔄 Building progress bar...');

    final now = DateTime.now();
    final shiftDuration = now.difference(_shiftStartTime!);
    final hours = shiftDuration.inHours;
    final minutes = shiftDuration.inMinutes % 60;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checked In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Driver: $_driverName',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Truck: $_truckInfo ($_plateNumber)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'View: Attendance Calendar',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _endShift,
                  icon: const Icon(Icons.stop),
                  label: const Text('Check-Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _endShift() async {
    print('🔄 _endShift called');
    print('🔄 _attendanceId: $_attendanceId');
    print('🔄 _endSelfie available: ${_endSelfie != null}');

    // Use the stored end selfie or show modal if not available
    File? endSelfie = _endSelfie;

    if (endSelfie == null) {
      print('🔄 No stored end selfie, showing modal...');
      // Show end shift modal with selfie requirement
      endSelfie = await _showEndShiftModal();
    } else {
      print('🔄 Using stored end selfie');
    }

    if (endSelfie != null && _attendanceId != null) {
      print('🔄 ===== PROCESSING CHECK-OUT =====');
      print('🔄 End selfie received: ${endSelfie.path}');
      print('🔄 Attendance ID: $_attendanceId');

      // Complete all active collections automatically
      int completedCount = 0;
      print('🔄 Auto-completing all collections...');
      print('🔄 Total assigned collections: ${_assignedCollections.length}');

      for (var collection in _assignedCollections) {
        print('🔄 Collection ${collection.id}: status=${collection.status}');

        // Complete collections that are in progress or scheduled
        if (collection.status == CollectionStatus.inProgress ||
            collection.status == CollectionStatus.scheduled) {
          print(
            '✅ Completing collection: ${collection.id} (status: ${collection.status})',
          );

          final result = await CollectionApprovalService.completeCollection(
            collection.id,
          );
          print('🔄 Completion result: $result');

          if (result['success'] == true) {
            completedCount++;
            print('✅ Successfully completed collection: ${collection.id}');
          } else {
            print(
              '❌ Failed to complete collection: ${collection.id} - ${result['message']}',
            );
          }
        } else {
          print(
            '⏭️ Skipping collection ${collection.id} with status: ${collection.status}',
          );
        }
      }

      print('📊 Total collections auto-completed: $completedCount');

      // Refresh assigned collections to reflect the completed status
      print('🔄 Refreshing assigned collections...');
      await _loadAssignedCollections();

      // Record check-out in Firebase
      print('🔄 Recording check-out in Firebase Firestore...');
      print('🔄 Attendance ID: $_attendanceId');
      print('🔄 End selfie: ${endSelfie.path}');
      print('🔄 Collections completed: $completedCount');

      final attendanceResult = await AttendanceService.recordCheckOut(
        attendanceId: _attendanceId!,
        checkOutSelfie: endSelfie,
        collectionsCompleted: completedCount,
      );

      print('🔄 Check-out result: $attendanceResult');

      // Stop timer and reset shift state
      _shiftTimer?.cancel();
      setState(() {
        _isShiftActive = false;
        _shiftStartTime = null;
        _driverName = null;
        _truckInfo = null;
        _plateNumber = null;
        _startSelfie = null;
        _endSelfie = endSelfie;
        _attendanceId = null;
      });

      if (mounted) {
        if (attendanceResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Check-out recorded successfully! $completedCount collections auto-completed.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Check-out failed: ${attendanceResult['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        await _loadAssignedCollections();
      }
    }
  }

  Future<File?> _showEndShiftModal() async {
    print('🔄 ===== SHOWING END SHIFT MODAL =====');
    File? selectedImage;

    return await showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Check-Out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Take a selfie to check-out',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (selectedImage != null)
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, size: 50),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  print('🔄 Take End Selfie button pressed');
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  print('🔄 End selfie picker result: ${image?.path}');
                  if (image != null) {
                    print('🔄 Setting end selfie: ${image.path}');
                    setModalState(() {
                      selectedImage = File(image.path);
                    });
                    print('🔄 End selfie updated: ${selectedImage?.path}');
                  } else {
                    print('🔄 No end selfie selected');
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Selfie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                print('🔄 ===== CHECK-OUT BUTTON PRESSED =====');
                print('🔄 End selfie available: ${selectedImage != null}');
                if (selectedImage != null) {
                  print('🔄 End selfie provided, closing modal...');
                  Navigator.pop(context, selectedImage);
                } else {
                  print('🔄 No end selfie, showing error...');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please take a selfie to end shift'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check-Out'),
            ),
          ],
        ),
      ),
    );
  }
}
