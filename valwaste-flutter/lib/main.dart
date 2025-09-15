import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Auth Service
  FirebaseAuthService.initialize();

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
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
    } else {
      print('User not logged in, showing LoginScreen');
      return const LoginScreen();
    }
  }
}
