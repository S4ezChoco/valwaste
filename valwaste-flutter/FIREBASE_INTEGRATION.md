# Firebase Integration for ValWaste

## Overview
The ValWaste app has been successfully integrated with Firebase for authentication and data storage. This replaces the previous mock authentication system with a real, scalable backend solution.

## Features Implemented

### 1. Firebase Authentication
- **User Registration**: Create new accounts with email and password
- **User Login**: Secure authentication with Firebase Auth
- **Password Reset**: Email-based password reset functionality
- **Account Management**: Update profile, delete account
- **Session Management**: Automatic session handling

### 2. Firestore Database
- **User Profiles**: Store user data in Firestore collections
- **Real-time Data**: Live data synchronization
- **Scalable Storage**: Cloud-based database solution

### 3. Security Features
- **Email Verification**: Built-in email verification
- **Password Strength**: Firebase enforces password requirements
- **Secure Storage**: User data stored securely in Firestore
- **Authentication State**: Real-time auth state monitoring

## Implementation Details

### Dependencies Added
```yaml
firebase_core: ^2.24.2      # Firebase core functionality
firebase_auth: ^4.15.3      # Authentication services
cloud_firestore: ^4.13.6    # Database services
```

### Files Modified/Created

#### New Files:
- `lib/services/firebase_auth_service.dart` - Firebase authentication service
- `lib/firebase_options.dart` - Firebase configuration
- `FIREBASE_INTEGRATION.md` - This documentation

#### Modified Files:
- `lib/models/user.dart` - Updated User model for Firebase compatibility
- `lib/main.dart` - Firebase initialization
- `lib/screens/auth/login_screen.dart` - Firebase login integration
- `lib/screens/auth/register_screen.dart` - Firebase registration integration
- `lib/screens/profile/profile_screen.dart` - Firebase logout integration

### User Model Updates
```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String barangay;        // Added for location tracking
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;     // Added for data tracking
  final bool isActive;
}
```

## Firebase Service Methods

### Authentication Methods
```dart
// Register new user
FirebaseAuthService.register({
  required String name,
  required String email,
  required String password,
  required String phone,
  required String address,
  String? barangay = 'Valenzuela City',
})

// Login user
FirebaseAuthService.login(String email, String password)

// Logout user
FirebaseAuthService.logout()

// Reset password
FirebaseAuthService.resetPassword(String email)

// Delete account
FirebaseAuthService.deleteAccount()
```

### User Data Methods
```dart
// Get current user data
FirebaseAuthService.getCurrentUserData()

// Update user profile
FirebaseAuthService.updateProfile({
  required String name,
  required String phone,
  required String address,
  String? barangay,
})
```

### Properties
```dart
// Check if user is logged in
FirebaseAuthService.isLoggedIn

// Get current Firebase user
FirebaseAuthService.currentUser

// Auth state changes stream
FirebaseAuthService.authStateChanges
```

## Database Structure

### Firestore Collections

#### Users Collection
```
users/{userId}
├── id: string
├── name: string
├── email: string
├── phone: string
├── address: string
├── barangay: string
├── profileImage: string (optional)
├── createdAt: timestamp
├── updatedAt: timestamp
└── isActive: boolean
```

## Setup Instructions

### 1. Firebase Project Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Email/Password provider
3. Create a Firestore database
4. Set up security rules for Firestore

### 2. Configuration
1. Replace placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration
2. Update the following values:
   - `apiKey`
   - `appId`
   - `messagingSenderId`
   - `projectId`
   - `authDomain`
   - `storageBucket`

### 3. Security Rules
Set up Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Error Handling

### Authentication Errors
The service handles common Firebase Auth errors:
- **weak-password**: Password too weak
- **email-already-in-use**: Email already registered
- **user-not-found**: No user with that email
- **wrong-password**: Incorrect password
- **invalid-email**: Invalid email format
- **user-disabled**: Account disabled

### User-Friendly Messages
All error messages are converted to user-friendly text and displayed via SnackBar notifications.

## Features Removed

### Auto-Login Test
- Removed the auto-login test button from login screen
- Removed `autoLoginForTesting()` method from auth service
- Users must now create real accounts or use existing credentials

## Future Enhancements

### Planned Features
1. **Email Verification**: Require email verification before account activation
2. **Social Login**: Google, Facebook, Apple sign-in options
3. **Phone Authentication**: SMS-based verification
4. **Profile Pictures**: Upload and store profile images
5. **Data Export**: Export user data functionality

### Advanced Features
1. **Real-time Updates**: Live data synchronization across devices
2. **Offline Support**: Offline data caching and sync
3. **Push Notifications**: Firebase Cloud Messaging integration
4. **Analytics**: Firebase Analytics integration
5. **Crash Reporting**: Firebase Crashlytics integration

## Testing

### Test Accounts
Create test accounts through the registration screen:
1. Use valid email addresses
2. Passwords must be at least 6 characters
3. All fields are required

### Error Testing
Test various error scenarios:
- Invalid email formats
- Weak passwords
- Duplicate email registration
- Wrong password login
- Network connectivity issues

## Troubleshooting

### Common Issues
1. **Firebase not initialized**: Check Firebase configuration
2. **Authentication errors**: Verify Firebase Auth is enabled
3. **Database errors**: Check Firestore security rules
4. **Network issues**: Ensure internet connectivity

### Debug Commands
```bash
flutter pub get          # Install dependencies
flutter clean           # Clean build cache
flutter run             # Test the app
```

## Security Considerations

### Data Protection
- User passwords are never stored locally
- All authentication handled by Firebase
- User data encrypted in transit and at rest
- Automatic session management

### Privacy Compliance
- GDPR-compliant data handling
- User consent for data collection
- Right to data deletion
- Transparent data usage

## Credits
- **Firebase**: Google's mobile and web app development platform
- **Firebase Auth**: Authentication service
- **Cloud Firestore**: NoSQL cloud database
- **FlutterFire**: Official Firebase plugins for Flutter


