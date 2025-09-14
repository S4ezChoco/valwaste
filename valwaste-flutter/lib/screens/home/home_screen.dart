import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/announcement_notification_service.dart';
import '../../services/location_tracking_service.dart';
import '../../models/user.dart';
import '../schedule/schedule_screen.dart';
import '../schedule/barangay_schedule_screen.dart';
import '../schedule/driver_schedule_screen.dart';
import '../profile/profile_screen.dart';
import '../collection/collection_request_screen.dart';
import '../map/map_screen.dart';
import '../barangay/approval_screen.dart';
import '../driver/driver_collections_screen.dart';
import '../guide/recycling_guide_screen.dart';
import '../report/driver_report_screen.dart';
import 'resident_dashboard_screen.dart';
import 'barangay_official_dashboard_screen.dart';
import 'collector_dashboard_screen.dart';
import 'administrator_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  List<Widget> _screens = [];
  bool _isLoading = true;
  final AnnouncementNotificationService _announcementService =
      AnnouncementNotificationService();

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _pageController = PageController(initialPage: _currentIndex);

    // Start listening for announcements after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _announcementService.startListening(context);
      }
    });

    // Start location tracking for all users
    _startLocationTracking();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _announcementService.stopListening();
    super.dispose();
  }

  /// Start location tracking for the current user
  Future<void> _startLocationTracking() async {
    try {
      await LocationTrackingService.startLocationTracking();
      print('HomeScreen: Location tracking started');
    } catch (e) {
      print('HomeScreen: Error starting location tracking: $e');
    }
  }

  void _initializeScreens() async {
    print('HomeScreen: Initializing screens...');

    // Try to get current user with refresh
    final currentUser = await FirebaseAuthService.getCurrentUserWithRefresh();
    print('HomeScreen: Current user: ${currentUser?.email ?? 'null'}');
    print('HomeScreen: User role: ${currentUser?.roleString ?? 'null'}');

    if (currentUser == null) {
      // Default screens if no user (shouldn't happen)
      print('HomeScreen: No current user found, using default screens');
      _screens = [
        const ResidentDashboardScreen(),
        const ScheduleScreen(),
        const RecyclingGuideScreen(), // Using Recycling Guide as Report
        const ProfileScreen(),
      ];
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print('HomeScreen: Setting up screens for role: ${currentUser.roleString}');
    switch (currentUser.role) {
      case UserRole.resident:
        print('HomeScreen: Initializing Resident dashboard');
        // Resident features: Home, Schedule, Maps, Profile
        _screens = [
          const ResidentDashboardScreen(),
          const ScheduleScreen(), // Schedule tab for viewing schedules and requesting collections
          const MapScreen(), // Maps tab for viewing collection routes and locations
          const ProfileScreen(),
        ];
        break;
      case UserRole.barangayOfficial:
        print('HomeScreen: Initializing Barangay Official dashboard');
        // Barangay Official features: Home, Approval, Maps, Profile
        _screens = [
          const BarangayOfficialDashboardScreen(),
          const ApprovalScreen(), // New approval screen for managing requests
          const MapScreen(), // Maps tab
          const ProfileScreen(),
        ];
        break;
      case UserRole.driver:
        print('HomeScreen: Initializing Driver dashboard');
        // Driver features: Maps, Collections, Reports, Profile
        _screens = [
          const MapScreen(), // Maps tab is now the home
          const DriverCollectionsScreen(), // New collections screen for assigned tasks
          const DriverReportScreen(), // Reports tab - shows collection completion reports
          const ProfileScreen(),
        ];
        break;
      case UserRole.collector:
        print('HomeScreen: Initializing Collector dashboard');
        // Collector features: Home, Report, Maps, Profile
        _screens = [
          const CollectorDashboardScreen(),
          const ScheduleScreen(), // Using Schedule as Report for now
          const MapScreen(), // Maps tab
          const ProfileScreen(),
        ];
        break;
      case UserRole.administrator:
        print('HomeScreen: Initializing Administrator dashboard');
        // Administrator features: Home, Report, Maps, Profile
        _screens = [
          const AdministratorDashboardScreen(),
          const CollectionRequestScreen(), // Using Collection Request as Report
          const MapScreen(), // Maps tab
          const ProfileScreen(),
        ];
        break;
      default:
        print('HomeScreen: Unknown role, using Resident screens');
        _screens = [
          const ResidentDashboardScreen(),
          const ScheduleScreen(), // Schedule tab
          const MapScreen(), // Maps tab
          const ProfileScreen(),
        ];
        break;
    }
    print('HomeScreen: Screens initialized with ${_screens.length} screens');

    setState(() {
      _isLoading = false;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _isMapScreen() {
    final currentUser = FirebaseAuthService.currentUser;
    if (currentUser == null) return false;

    // Map is at index 0 for driver, index 2 for other roles including resident
    if (currentUser.role == UserRole.driver) {
      return _currentIndex == 0; // Map is still the first tab for driver
    }
    return _currentIndex ==
        2; // Map is at index 2 for other roles including resident
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    final currentUser = FirebaseAuthService.currentUser;
    print(
      'HomeScreen: Getting bottom nav items for user: ${currentUser?.email ?? 'null'}',
    );
    print('HomeScreen: User role: ${currentUser?.roleString ?? 'null'}');

    if (currentUser == null) {
      print('HomeScreen: No current user, returning default nav items');
      return _getDefaultNavItems();
    }

    switch (currentUser.role) {
      case UserRole.resident:
        print('HomeScreen: Returning Resident nav items (4 items)');
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.barangayOfficial:
        print('HomeScreen: Returning Barangay Official nav items (4 items)');
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.approval_outlined),
            activeIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.driver:
        print('HomeScreen: Returning Driver nav items (4 items)');
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Collections',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.collector:
        print('HomeScreen: Returning Collector nav items (4 items)');
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Report',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.administrator:
        print('HomeScreen: Returning Administrator nav items (4 items)');
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Report',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      default:
        print('HomeScreen: Unknown role, returning default nav items');
        return _getDefaultNavItems();
    }
  }

  List<BottomNavigationBarItem> _getDefaultNavItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Schedule',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'History',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print current user info
    final currentUser = FirebaseAuthService.currentUser;
    print('HomeScreen build: Current user: ${currentUser?.email ?? 'null'}');
    print('HomeScreen build: User role: ${currentUser?.roleString ?? 'null'}');
    print('HomeScreen build: Screens count: ${_screens.length}');
    print('HomeScreen build: Current index: $_currentIndex');

    if (_isLoading || _screens.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your dashboard...',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: _isMapScreen() ? const NeverScrollableScrollPhysics() : null,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: AppColors.primary,
        elevation: 8,
        items: _getBottomNavItems(),
      ),
    );
  }
}

// Default Dashboard Screen (fallback)
class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSizes.paddingLarge),
              Text(
                'Welcome to ValWaste',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                'Please log in to access your dashboard',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widgets
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            const SizedBox(height: AppSizes.paddingSmall),
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
    );
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
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
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
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String residentName;
  final String address;
  final String requestType;
  final String status;
  final String time;

  const _RequestCard({
    required this.residentName,
    required this.address,
    required this.requestType,
    required this.status,
    required this.time,
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
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            address,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Row(
            children: [
              Text(
                requestType,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final String address;
  final String time;
  final String status;
  final String wasteType;

  const _CollectionCard({
    required this.address,
    required this.time,
    required this.status,
    required this.wasteType,
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
          Icon(Icons.recycling, color: Colors.green, size: 24),
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green,
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

class _StopCard extends StatelessWidget {
  final String address;
  final String time;
  final String wasteType;
  final String status;

  const _StopCard({
    required this.address,
    required this.time,
    required this.wasteType,
    required this.status,
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
