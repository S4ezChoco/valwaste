import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Auth Service
  await FirebaseAuthService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValWaste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoadingUserData = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('AuthWrapper: Initializing authentication...');

    // Listen to authentication state changes
    FirebaseAuthService.authStateChanges.listen((user) {
      print('Auth state changed: ${user?.email ?? 'null'}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _checkUserData();
      }
    });

    // Force refresh after a short delay to ensure we catch any immediate changes
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _checkUserData();
      }
    });
  }

  Future<void> _checkUserData() async {
    final isLoggedIn = FirebaseAuthService.isLoggedIn;
    final currentUser = FirebaseAuthService.currentUser;

    print(
      'AuthWrapper: Checking user data - isLoggedIn: $isLoggedIn, currentUser: ${currentUser?.email ?? 'null'}',
    );

    if (isLoggedIn && currentUser == null) {
      print(
        'AuthWrapper: User logged in but data not loaded, attempting to refresh...',
      );
      setState(() {
        _isLoadingUserData = true;
      });

      try {
        // Try to refresh user data with timeout
        await Future.any([
          FirebaseAuthService.refreshCurrentUser(),
          Future.delayed(
            const Duration(seconds: 10),
          ), // Increased timeout to 10 seconds
        ]);

        // Wait a bit more for data to load
        await Future.delayed(const Duration(milliseconds: 2000));

        // Check again after refresh
        final updatedUser = FirebaseAuthService.currentUser;
        print(
          'AuthWrapper: After refresh - currentUser: ${updatedUser?.email ?? 'null'}',
        );

        // If still no user data, try force refresh
        if (updatedUser == null) {
          print('AuthWrapper: Still no user data, attempting force refresh...');
          try {
            await FirebaseAuthService.forceRefreshUserData();
            final forceRefreshedUser = FirebaseAuthService.currentUser;
            print(
              'AuthWrapper: After force refresh - currentUser: ${forceRefreshedUser?.email ?? 'null'}',
            );
          } catch (forceRefreshError) {
            print('AuthWrapper: Force refresh failed: $forceRefreshError');
          }
        }

        if (mounted) {
          setState(() {
            _isLoadingUserData = false;
          });
        }
      } catch (e) {
        print('AuthWrapper: Error refreshing user data: $e');
        if (mounted) {
          setState(() {
            _isLoadingUserData = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking authentication
    if (_isLoading) {
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
                'Loading...',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is logged in
    final isLoggedIn = FirebaseAuthService.isLoggedIn;
    final currentUser = FirebaseAuthService.currentUser;

    print(
      'AuthWrapper build: isLoggedIn = $isLoggedIn, currentUser = ${currentUser?.email ?? 'null'}',
    );
    print('User role: ${currentUser?.roleString ?? 'null'}');

    if (isLoggedIn && currentUser != null) {
      print(
        'User is logged in, showing HomeScreen for role: ${currentUser.roleString}',
      );
      return const HomeScreen();
    } else if (isLoggedIn && currentUser == null && _isLoadingUserData) {
      print('User is logged in but currentUser is null, showing loading...');
      // User is logged in but data not loaded yet, show loading
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
                'Loading user data...',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isLoggedIn && currentUser == null) {
      print('User is logged in but data failed to load, showing retry screen');
      // If user data failed to load, show retry screen instead of login
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
                  Icons.error_outline,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load user data',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please try again',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoadingUserData = true;
                  });
                  await _checkUserData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await FirebaseAuthService.logout();
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Text(
                  'Logout',
                  style: AppTextStyles.body1.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      print('User not logged in, showing LoginScreen');
      return const LoginScreen();
    }
  }
}
