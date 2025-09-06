import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color secondary = Color(0xFFFF9800);
  static const Color accent = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF388E3C);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

class AppStrings {
  // App
  static const String appName = 'ValWaste';
  static const String appTagline = 'Smart Waste Management';

  // Authentication
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Full Name';
  static const String phone = 'Phone Number';
  static const String address = 'Address';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';

  // Navigation
  static const String home = 'Home';
  static const String schedule = 'Schedule';
  static const String history = 'History';
  static const String guide = 'Guide';
  static const String profile = 'Profile';

  // Waste Collection
  static const String scheduleCollection = 'Schedule Collection';
  static const String wasteType = 'Waste Type';
  static const String quantity = 'Quantity';
  static const String description = 'Description';
  static const String scheduledDate = 'Scheduled Date';
  static const String status = 'Status';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';

  // Messages
  static const String success = 'Success';
  static const String error = 'Error';
  static const String warning = 'Warning';
  static const String info = 'Information';
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String tryAgain = 'Please try again';
  static const String networkError =
      'Network error. Please check your connection.';
}

class WasteTypeData {
  static const Map<String, String> wasteTypes = {
    'general': 'General Waste',
    'recyclable': 'Recyclable',
    'organic': 'Organic Waste',
    'hazardous': 'Hazardous Waste',
    'electronic': 'Electronic Waste',
  };

  static const Map<String, Color> wasteTypeColors = {
    'general': Color(0xFF9E9E9E),
    'recyclable': Color(0xFF4CAF50),
    'organic': Color(0xFF8D6E63),
    'hazardous': Color(0xFFF44336),
    'electronic': Color(0xFF2196F3),
  };

  static const Map<String, IconData> wasteTypeIcons = {
    'general': Icons.delete,
    'recyclable': Icons.recycling,
    'organic': Icons.eco,
    'hazardous': Icons.warning,
    'electronic': Icons.devices,
  };
}
